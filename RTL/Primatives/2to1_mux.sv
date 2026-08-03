module mux2 #(parameter WIDTH = 32)(
  input logic [WIDTH-1:0] a, b,
  input logic sel,
  output logic [WIDTH-1:0] result
);

  assign result = sel ? a : b;

endmodule
