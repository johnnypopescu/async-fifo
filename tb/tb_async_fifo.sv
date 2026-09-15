`timescale 1ns/1ps

// Testbench pentru async_fifo — prima variantă.
//
// - două ceasuri necorelate: 100 MHz (scriere) și ~73 MHz (citire)
// - model de referință: o coadă SystemVerilog
// - stimuli random cu rate de scriere/citire diferite pe faze
// - verificări: date în ordine, fără overflow/underflow,
//   full ridicat când e plin, empty ridicat când e gol
// - la final: sumar de coverage (s-a atins plin, gol, aproape-plin etc.)
module tb_async_fifo;

  localparam int  WIDTH   = 8;
  localparam int  DEPTH   = 8;
  localparam real WR_HALF = 5.0;     // 100 MHz
  localparam real RD_HALF = 6.849;   // ~73 MHz

  // ---------------------------------------------------------------- semnale
  logic             wr_clk = 0, rd_clk = 0;
  logic             wr_rst_n = 0, rd_rst_n = 0;
  logic             wr_en = 0, rd_en = 0;
  logic [WIDTH-1:0] wr_data = '0;
  logic [WIDTH-1:0] rd_data;
  logic             full, empty;

  async_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
    .wr_clk   (wr_clk),
    .wr_rst_n (wr_rst_n),
    .wr_en    (wr_en),
    .wr_data  (wr_data),
    .full     (full),
    .rd_clk   (rd_clk),
    .rd_rst_n (rd_rst_n),
    .rd_en    (rd_en),
    .rd_data  (rd_data),
    .empty    (empty)
  );

  always #(WR_HALF) wr_clk = ~wr_clk;
  always #(RD_HALF) rd_clk = ~rd_clk;

  // ------------------------------------------------------ model și contoare
  logic [WIDTH-1:0] model [$];
  logic [WIDTH-1:0] expected;

  int wr_prob = 0;   // probabilitatea (%) de a cere scriere pe un front
  int rd_prob = 0;   // probabilitatea (%) de a cere citire pe un front
  int errors  = 0;

  int n_writes = 0, n_reads = 0;
  int n_wr_blocked = 0, n_rd_blocked = 0;   // cereri refuzate de full/empty
  int n_full = 0, n_empty = 0;              // cicluri cu flag-ul ridicat
  int n_almost_full = 0, n_almost_empty = 0;

  // ------------------------------------------------ domeniul de scriere
  // Tot ce se citește aici (wr_en, full, wr_data) are valoarea de dinaintea
  // frontului — exact ce vede și DUT-ul. Noii stimuli se dau cu <=.
  always @(posedge wr_clk) begin
    if (wr_rst_n) begin
      if (model.size() == DEPTH && !full) begin
        errors++;
        $display("[%0t] EROARE: FIFO plin (%0d elemente) dar full=0", $time, model.size());
      end

      if (wr_en && full) n_wr_blocked++;
      if (wr_en && !full) begin
        model.push_back(wr_data);
        n_writes++;
      end

      if (full)                      n_full++;
      if (model.size() == DEPTH - 1) n_almost_full++;
    end

    wr_en   <= ($urandom % 100) < wr_prob;
    wr_data <= $urandom;
  end

  // ------------------------------------------------- domeniul de citire
  always @(posedge rd_clk) begin
    if (rd_rst_n) begin
      if (model.size() == 0 && !empty) begin
        errors++;
        $display("[%0t] EROARE: FIFO gol dar empty=0", $time);
      end

      if (rd_en && empty) n_rd_blocked++;
      if (rd_en && !empty) begin
        if (model.size() == 0) begin
          errors++;
          $display("[%0t] EROARE: underflow — DUT a citit din FIFO gol", $time);
        end else begin
          expected = model.pop_front();
          n_reads++;
          if (rd_data !== expected) begin
            errors++;
            $display("[%0t] EROARE: citit 0x%02h, așteptat 0x%02h", $time, rd_data, expected);
          end
        end
      end

      if (empty)               n_empty++;
      if (model.size() == 1)   n_almost_empty++;
    end

    rd_en <= ($urandom % 100) < rd_prob;
  end

  // ------------------------------------------------------------- scenariu
  task automatic phase(input string name, input int pw, input int pr, input int cycles);
    $display("[%0t] faza: %s (scriere %0d%%, citire %0d%%, %0d cicluri)",
             $time, name, pw, pr, cycles);
    wr_prob = pw;
    rd_prob = pr;
    repeat (cycles) @(posedge wr_clk);
  endtask

  task automatic check_cov(input string name, input int count);
    if (count == 0) begin
      errors++;
      $display("  %s: %0d   <-- NEATINS", name, count);
    end else begin
      $display("  %s: %0d", name, count);
    end
  endtask

  initial begin
    $dumpfile("build/wave.vcd");
    $dumpvars(0, tb_async_fifo);

    repeat (5) @(posedge wr_clk);
    wr_rst_n <= 1;
    rd_rst_n <= 1;
    repeat (5) @(posedge wr_clk);

    phase("echilibrat",           50,  50, 3000);
    phase("scriere rapida",       90,  20, 3000);   // stă mult pe full
    phase("citire rapida",        20,  90, 3000);   // stă mult pe empty
    phase("umple pana la plin",  100,   0,  100);
    phase("goleste complet",       0, 100,  100);
    phase("rate aproape egale",   70, 100, 3000);   // 70 MHz vs 73 MHz efectiv
    phase("rafale scurte",        95,  95, 2000);
    phase("golire finala",         0, 100,   50);

    // așteaptă să se golească tot, cu limită
    for (int i = 0; i < 1000 && model.size() != 0; i++) @(posedge rd_clk);
    repeat (10) @(posedge rd_clk);

    if (model.size() != 0) begin
      errors++;
      $display("EROARE: au rămas %0d elemente necitite în model", model.size());
    end
    if (!empty) begin
      errors++;
      $display("EROARE: la final FIFO-ul ar trebui să fie gol");
    end

    $display("");
    $display("---------------- sumar ----------------");
    $display("  scrieri acceptate      %6d", n_writes);
    $display("  citiri acceptate       %6d", n_reads);
    check_cov("cicluri full",          n_full);
    check_cov("cicluri empty",         n_empty);
    check_cov("cicluri aproape plin",  n_almost_full);
    check_cov("cicluri aproape gol",   n_almost_empty);
    check_cov("scrieri blocate",       n_wr_blocked);
    check_cov("citiri blocate",        n_rd_blocked);
    $display("---------------------------------------");

    if (errors == 0) begin
      $display("TEST PASSED");
      $finish;
    end else begin
      $fatal(1, "TEST FAILED: %0d erori", errors);
    end
  end

  // watchdog: dacă ceva se blochează, nu rulăm la infinit
  initial begin
    #5_000_000;
    $fatal(1, "TIMEOUT");
  end

endmodule
