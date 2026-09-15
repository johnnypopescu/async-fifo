// FIFO sincron — încălzirea dinainte de varianta asincronă.
//
// Aceeași idee cu bitul suplimentar în pointeri, dar fără cod Gray și fără
// sincronizatoare: totul e pe un singur ceas, deci flag-urile sunt exacte.
module sync_fifo #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 8          // putere a lui 2
) (
  input  logic             clk,
  input  logic             rst_n,
  input  logic             wr_en,
  input  logic [WIDTH-1:0] wr_data,
  output logic             full,
  input  logic             rd_en,
  output logic [WIDTH-1:0] rd_data,
  output logic             empty
);

  localparam int ADDR_W = $clog2(DEPTH);

  logic [WIDTH-1:0] mem [0:DEPTH-1];
  logic [ADDR_W:0]  wptr, rptr;    // ADDR_W biți de adresă + 1 bit suplimentar

  wire do_write = wr_en && !full;
  wire do_read  = rd_en && !empty;

  always_ff @(posedge clk) begin
    if (do_write) mem[wptr[ADDR_W-1:0]] <= wr_data;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wptr <= '0;
      rptr <= '0;
    end else begin
      if (do_write) wptr <= wptr + 1'b1;
      if (do_read)  rptr <= rptr + 1'b1;
    end
  end

  assign rd_data = mem[rptr[ADDR_W-1:0]];
  assign empty   = (wptr == rptr);
  assign full    = (wptr[ADDR_W-1:0] == rptr[ADDR_W-1:0]) &&
                   (wptr[ADDR_W]     != rptr[ADDR_W]);

endmodule
