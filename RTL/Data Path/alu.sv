import riscv_pkg::*;

module alu (
  input alu_ctrl_e alu_ctrl,
  input [XLEN-1:0] a,
  input [XLEN-1:0] b,
  output logic [XLEN-1:0] result,
);

  logic [XLEN-1:0] sum;
  logic cout;
  
  always_comb begin
    if (alu_ctrl == ALU_ADD)
      {cout, sum} = {1'b0, a} + {1'b0,  b};
    else
      {cout, sum} = {1'b0, a} + {1'b0, ~b} + 33'd1;
  end

  always_comb begin
    unique case(alu_ctrl)
      ALU_ADD:    result = sum;
      ALU_SUB:    result = sum;
      ALU_AND:    result = a & b;
      ALU_OR:     result = a | b;
      ALU_XOR:    result = a ^ b;
      ALU_SLT:    result = {{(XLEN-1){1'b0}}, ($signed(a) < $signed(b))};
      ALU_SLTU:   result = {{(XLEN-1){1'b0}}, (a < b)};
      ALU_SLL:    result = a << b[4:0];
      ALU_SRL:    result = a >> b[4:0];
      ALU_SRA:    result = $signed(a) >>> b[4:0];
      ALU_PASS_B: result = b;
      default: result = '0;
    endcase
  end

endmodule
