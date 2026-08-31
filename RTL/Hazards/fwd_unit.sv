import riscv_pkg::*;

module fwd_unit(
    input logic [REG_ADDR_W-1:0] rs1E, rs2E,
    input logic [REG_ADDR_W-1:0] rdM1, rdM2, rdW,
    input logic reg_writeM1, reg_writeM2, reg_writeW,
    output fwdA_e fwdA,
    output fwdB_e fwdB
);

    always_comb begin
        fwdA = FWD_NONE_A;
        fwdB = FWD_NONE_B;

        if (((rs1E == rdM1) & reg_writeM1) & (rs1E != 0))
            fwdA = FWD_MEM1_A;
        else if (((rs1E == rdM2) & reg_writeM2) & (rs1E != 0))
            fwdA = FWD_MEM2_A;
        else if (((rs1E == rdW) & reg_writeW) & (rs1E != 0))
            fwdA = FWD_WB_A;
        else
            fwdA = FWD_NONE_A;

        if (((rs2E == rdM1) & reg_writeM1) & (rs2E != 0))
            fwdB = FWD_MEM1_B;
        else if (((rs2E == rdM2) & reg_writeM2) & (rs2E != 0))
            fwdB = FWD_MEM2_B;
        else if (((rs2E == rdW) & reg_writeW) & (rs2E != 0))
            fwdB = FWD_WB_B;
        else
            fwdB = FWD_NONE_B;
    end

endmodule