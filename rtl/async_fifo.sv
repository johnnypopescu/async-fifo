// FIFO asincron — modulul de top.
//
//   domeniul wr_clk                              domeniul rd_clk
//  ┌──────────────┐   wptr_gray   ┌─────────┐  rq2_wptr_gray ┌───────────────┐
//  │ wr_ptr_full  │──────────────>│sync_2ff │───────────────>│ rd_ptr_empty  │
//  │              │               └─────────┘                │               │
//  │              │ wq2_rptr_gray ┌─────────┐   rptr_gray    │               │
//  │              │<──────────────│sync_2ff │<───────────────│               │
//  └──────┬───────┘               └─────────┘                └───────┬───────┘
//         │ waddr                ┌──────────┐                  raddr │
//         └─────────────────────>│ fifo_mem │<───────────────────────┘
//                   wr_data ────>│          │────> rd_data
//                                └──────────┘
//
// Scriere acceptată când wr_en && !full; citire când rd_en && !empty.
// DEPTH trebuie să fie putere a lui 2 (pointerii Gray se bazează pe asta).
// Resetările se presupun deja sincronizate în domeniile lor.
module async_fifo #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 8
) (
  // domeniul de scriere
  input  logic             wr_clk,
  input  logic             wr_rst_n,
  input  logic             wr_en,
  input  logic [WIDTH-1:0] wr_data,
  output logic             full,
  // domeniul de citire
  input  logic             rd_clk,
  input  logic             rd_rst_n,
  input  logic             rd_en,
  output logic [WIDTH-1:0] rd_data,
  output logic             empty
);

  localparam int ADDR_W = $clog2(DEPTH);

  logic [ADDR_W-1:0] waddr, raddr;
  logic [ADDR_W:0]   wptr_gray, rptr_gray;
  logic [ADDR_W:0]   wq2_rptr_gray, rq2_wptr_gray;

  fifo_mem #(.WIDTH(WIDTH), .ADDR_W(ADDR_W)) u_mem (
    .wr_clk  (wr_clk),
    .wr_en   (wr_en && !full),
    .waddr   (waddr),
    .wr_data (wr_data),
    .raddr   (raddr),
    .rd_data (rd_data)
  );

  wr_ptr_full #(.ADDR_W(ADDR_W)) u_wr_ptr (
    .wr_clk        (wr_clk),
    .wr_rst_n      (wr_rst_n),
    .wr_en         (wr_en),
    .wq2_rptr_gray (wq2_rptr_gray),
    .waddr         (waddr),
    .wptr_gray     (wptr_gray),
    .full          (full)
  );

  rd_ptr_empty #(.ADDR_W(ADDR_W)) u_rd_ptr (
    .rd_clk        (rd_clk),
    .rd_rst_n      (rd_rst_n),
    .rd_en         (rd_en),
    .rq2_wptr_gray (rq2_wptr_gray),
    .raddr         (raddr),
    .rptr_gray     (rptr_gray),
    .empty         (empty)
  );

  // pointerul de citire -> domeniul de scriere (pentru full)
  sync_2ff #(.WIDTH(ADDR_W+1)) u_sync_r2w (
    .clk   (wr_clk),
    .rst_n (wr_rst_n),
    .d     (rptr_gray),
    .q     (wq2_rptr_gray)
  );

  // pointerul de scriere -> domeniul de citire (pentru empty)
  sync_2ff #(.WIDTH(ADDR_W+1)) u_sync_w2r (
    .clk   (rd_clk),
    .rst_n (rd_rst_n),
    .d     (wptr_gray),
    .q     (rq2_wptr_gray)
  );

endmodule
