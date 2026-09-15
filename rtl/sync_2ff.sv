// Sincronizator cu 2 registre.
//
// Primul registru (meta) poate intra în metastabilitate când `d` se schimbă
// aproape de frontul lui `clk`. Are o perioadă întreagă de ceas să se
// stabilizeze înainte ca al doilea registru (q) să-l eșantioneze, deci
// probabilitatea ca metastabilitatea să ajungă mai departe devine neglijabilă.
//
// ATENȚIE: pentru WIDTH > 1 fiecare bit se sincronizează independent și
// biții pot ajunge în cicluri diferite. E sigur doar dacă între două valori
// consecutive se schimbă un singur bit — de aici codul Gray pe pointeri.
module sync_2ff #(
  parameter int WIDTH = 1
) (
  input  logic             clk,
  input  logic             rst_n,
  input  logic [WIDTH-1:0] d,
  output logic [WIDTH-1:0] q
);

  // ASYNC_REG îi spune lui Vivado să țină registrele lipite și să nu le
  // optimizeze; simulatoarele ignoră atributul.
  (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] meta;
  (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] q_r;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      meta <= '0;
      q_r  <= '0;
    end else begin
      meta <= d;
      q_r  <= meta;
    end
  end

  assign q = q_r;

endmodule
