// Pointerul de citire și flag-ul `empty` — totul în domeniul rd_clk.
//
// Gol = pointerii Gray identici pe toți biții, inclusiv bitul suplimentar.
module rd_ptr_empty #(
  parameter int ADDR_W = 3
) (
  input  logic              rd_clk,
  input  logic              rd_rst_n,
  input  logic              rd_en,
  input  logic [ADDR_W:0]   rq2_wptr_gray,  // pointerul de scriere, deja sincronizat
  output logic [ADDR_W-1:0] raddr,
  output logic [ADDR_W:0]   rptr_gray,      // pleacă spre domeniul de scriere
  output logic              empty
);

  logic [ADDR_W:0] rbin, rbin_next, rgray_next;

  assign rbin_next  = rbin + (rd_en && !empty);
  assign rgray_next = (rbin_next >> 1) ^ rbin_next;
  assign raddr      = rbin[ADDR_W-1:0];

  always_ff @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
      rbin      <= '0;
      rptr_gray <= '0;
      empty     <= 1'b1;   // după reset FIFO-ul e gol
    end else begin
      rbin      <= rbin_next;
      rptr_gray <= rgray_next;
      // Pesimism: rq2_wptr_gray e în urmă, deci pare că s-a scris mai puțin
      // -> empty coboară târziu. Nu citim niciodată o locație nescrisă.
      empty     <= (rgray_next == rq2_wptr_gray);
    end
  end

endmodule
