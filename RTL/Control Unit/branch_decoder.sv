import riscv_pkg::*;

module branch_decoder (
  input funct3_branch_e funct3,
  input logic [XLEN-1:0] a,
  input logic [XLEN-1:0] b,
  output logic branch_taken,
  output logic illegal_instr_branch
);

  logic is_zero;
  logic is_less;
  logic is_less_u;

  always_comb begin
    illegal_instr_branch = 1'b0;

    is_zero = (a == b);
    is_less = ($signed(a) < $signed(b));
    is_less_u = (a < b);
    
    unique case(funct3)
        F3_BEQ:  branch_taken = is_zero;
        F3_BNE:  branch_taken = ~is_zero;
        F3_BLT:  branch_taken = is_less;
        F3_BGE:  branch_taken = ~is_less;
        F3_BLTU: branch_taken = is_less_u;
        F3_BGEU: branch_taken = ~is_less_u;
        
        default: begin
          branch_taken = 1'b0;
          illegal_instr_branch = 1'b1;
        end
    endcase
  end
endmodule
