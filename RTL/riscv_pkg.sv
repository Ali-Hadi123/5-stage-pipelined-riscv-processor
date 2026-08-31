package riscv_pkg;

  parameter int XLEN       = 32;                  
  parameter int REG_COUNT  = 32;
  parameter int REG_ADDR_W = $clog2(REG_COUNT);
  parameter int ILEN       = 32;

  typedef enum logic [6:0] {    //Possible OP codes (instr[6:0]).
    OP_LOAD     = 7'b0000011,
    OP_STORE    = 7'b0100011,
    OP_BRANCH   = 7'b1100011,
    OP_JALR     = 7'b1100111,
    OP_JAL      = 7'b1101111,
    OP_ARTH_IMM = 7'b0010011,
    OP_ARTH_REG = 7'b0110011,
    OP_AUIPC    = 7'b0010111,
    OP_LUI      = 7'b0110111,
    OP_SYSTEM   = 7'b1110011,
    OP_FENCE    = 7'b0001111
  } opcode_e;

  typedef enum logic [2:0] {  //Possible funct3 values for branch instructions.
    F3_BEQ  = 3'b000,
    F3_BNE  = 3'b001,
    F3_BLT  = 3'b100,
    F3_BGE  = 3'b101,
    F3_BLTU = 3'b110,
    F3_BGEU = 3'b111
  } funct3_branch_e;

  typedef enum logic [2:0] {  //Possible funct3 values for load instructions.
    F3_LB  = 3'b000,
    F3_LH  = 3'b001,
    F3_LW  = 3'b010,
    F3_LBU = 3'b100,
    F3_LHU = 3'b101
  } funct3_load_e;

  typedef enum logic [2:0] {  //Possible funct3 values for store instructions.
    F3_SB = 3'b000,
    F3_SH = 3'b001,
    F3_SW = 3'b010
  } funct3_store_e;

  typedef enum logic [2:0] {  //Possible funct3 values for arithmatic.
    F3_ADD_SUB = 3'b000,
    F3_SLL     = 3'b001,
    F3_SLT     = 3'b010,
    F3_SLTU    = 3'b011,
    F3_XOR     = 3'b100,
    F3_SRL_SRA = 3'b101,
    F3_OR      = 3'b110,
    F3_AND     = 3'b111
  } funct3_arth_e;

  typedef enum logic [6:0] { //Distinguishes SUB from ADD and SRA from SRL based on funct7 value.
    F7_NORMAL = 7'b0000000,
    F7_ALT    = 7'b0100000   
  } funct7_e;

  //SystemVerilog automatically assigns interger values starting from 0 and counting upwards for enums that don't have explicit
  //values. Since the values of the enums below don't correspond to specefic bits of machine instructions, their values don't matter
  //and it's ok to let SystemVerilog assign the default values.
  
  typedef enum logic [2:0] {
    FMT_R,                    
    FMT_I,
    FMT_S,
    FMT_B,
    FMT_U,
    FMT_J
  } instr_fmt_e;

  typedef enum logic [2:0] {
    ALUOP_ADD,
    ALUOP_BRANCH,
    ALUOP_FUNCT,
    ALUOP_PASS_B
} alu_op_e;
  
  typedef enum logic [3:0] { 
    ALU_ADD,
    ALU_SUB,
    ALU_SLL,
    ALU_SLT,
    ALU_SLTU,
    ALU_XOR,
    ALU_SRL,
    ALU_SRA,
    ALU_OR,
    ALU_AND,
    ALU_PASS_B
  } alu_ctrl_e;

  typedef enum logic [1:0] {
    RESULT_ALU,     
    RESULT_MEM,
    RESULT_PCPLUS4,
    RESULT_PCTARGET
} result_src_e;

  typedef enum logic [1:0] {
    PC_PLUS4,
    PC_TARGET,
    PC_RESULT
  } pc_src_e;

  typedef enum logic {
    ALU_SRC_RD2,
    ALU_SRC_IMM
  } alu_src_e;

  typedef enum logic [1:0] {
    MEM_BYTE,
    MEM_HALF,
    MEM_WORD
  } mem_size_e;

  typedef enum logic [1:0] {
    FWD_NONE_A,
    FWD_WB_A,
    FWD_MEM_A
  } fwdA_e;

  typedef enum logic [1:0] {
    FWD_NONE_B,
    FWD_WB_B,
    FWD_MEM_B
  } fwdB_e;

  //Instruction field extraction helpers.
  
  function automatic logic [6:0] get_opcode(input logic [ILEN-1:0] instr);
    return instr[6:0];
  endfunction

  function automatic logic [4:0] get_rd(input logic [ILEN-1:0] instr);
    return instr[11:7];
  endfunction

  function automatic logic [4:0] get_rs1(input logic [ILEN-1:0] instr);
    return instr[19:15];
  endfunction

  function automatic logic [4:0] get_rs2(input logic [ILEN-1:0] instr);
    return instr[24:20];
  endfunction

  function automatic logic [2:0] get_funct3(input logic [ILEN-1:0] instr);
    return instr[14:12];
  endfunction

  function automatic logic [6:0] get_funct7(input logic [ILEN-1:0] instr);
    return instr[31:25];
  endfunction

  function automatic instr_fmt_e get_fmt(input logic [6:0] opcode);
    unique case (opcode)
      OP_ARTH_REG:        get_fmt = FMT_R;
      OP_ARTH_IMM,
      OP_LOAD,
      OP_JALR,
      OP_SYSTEM,
      OP_FENCE:            get_fmt = FMT_I;
      OP_STORE:            get_fmt = FMT_S;
      OP_BRANCH:           get_fmt = FMT_B;
      OP_LUI,
      OP_AUIPC:            get_fmt = FMT_U;
      OP_JAL:              get_fmt = FMT_J;
      default:             get_fmt = FMT_I;
    endcase
  endfunction

  //Structs for pipelined registers.

  typedef struct packed {
    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] pc_plus4;
  } f1f2_reg_t;

  typedef struct packed {
    logic [XLEN-1:0] instr;
    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] pc_plus4;
  } fd_reg_t;

  typedef struct packed {
    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] pc_plus4;
    logic [XLEN-1:0] rdata1;
    logic [XLEN-1:0] rdata2;
    logic [XLEN-1:0] imm_out;
    logic [2:0] funct3;

    logic [REG_ADDR_W-1:0] rs1_addr;
    logic [REG_ADDR_W-1:0] rs2_addr;
    logic [REG_ADDR_W-1:0] rd_addr;
    
    alu_src_e alu_src;
    logic mem_read;
    logic mem_write;
    result_src_e result_src;
    logic is_branch;
    logic is_jal;
    logic is_jalr;
    logic reg_write;
    alu_ctrl_e alu_ctrl;
    mem_size_e mem_size;
    logic mem_unsigned;

    logic illegal_instr_main;
    logic illegal_instr_mem;
    logic illegal_instr_alu;
  } de_reg_t;

  typedef struct packed {
    logic [XLEN-1:0] alu_result;
    logic [XLEN-1:0] write_data;
    logic [XLEN-1:0] pc_plus4;
    logic [XLEN-1:0] pc_target;

    logic [REG_ADDR_W-1:0] rd_addr;

    result_src_e result_src;
    logic mem_read;
    logic mem_write;
    mem_size_e mem_size;
    logic mem_unsigned;
    logic reg_write;

    logic illegal_instr;
  } em_reg_t;

  typedef struct packed {
    logic [XLEN-1:0] alu_result;
    logic [REG_ADDR_W-1:0] rd_addr;
    logic [XLEN-1:0] pc_target;
    logic [XLEN-1:0] pc_plus4;

    result_src_e result_src;
    logic reg_write;

    logic illegal_instr;
  } m1m2_reg_t;

  typedef struct packed {
    logic [XLEN-1:0] mem_rdata;
    logic [XLEN-1:0] alu_result;
    logic [XLEN-1:0] pc_plus4;
    logic [XLEN-1:0] pc_target;

    logic [REG_ADDR_W-1:0] rd_addr;

    logic reg_write;
    result_src_e result_src;

    logic illegal_instr;
  } mw_reg_t;

endpackage