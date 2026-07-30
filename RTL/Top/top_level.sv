import riscv_pkg::*;

module top #(
  parameter int unsigned ram_size = 1024,
  parameter int unsigned rom_size = 1024,
  parameter init_mem = ""
)(
  input logic clk,
  input logic rst,
  output logic illegal_instr
);

  //Fetching Instructions:

  logic [XLEN-1:0] pc_out;
  logic [XLEN-1:0] next_pc;
  logic [XLEN-1:0] instr;

  pc u_pc(
    .clk(clk),
    .rst(rst),
    .next_pc(next_pc),
    .pc_out(pc_out)
  );

  imem #(
    .init_mem(init_mem),
    .rom_size(rom_size)
  ) u_imem(
    .pc_addr(pc_out),
    .instr(instr)
  );

  //Instruction Field Extraction:

  opcode_e op_code;
  logic [4:0] rs1_addr, rs2_addr, rd_addr;
  logic [2:0] funct3;
  logic [6:0] funct7;

  assign op_code   = opcode_e'(riscv_pkg::get_opcode(instr));
  assign rs1_addr  = riscv_pkg::get_rs1(instr);
  assign rs2_addr  = riscv_pkg::get_rs2(instr);
  assign rd_addr   = riscv_pkg::get_rd(instr);
  assign funct3    = riscv_pkg::get_funct3(instr);
  assign funct7    = riscv_pkg::get_funct7(instr);

  //Generating Control Signals:

  result_src_e result_src;
  logic mem_read, mem_write;
  alu_src_e alu_src;
  instr_fmt_e imm_src;
  logic reg_write;
  logic is_branch, is_jal, is_jalr;
  alu_op_e alu_op;
  logic illegal_instr_main;

  main_decoder u_main_decoder(
    .op_code(op_code),
    .result_src(result_src),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .alu_src(alu_src),
    .imm_src(imm_src),
    .reg_write(reg_write),
    .illegal_instr_main(illegal_instr_main),
    .is_branch(is_branch),
    .is_jal(is_jal),
    .is_jalr(is_jalr),
    .alu_op(alu_op)
  );

  alu_ctrl_e alu_ctrl;
  logic illegal_instr_alu;

  alu_decoder u_alu_decoder(
    .op_code(op_code),
    .alu_op(alu_op),
    .funct3(funct3),
    .funct7(funct7),
    .alu_ctrl(alu_ctrl),
    .illegal_instr_alu(illegal_instr_alu)
  );

  mem_size_e mem_size;
  logic mem_unsigned;
  logic illegal_instr_mem;

  mem_decoder u_mem_decoder(
    .op_code(op_code),
    .funct3(funct3),
    .mem_size(mem_size),
    .mem_unsigned(mem_unsigned),
    .illegal_instr_mem(illegal_instr_mem)
  );

  logic branch_taken;
  logic illegal_instr_branch;

  branch_decoder u_branch_decoder(
    .funct3(funct3_branch_e'(funct3)),
    .is_zero(alu_zero),
    .is_less(alu_less),
    .is_less_u(alu_less_u),
    .branch_taken(branch_taken),
    .illegal_instr_branch(illegal_instr_branch)
  );
  
  //Detecting Illegal Instructions:
  assign illegal_instr = illegal_instr_main | illegal_instr_alu | illegal_instr_mem | (is_branch & illegal_instr_branch);

  logic [XLEN-1:0] imm_out;

  imm_gen u_imm_gen( //Despite imm_gen handling instruction field extraction, it's placed here because it required imm_src.
    .instr(instr),
    .imm_src(imm_src),
    .imm_out(imm_out)
  );

  //Register File:

  logic [XLEN-1:0] read_data_1, read_data_2;
  logic [XLEN-1:0] write_data;

  logic reg_write_safe;
  assign reg_write_safe = reg_write & ~illegal_instr; //Ensures reg_write can't accidently be 
                                                      //set to high due to an invalid instruction. 
  regf u_regf(
    .clk(clk),
    .rs1(rs1_addr),
    .rs2(rs2_addr),
    .rd(rd_addr),
    .wd(write_data),
    .reg_write(reg_write_safe),
    .rdata1(read_data_1),
    .rdata2(read_data_2)
  );

  //Execution:

  logic [XLEN-1:0] alu_b;

  mux2 #(.WIDTH(XLEN)) u_alu_src_b_mux(
    .a(imm_out),
    .b(read_data_2),
    .sel(alu_src),
    .result(alu_b)
  );

  logic [XLEN-1:0] alu_result;
  logic alu_zero, alu_less, alu_less_u;

  alu u_alu(
    .alu_ctrl(alu_ctrl),
    .a(read_data_1),
    .b(alu_b),
    .result(alu_result),
    .is_zero(alu_zero),
    .is_less(alu_less),
    .is_less_u(alu_less_u)
  );

  //Computing Next PC:

  logic [XLEN-1:0] pc_plus4, pc_target;

  adder #(.WIDTH(XLEN)) u_pc_plus4_adder(
    .a(pc_out),
    .b(XLEN'(4)),
    .sum(pc_plus4)
  );

  adder #(.WIDTH(XLEN)) u_pc_target_adder(
    .a(pc_out),
    .b(imm_out),
    .sum(pc_target)
  );

  pc_src_e pc_src;

  pc_comp u_pc_comp(
    .is_branch(is_branch),
    .branch_taken(branch_taken),
    .is_jal(is_jal),
    .is_jalr(is_jalr),
    .pc_src(pc_src)
  );

  logic [XLEN-1:0] pc_mux_out;
  
  mux3 #(.WIDTH(XLEN)) u_pc_mux(
    .a(pc_plus4),
    .b(pc_target),
    .c(alu_result),
    .sel(pc_src),
    .result(pc_mux_out)
  );

  logic next_pc_normal;
  assign next_pc_normal = {pc_mux_out[XLEN-1:1], 1'b0}; //LSB set to 0 to handle JALR instructions.

  assign next_pc = illegal_instr ? pc_out : next_pc_normal; //Freezes the pc in the case of an illegal instruction.

  //Handling Memory and Writeback:

  logic [XLEN-1:0] mem_read_data;

  logic mem_read_safe, mem_write_safe;
  assign mem_read_safe = mem_read & ~illegal_instr;
  assign mem_write_safe = mem_write & ~illegal_instr;
  
  dmem #(.ram_size(ram_size)) u_dmem(
    .clk(clk),
    .byte_addr(alu_result),
    .wdata(read_data_2),
    .mem_read(mem_read_safe),
    .mem_write(mem_write_safe),
    .mem_size(mem_size),
    .mem_unsigned(mem_unsigned),
    .read_data(mem_read_data)
  );

  mux4 #(.WIDTH(XLEN)) u_writeback_mux(
    .a(alu_result),
    .b(mem_read_data),
    .c(pc_plus4),
    .d(pc_target),
    .sel(result_src),
    .result(write_data)
  );

endmodule
