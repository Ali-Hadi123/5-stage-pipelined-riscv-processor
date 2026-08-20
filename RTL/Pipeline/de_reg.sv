import riscv_pkg::*;

module de_reg(
    input logic clk,
    input logic rst,
    input logic flush,
    input de_reg_t d_in,
    output de_reg_t d_out
);

  function automatic de_reg_t bubble();
    bubble = '0;
    bubble.alu_ctrl  = ALU_ADD;
    bubble.result_src = RESULT_ALU;
  endfunction

  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      d_out <= bubble();

    else begin
      d_out.pc            <= d_in.pc;
      d_out.pc_plus4      <= d_in.pc_plus4;
      d_out.rdata1        <= d_in.rdata1;
      d_out.rdata2        <= d_in.rdata2;
      d_out.imm_out       <= d_in.imm_out;
      d_out.funct3        <= d_in.funct3;
      d_out.rs1_addr      <= d_in.rs1_addr;
      d_out.rs2_addr      <= d_in.rs2_addr;
      d_out.rd_addr       <= d_in.rd_addr;
      d_out.alu_src       <= d_in.alu_src;
      d_out.alu_ctrl      <= d_in.alu_ctrl;
      d_out.mem_size      <= d_in.mem_size;
      d_out.mem_unsigned  <= d_in.mem_unsigned;

      if (flush) begin
        d_out.mem_read           <= 1'b0;
        d_out.mem_write          <= 1'b0;
        d_out.reg_write          <= 1'b0;
        d_out.is_branch          <= 1'b0;
        d_out.is_jal             <= 1'b0;
        d_out.is_jalr            <= 1'b0;
        d_out.result_src         <= RESULT_ALU;
        d_out.illegal_instr_main <= 1'b0;
        d_out.illegal_instr_mem  <= 1'b0;
        d_out.illegal_instr_alu  <= 1'b0;
      end 
      else begin
        d_out.mem_read            <= d_in.mem_read;
        d_out.mem_write           <= d_in.mem_write;
        d_out.reg_write           <= d_in.reg_write;
        d_out.is_branch           <= d_in.is_branch;
        d_out.is_jal              <= d_in.is_jal;
        d_out.is_jalr             <= d_in.is_jalr;
        d_out.result_src          <= d_in.result_src;
        d_out.illegal_instr_main  <= d_in.illegal_instr_main;
        d_out.illegal_instr_mem   <= d_in.illegal_instr_mem;
        d_out.illegal_instr_alu   <= d_in.illegal_instr_alu;
      end
    end
  end
endmodule