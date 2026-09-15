`timescale 1ns/1ps

// Testbench scurt pentru sync_fifo (încălzirea).
// Pe un singur ceas flag-urile trebuie să fie EXACTE, nu doar pesimiste.
module tb_sync_fifo;

  localparam int WIDTH = 8;
  localparam int DEPTH = 8;

  logic             clk = 0, rst_n = 0;
  logic             wr_en = 0, rd_en = 0;
  logic [WIDTH-1:0] wr_data = '0;
  logic [WIDTH-1:0] rd_data;
  logic             full, empty;

  sync_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
    .clk     (clk),
    .rst_n   (rst_n),
    .wr_en   (wr_en),
    .wr_data (wr_data),
    .full    (full),
    .rd_en   (rd_en),
    .rd_data (rd_data),
    .empty   (empty)
  );

  always #5 clk = ~clk;

  logic [WIDTH-1:0] model [$];
  logic [WIDTH-1:0] expected;
  int wr_prob = 0, rd_prob = 0;
  int errors = 0;

  always @(posedge clk) begin
    if (rst_n) begin
      if (full !== (model.size() == DEPTH)) begin
        errors++;
        $display("[%0t] EROARE: full=%0b, model are %0d elemente", $time, full, model.size());
      end
      if (empty !== (model.size() == 0)) begin
        errors++;
        $display("[%0t] EROARE: empty=%0b, model are %0d elemente", $time, empty, model.size());
      end

      if (rd_en && !empty) begin
        expected = model.pop_front();
        if (rd_data !== expected) begin
          errors++;
          $display("[%0t] EROARE: citit 0x%02h, așteptat 0x%02h", $time, rd_data, expected);
        end
      end
      if (wr_en && !full) model.push_back(wr_data);
    end

    wr_en   <= ($urandom % 100) < wr_prob;
    rd_en   <= ($urandom % 100) < rd_prob;
    wr_data <= $urandom;
  end

  task automatic phase(input int pw, input int pr, input int cycles);
    wr_prob = pw;
    rd_prob = pr;
    repeat (cycles) @(posedge clk);
  endtask

  initial begin
    repeat (3) @(posedge clk);
    rst_n <= 1;

    phase( 50,  50, 2000);
    phase( 90,  20, 1000);
    phase( 20,  90, 1000);
    phase(100,   0,   50);
    phase(  0, 100,   50);

    if (errors == 0) begin
      $display("TEST PASSED");
      $finish;
    end else begin
      $fatal(1, "TEST FAILED: %0d erori", errors);
    end
  end

endmodule
