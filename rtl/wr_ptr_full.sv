// Pointerul de scriere și flag-ul `full` — totul în domeniul wr_clk.
//
// Pointerul are ADDR_W+1 biți: ADDR_W biți de adresă plus un bit suplimentar
// care arată dacă scrierea a „făcut turul" memoriei o dată în plus față de
// citire.
//
// Condiția de plin în binar: adresele egale, bitul suplimentar diferit.
// În cod Gray asta înseamnă: cei doi biți de sus inversați, restul egali.
// (Gray-ul oglindește jumătatea a doua a secvenței, de aceea se inversează
// și bitul de sub MSB, nu doar MSB-ul.)
module wr_ptr_full #(
  parameter int ADDR_W = 3
) (
  input  logic              wr_clk,
  input  logic              wr_rst_n,
  input  logic              wr_en,
  input  logic [ADDR_W:0]   wq2_rptr_gray,  // pointerul de citire, deja sincronizat
  output logic [ADDR_W-1:0] waddr,
  output logic [ADDR_W:0]   wptr_gray,      // pleacă spre domeniul de citire
  output logic              full
);

  // Masca pentru cei doi biți de sus, ex. ADDR_W=3 -> 4'b1100
  localparam logic [ADDR_W:0] TOP2 = 3 << (ADDR_W - 1);

  logic [ADDR_W:0] wbin, wbin_next, wgray_next;

  assign wbin_next  = wbin + (wr_en && !full);
  assign wgray_next = (wbin_next >> 1) ^ wbin_next;
  assign waddr      = wbin[ADDR_W-1:0];

  always_ff @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
      wbin      <= '0;
      wptr_gray <= '0;
      full      <= 1'b0;
    end else begin
      wbin      <= wbin_next;
      // Gray-ul trece prin registru, nu direct din logica combinațională:
      // altfel ar putea avea glitch-uri cu mai mulți biți schimbați simultan.
      wptr_gray <= wgray_next;
      // Pesimism: wq2_rptr_gray e în urmă cu 2+ cicluri, deci pare că s-a
      // citit mai puțin decât în realitate -> full se ridică devreme și
      // coboară târziu. Niciodată invers.
      full      <= (wgray_next == (wq2_rptr_gray ^ TOP2));
    end
  end

endmodule
