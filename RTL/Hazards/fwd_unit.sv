import riscv_pkg::*;

module fwd_unit(
    input logic [REG_ADDR_WIDTH-1:0] rs1E, rs2E,
    input logic [REG_ADDR_WIDTH-1:0] rdM,
    input logic reg_writeM,
    output fwdA_e fwdA,
    output fwdB_e fwdB
);

    always_comb begin
        fwdA_e = FWD_NONE_A;
        fwdB_e = FWD_NONE_B;

        