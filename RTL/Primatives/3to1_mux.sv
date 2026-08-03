module mux3 #(parameter WIDTH = 32) (
  input logic [WIDTH-1:0] a, b, c,
  input logic [1:0] sel,
  output logic [WIDTH-1:0] result
);

  always_comb begin
    unique case(sel)
      2'b00: result = a;
      2'b01: result = b;
      2'b10: result = c;
      default: result = {WIDTH{1'b0}};
    endcase
  end

endmodule
