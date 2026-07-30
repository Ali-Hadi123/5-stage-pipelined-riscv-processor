import riscv_pkg::*;

module alu_decoder (
  input opcode_e op_code,
  input alu_op_e alu_op,
  input funct3_arth_e funct3,
  input funct7_e funct7,
  output alu_ctrl_e alu_ctrl,
  output logic illegal_instr_alu
);

  logic is_R_type;                             
  assign is_R_type = (op_code == OP_ARTH_REG);

  //"is_R_type" is required to ensure that the ALU decoder does not try to read the non-existant funct7 
  //of an I type instruction as both I and R type instructions output ALUOP_FUNCT and have F3_ADD_SUB.
  
  always_comb begin
    illegal_instr_alu = 1'b0;
    
    unique case(alu_op)
      ALUOP_ADD: alu_ctrl = ALU_ADD;
      ALUOP_BRANCH: alu_ctrl = ALU_SUB;
      ALUOP_PASS_B: alu_ctrl = ALU_PASS_B;
      
      ALUOP_FUNCT: begin
        unique case(funct3)
          F3_ADD_SUB: alu_ctrl = alu_ctrl_e'((is_R_type && funct7 == F7_ALT) ? ALU_SUB : ALU_ADD);
          F3_SLL: alu_ctrl = ALU_SLL;
          F3_SLT: alu_ctrl = ALU_SLT;
          F3_SLTU: alu_ctrl = ALU_SLTU;
          F3_XOR: alu_ctrl = ALU_XOR;
          F3_SRL_SRA: alu_ctrl = alu_ctrl_e'((funct7 == F7_ALT) ? ALU_SRA : ALU_SRL);
          F3_OR: alu_ctrl = ALU_OR;
          F3_AND: alu_ctrl = ALU_AND;
        endcase
      end

      default: begin
        alu_ctrl = ALU_ADD;
        illegal_instr_alu = 1'b1;
      end
    endcase
  end
endmodule

