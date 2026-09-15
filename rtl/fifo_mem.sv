// Memorie dual-port: scriere sincronă pe wr_clk, citire combinațională.
//
// Citirea combinațională e sigură deși datele sunt scrise în alt domeniu:
// o locație devine citibilă doar după ce pointerul de scriere a trecut prin
// sincronizator (minim 2 fronturi de rd_clk), deci datele de la `raddr`
// sunt stabile de mult când domeniul de citire le folosește.
//
// Rezultat: FIFO de tip first-word-fall-through — `rd_data` e valid
// oricând `empty` e 0, iar `rd_en` doar avansează la următorul element.
module fifo_mem #(
  parameter int WIDTH  = 8,
  parameter int ADDR_W = 3
) (
  input  logic              wr_clk,
  input  logic              wr_en,
  input  logic [ADDR_W-1:0] waddr,
  input  logic [WIDTH-1:0]  wr_data,
  input  logic [ADDR_W-1:0] raddr,
  output logic [WIDTH-1:0]  rd_data
);

  logic [WIDTH-1:0] mem [0:(1<<ADDR_W)-1];

  always_ff @(posedge wr_clk) begin
    if (wr_en) mem[waddr] <= wr_data;
  end

  assign rd_data = mem[raddr];

endmodule
