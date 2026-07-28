import riscv_pkg::*;

module main_decoder (
  input opcode_e op_code,
  
  output result_src_e result_src,
  output logic mem_read,
  output logic mem_write,
  output alu_src_e alu_src,
  output instr_fmt_e imm_src,
  output logic reg_write,
  output logic illegal_instr_main,

  output logic is_branch,
  output logic is_jal,
  output logic is_jalr,
  
  output alu_op_e alu_op
);
  
  always_comb begin

    // Creating safe signals as a default case.
    
    is_branch = 1'b0;
    is_jal = 1'b0;          
    is_jalr = 1'b0;             // PCnext is PC + 4 as a default
    
    result_src = RESULT_ALU;     // ALU result
    mem_write  = 1'b0;           // Never write memory by default
    mem_read   = 1'b0;           // Never load memory by default
    alu_src    = ALU_SRC_RD2;    // Use register operand (RD2)
    imm_src    = FMT_I;          // Doesn't matter unless ALUSrc=1
    reg_write  = 1'b0;           // Don't write registers
    alu_op     = ALUOP_ADD;      // Default ALU operation (typically ADD)
    illegal_instr_main = 1'b1;       // Assumes invalid instruction
    
    unique case(op_code)
      OP_ARTH_REG: begin
        result_src = RESULT_ALU;
        mem_write = 1'b0;
        mem_read   = 1'b0;
        alu_src = ALU_SRC_RD2;
        imm_src = FMT_I;
        reg_write = 1'b1;
        alu_op = ALUOP_FUNCT;
        illegal_instr_main = 1'b0;
      end

      OP_ARTH_IMM: begin
        result_src = RESULT_ALU;
        mem_write = 1'b0;
        mem_read   = 1'b0;
        alu_src = ALU_SRC_IMM;
        imm_src = FMT_I;
        reg_write = 1'b1;
        alu_op = ALUOP_FUNCT;
        illegal_instr_main = 1'b0;
      end

      OP_LOAD: begin
        result_src = RESULT_MEM;
        mem_write = 1'b0;
        mem_read   = 1'b1;
        alu_src = ALU_SRC_IMM;
        imm_src = FMT_I;
        reg_write = 1'b1;
        alu_op = ALUOP_ADD;
        illegal_instr_main = 1'b0;
      end

      OP_STORE: begin
        result_src = RESULT_ALU;
        mem_write = 1'b1;
        mem_read   = 1'b0;
        alu_src = ALU_SRC_IMM;
        imm_src = FMT_S;
        reg_write = 1'b0;
        alu_op = ALUOP_ADD;
        illegal_instr_main = 1'b0;
      end

      OP_BRANCH: begin
        is_branch = 1'b1;
        
        result_src = RESULT_ALU;
        mem_write = 1'b0;
        mem_read   = 1'b0;
        alu_src = ALU_SRC_RD2;
        imm_src = FMT_B;
        reg_write = 1'b0;
        alu_op = ALUOP_BRANCH;
        illegal_instr_main = 1'b0;
      end

      OP_JAL: begin
        is_jal = 1'b1;
        
        result_src = RESULT_PCPLUS4;
        mem_write = 1'b0;
        mem_read   = 1'b0;
        alu_src = ALU_SRC_IMM;
        imm_src = FMT_J;
        reg_write = 1'b1;
        alu_op = ALUOP_ADD;
        illegal_instr_main = 1'b0;
      end

      OP_JALR: begin
        is_jalr = 1'b1;
        
        result_src = RESULT_PCPLUS4;
        mem_write = 1'b0;
        mem_read   = 1'b0;
        alu_src = ALU_SRC_IMM;
        imm_src = FMT_I;
        reg_write = 1'b1;
        alu_op = ALUOP_ADD;
        illegal_instr_main = 1'b0;
      end

      OP_LUI: begin
        result_src = RESULT_ALU;        
        mem_write  = 1'b0;     
        mem_read   = 1'b0;
        alu_src    = ALU_SRC_IMM;        
        imm_src    = FMT_U;       
        reg_write  = 1'b1;           
        alu_op     = ALUOP_PASS_B;
        illegal_instr_main = 1'b0;
      end

      OP_AUIPC: begin
        result_src = RESULT_PCTARGET;        
        mem_write  = 1'b0;        
        mem_read   = 1'b0;
        alu_src    = ALU_SRC_RD2;        
        imm_src    = FMT_U;       
        reg_write  = 1'b1;           
        alu_op     = ALUOP_ADD;
        illegal_instr_main = 1'b0;
      end

      //Although allowing fence and system instructions to be handled by the default would not alter 
      //functionality, seperating them allows for the true, illegal instructions to be more easily flagged.
      
      OP_FENCE: ;  
      OP_SYSTEM: ; 

      default: illegal_instr_main = 1'b1;
    endcase
  end
endmodule
