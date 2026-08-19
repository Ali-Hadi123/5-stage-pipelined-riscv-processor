import riscv_pkg::*;

module de_reg(
    input logic clk,
    input logic rst,
    input logic flush,
    input de_reg_t d_in,
    output de_reg_t d_out
);

  function automatic de_reg_t bubble();
    bubble.pc                  = '0;
    bubble.pc_plus4            = '0;
    bubble.rdata1              = '0;
    bubble.rdata2              = '0;
    bubble.imm_out             = '0;
    bubble.funct3              = 3'b0;
 
    bubble.rs1_addr            = '0;
    bubble.rs2_addr            = '0;
    bubble.rd_addr             = '0;
 
    bubble.alu_src             = ALU_SRC_RD2;
    bubble.mem_read            = 1'b0;
    bubble.mem_write           = 1'b0;
    bubble.result_src          = RESULT_ALU;
    bubble.is_branch           = 1'b0;
    bubble.is_jal              = 1'b0;
    bubble.is_jalr             = 1'b0;
    bubble.reg_write           = 1'b0;
    bubble.alu_ctrl            = ALU_ADD;
    bubble.mem_size            = MEM_WORD;
    bubble.mem_unsigned        = 1'b0;
 
    bubble.illegal_instr_main  = 1'b0;
    bubble.illegal_instr_mem   = 1'b0;
    bubble.illegal_instr_alu   = 1'b0;
  endfunction

  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      d_out <= bubble();
    else if (flush) begin
      d_out.reg_write  <= 1'b0;
      d_out.mem_write  <= 1'b0;
      d_out.mem_read   <= 1'b0;
      d_out.is_branch  <= 1'b0;
      d_out.is_jal     <= 1'b0;
      d_out.is_jalr    <= 1'b0;
      d_out.illegal_instr_main <= 1'b0;
      d_out.illegal_instr_mem  <= 1'b0;
      d_out.illegal_instr_alu  <= 1'b0;
    end
    else
        d_out <= d_in;
  end
  
endmodule