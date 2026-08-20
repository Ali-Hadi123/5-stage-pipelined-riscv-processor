import riscv_pkg::*;

module branch_decoder (
  input funct3_branch_e funct3,
  input logic [XLEN-1:0] a,
  input logic [XLEN-1:0] b,
  output logic branch_taken,
  output logic illegal_instr_branch
);

  always_comb begin
    illegal_instr_branch = 1'b0;
    
    unique case(funct3)
        F3_BEQ:  branch_taken = (a == b);
        F3_BNE:  branch_taken = ~(a == b);
        F3_BLT:  branch_taken = ($signed(a) < $signed(b));
        F3_BGE:  branch_taken = ~($signed(a) < $signed(b));
        F3_BLTU: branch_taken = (a < b);
        F3_BGEU: branch_taken = ~(a < b);
        
        default: begin
          branch_taken = 1'b0;
          illegal_instr_branch = 1'b1;
        end
    endcase
  end
endmodule
