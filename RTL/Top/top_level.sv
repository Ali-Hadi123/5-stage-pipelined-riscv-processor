import riscv_pkg::*;

module top #(
  parameter int unsigned ram_size = 1024,
  parameter int unsigned rom_size = 1024,
  parameter init_mem = ""
)(
  input logic clk,
  input logic rst,
  output logic illegal_instr,

  output logic [XLEN-1:0] fpga_mem_addr,    //These output ports enable a memory-mapped 
  output logic [XLEN-1:0] fpga_mem_wdata,   //peripheral (see fpga_top.sv file).
  output logic fpga_mem_write
);

    //Pipeline control signals:
    logic stallF, stallD;
    logic flushD, flushE;
    logic halt;

    //Fetch Stage:

    logic [XLEN-1:0] pc_out, next_pc;

    pc u_pc(
        .clk(clk),
        .rst(rst),
        .stall(stallF),
        .next_pc(next_pc),
        .pc_out(pc_out)
    );

    logic [XLEN-1:0] pc_plus4F1;

    adder #(.WIDTH(XLEN)) u_pc_plus4_adder(
        .a(pc_out),
        .b(XLEN'(4)),
        .sum(pc_plus4F1)
    );

    f1f2_reg_t f1f2_in, f1f2_out;
    assign f1f2_in.pc = pc_out;
    assign f1f2_in.pc_plus4 = pc_plus4F1;

    f1f2_reg u_f1f2_reg(
        .clk(clk),
        .rst(rst),
        .stall(stallF),
        .d_in(f1f2_in),
        .d_out(f1f2_out)
    );

    logic [XLEN-1:0] instrF;

    imem #(
        .init_mem(init_mem),
        .rom_size(rom_size)
    ) u_imem(
        .clk(clk),
        .rst(rst),
        .stall(stallF),
        .pc_addr(pc_out),
        .instr(instrF)
    );

    fd_reg_t fd_in, fd_out;
    assign fd_in.instr = instrF;
    assign fd_in.pc = f1f2_out.pc;
    assign fd_in.pc_plus4 = f1f2_out.pc_plus4;

    fd_reg u_fd_reg(
        .clk(clk),
        .rst(rst),
        .stall(stallD),
        .flush(flushD || flush_end),
        .d_in(fd_in),
        .d_out(fd_out)
    );

    //Decode Stage:

    opcode_e op_codeD;
    logic [REG_ADDR_W-1:0] rs1_addrD, rs2_addrD, rd_addrD;
    logic [2:0] funct3D;
    logic [6:0] funct7D;

    assign op_codeD      = opcode_e'(riscv_pkg::get_opcode(fd_out.instr));
    assign rs1_addrD     = riscv_pkg::get_rs1(fd_out.instr);
    assign rs2_addrD     = riscv_pkg::get_rs2(fd_out.instr);
    assign rd_addrD      = riscv_pkg::get_rd(fd_out.instr);
    assign funct3D       = riscv_pkg::get_funct3(fd_out.instr);
    assign funct7D       = riscv_pkg::get_funct7(fd_out.instr);

    result_src_e result_srcD;
    logic mem_readD, mem_writeD;
    alu_src_e alu_srcD;
    instr_fmt_e imm_srcD;
    logic reg_writeD;
    logic illegal_instr_mainD;
    logic is_branchD, is_jalD, is_jalrD;
    alu_op_e alu_opD;

    main_decoder u_main_decoder(
        .op_code(op_codeD),
        .result_src(result_srcD),
        .mem_read(mem_readD),
        .mem_write(mem_writeD),
        .alu_src(alu_srcD),
        .imm_src(imm_srcD),
        .reg_write(reg_writeD),
        .illegal_instr_main(illegal_instr_mainD),
        .is_branch(is_branchD),
        .is_jal(is_jalD),
        .is_jalr(is_jalrD),
        .alu_op(alu_opD)
    );

    alu_ctrl_e alu_ctrlD;
    logic illegal_instr_aluD;

    alu_decoder u_alu_decoder(
        .op_code(op_codeD),
        .alu_op(alu_opD),
        .funct3(funct3_arth_e'(funct3D)),
        .funct7(funct7_e'(funct7D)),
        .alu_ctrl(alu_ctrlD),
        .illegal_instr_alu(illegal_instr_aluD)
    );

    mem_size_e mem_sizeD;
    logic mem_unsignedD;
    logic illegal_instr_memD;
    
    mem_decoder u_mem_decoder(
        .op_code(op_codeD),
        .funct3(funct3D),
        .mem_size(mem_sizeD),
        .mem_unsigned(mem_unsignedD),
        .illegal_instr_mem(illegal_instr_memD)
    );

    logic [XLEN-1:0] imm_outD;

    imm_gen u_imm_gen(
        .instr(fd_out.instr),
        .imm_src(imm_srcD),
        .imm_out(imm_outD)
    );

    logic [XLEN-1:0] reg_rdata1, reg_rdata2;

    regf u_regf(                     //rd_addr, wb_data, and reg_write are from the writeback stage.
        .clk(clk),
        .rs1(rs1_addrD),
        .rs2(rs2_addrD),
        .rd(mw_out.rd_addr),
        .wd(wb_data),
        .reg_write(reg_write_safe),
        .rdata1(reg_rdata1),
        .rdata2(reg_rdata2)
    );

    de_reg_t de_in, de_out;
    assign de_in.pc        = fd_out.pc;
    assign de_in.pc_plus4  = fd_out.pc_plus4;
    assign de_in.rdata1    = reg_rdata1;
    assign de_in.rdata2    = reg_rdata2;
    assign de_in.imm_out   = imm_outD;
    assign de_in.funct3    = funct3D;
    
    assign de_in.rs1_addr  = rs1_addrD;
    assign de_in.rs2_addr  = rs2_addrD;
    assign de_in.rd_addr   = rd_addrD;
    
    assign de_in.alu_src      = alu_srcD;
    assign de_in.mem_read     = mem_readD;
    assign de_in.mem_write    = mem_writeD;
    assign de_in.result_src   = result_srcD;
    assign de_in.is_branch    = is_branchD;
    assign de_in.is_jal       = is_jalD;
    assign de_in.is_jalr      = is_jalrD;
    assign de_in.reg_write    = reg_writeD;
    assign de_in.alu_ctrl     = alu_ctrlD;
    assign de_in.mem_size     = mem_sizeD;
    assign de_in.mem_unsigned = mem_unsignedD;
    
    assign de_in.illegal_instr_main = illegal_instr_mainD;
    assign de_in.illegal_instr_mem  = illegal_instr_memD;
    assign de_in.illegal_instr_alu  = illegal_instr_aluD;
    
    de_reg u_de_reg(
        .clk(clk),
        .rst(rst),
        .flush(flushE || flush_end),
        .d_in(de_in),
        .d_out(de_out)
    );

    //Execute Stage:
    
    //Forwarding
    fwdA_e fwdA;
    fwdB_e fwdB;

    fwd_unit u_fwd_unit(
        .rs1E(de_out.rs1_addr),
        .rs2E(de_out.rs2_addr),
        .rdM(em_out.rd_addr),
        .rdW(mw_out.rd_addr),
        .reg_writeM(em_out.reg_write),
        .reg_writeW(mw_out.reg_write),
        .fwdA(fwdA),
        .fwdB(fwdB)
    );

    logic [XLEN-1:0] fwd_dataM;
    assign fwd_dataM = (em_out.result_src == RESULT_PCPLUS4)  ? em_out.pc_plus4  :
                        (em_out.result_src == RESULT_PCTARGET) ? em_out.pc_target :
                        em_out.alu_result;

    logic [XLEN-1:0] fwd_rdata1E, fwd_rdata2E;

    mux3 #(.WIDTH(XLEN)) u_fwdA_mux(
        .a(de_out.rdata1),
        .b(wb_data),
        .c(fwd_dataM),
        .sel(fwdA),
        .result(fwd_rdata1E)
    );
 
    mux3 #(.WIDTH(XLEN)) u_fwdB_mux(
        .a(de_out.rdata2),
        .b(wb_data),
        .c(fwd_dataM),
        .sel(fwdB),
        .result(fwd_rdata2E)
    );

    logic [XLEN-1:0] alu_bE;
    
    mux2 #(.WIDTH(XLEN)) u_alu_src_b_mux(
        .a(de_out.imm_out),
        .b(fwd_rdata2E),
        .sel(de_out.alu_src),
        .result(alu_bE)
    );

    logic [XLEN-1:0] alu_resultE;
    logic alu_zeroE, alu_lessE, alu_less_uE;

    alu u_alu(
        .alu_ctrl(de_out.alu_ctrl),
        .a(fwd_rdata1E),
        .b(alu_bE),
        .result(alu_resultE)
    );

    logic branch_takenE;
    logic illegal_instr_branchE;

    branch_decoder u_branch_decoder(
        .funct3(funct3_branch_e'(de_out.funct3)),
        .a(fwd_rdata1E),
        .b(alu_bE),
        .branch_taken(branch_takenE),
        .illegal_instr_branch(illegal_instr_branchE)
    );

    pc_src_e pc_srcE;

    pc_comp u_pc_comp(
        .is_branch(de_out.is_branch),
        .branch_taken(branch_takenE),
        .is_jal(de_out.is_jal),
        .is_jalr(de_out.is_jalr),
        .pc_src(pc_srcE)
    );

    logic [XLEN-1:0] pc_targetE;

    adder #(.WIDTH(XLEN)) u_pc_target_adder(
        .a(de_out.pc),
        .b(de_out.imm_out),
        .sum(pc_targetE)
    );

    logic [XLEN-1:0] pc_mux_outE;

    mux3 #(.WIDTH(XLEN)) u_pc_mux(
        .a(pc_plus4F1),
        .b(pc_targetE),
        .c(alu_resultE),
        .sel(pc_srcE),
        .result(pc_mux_outE)
    );

    logic [XLEN-1:0] next_pc_normal;
    assign next_pc_normal = {pc_mux_outE[XLEN-1:1], 1'b0};  //LSB cleared for JALR.
    
    //Freeze PC in case of illegal instruction:
    assign next_pc = halt ? pc_out : next_pc_normal;

    assign illegal_instr = de_out.illegal_instr_main | de_out.illegal_instr_alu | de_out.illegal_instr_mem | (de_out.is_branch & illegal_instr_branchE);

    logic flush_end;
    assign flush_end = halt ? 1'b1 : 1'b0;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            halt <= 1'b0;
        else if (illegal_instr)
            halt <= 1'b1;
    end

    //Hazard Unit Logic:
    hzrd_unit u_hzrd_unit(
        .mem_readE(de_out.mem_read),
        .rs1D(rs1_addrD),
        .rs2D(rs2_addrD),
        .rdE(de_out.rd_addr),
        .pc_srcE(pc_srcE),
        .stallF(stallF),
        .stallD(stallD),
        .flushD(flushD),
        .flushE(flushE)
    );

    em_reg_t em_in, em_out;
 
    assign em_in.alu_result   = alu_resultE;
    assign em_in.write_data   = fwd_rdata2E;
    assign em_in.pc_plus4     = de_out.pc_plus4;
    assign em_in.pc_target    = pc_targetE;
    assign em_in.rd_addr      = de_out.rd_addr;
    assign em_in.result_src   = de_out.result_src;
    assign em_in.mem_read     = de_out.mem_read;
    assign em_in.mem_write    = de_out.mem_write;
    assign em_in.mem_size     = de_out.mem_size;
    assign em_in.mem_unsigned = de_out.mem_unsigned;
    assign em_in.reg_write    = de_out.reg_write;
    assign em_in.illegal_instr = illegal_instr;
    
    em_reg u_em_reg(
        .clk(clk),
        .rst(rst),
        .d_in(em_in),
        .d_out(em_out)
    );

    //Memory Stage:

    logic mem_read_safeM, mem_write_safeM;
    assign mem_read_safeM  = em_out.mem_read  & ~em_out.illegal_instr;
    assign mem_write_safeM = em_out.mem_write & ~em_out.illegal_instr;

    assign fpga_mem_addr = em_out.alu_result;
    assign fpga_mem_wdata = em_out.write_data;
    assign fpga_mem_write = mem_write_safeM;

    logic [XLEN-1:0] mem_read_dataM;

    dmem #(.ram_size(ram_size)) u_dmem(
        .clk(clk),
        .byte_addr(em_out.alu_result),
        .wdata(em_out.write_data),
        .mem_read(mem_read_safeM),
        .mem_write(mem_write_safeM),
        .mem_size(em_out.mem_size),
        .mem_unsigned(em_out.mem_unsigned),
        .read_data(mem_read_dataM)
    );

    m1m2_reg_t m1m2_in, m1m2_out;
    assign m1m2_in.alu_result    = em_out.alu_result;
    assign m1m2_in.rd_addr       = em_out.rd_addr;
    assign m1m2_in.pc_target     = em_out.pc_target;
    assign m1m2_in.pc_plus4      = em_out.pc_plus4
    assign m1m2_in.result_src    = em_out.result_src;
    assign m1m2_in.reg_write     = em_out.reg_write;
    assign m1m2_in.illegal_instr = em_out.illegal_instr;

    m1m2_reg u_m1m2_reg(
        .clk(clk),
        .rst(rst),
        .d_in(m1m2_in),
        .d_out(m1m2_out)
    );

    mw_reg_t mw_in, mw_out;
    assign mw_in.mem_rdata     = mem_read_dataM;
    assign mw_in.alu_result    = m1m2_out.alu_result;
    assign mw_in.pc_plus4      = m1m2_out.pc_plus4;
    assign mw_in.pc_target     = m1m2_out.pc_target;
    assign mw_in.rd_addr       = m1m2_out.rd_addr;
    assign mw_in.reg_write     = m1m2_out.reg_write;
    assign mw_in.result_src    = m1m2_out.result_src;
    assign mw_in.illegal_instr = m1m2_out.illegal_instr;
    
    mw_reg u_mw_reg(
        .clk(clk),
        .rst(rst),
        .d_in(mw_in),
        .d_out(mw_out)
    );

    //Writeback Stage:

    logic [XLEN-1:0] wb_data;
    logic reg_write_safe;

    mux4 #(.WIDTH(XLEN)) u_writeback_mux(
        .a(mw_out.alu_result),
        .b(mw_out.mem_rdata),
        .c(mw_out.pc_plus4),
        .d(mw_out.pc_target),
        .sel(mw_out.result_src),
        .result(wb_data)
    );

    assign reg_write_safe = mw_out.reg_write & ~mw_out.illegal_instr;

endmodule