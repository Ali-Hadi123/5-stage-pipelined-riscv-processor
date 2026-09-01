module mux4 #(parameter WIDTH = 32) (
  input logic [WIDTH-1:0] a, b, c, d,
  input logic [1:0] sel,
  output logic [WIDTH-1:0] result
);

  assign result = (sel == 2'b00) ? a : (sel == 2'b01) ? b : (sel == 2'b10) ? c : d;

endmodule
