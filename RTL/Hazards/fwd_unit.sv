import riscv_pkg::*;

module fwd_unit(
    input logic [REG_ADDR_W-1:0] rs1E, rs2E,
    input logic [REG_ADDR_W-1:0] rdM, rdW,
    input logic reg_writeM, reg_writeW,
    output fwdA_e fwdA,
    output fwdB_e fwdB
);

    always_comb begin
        fwdA_e = FWD_NONE_A;
        fwdB_e = FWD_NONE_B;

        if (((rs1E == rdM) & reg_writeM) & (rs1E != 0))
            fwdA_e = FWD_MEM_A;
        else if (((rs1E == rdW) & reg_writeW) & (rs1E != 0))
            fwdA_e = FWD_WB_A;
        else
            fwdA_e = FWD_NONE_A;

        if (((rs2E == rdM) & reg_writeM) & (rs2E != 0))
            fwdB_e = FWD_MEM_B;
        else if (((rs2E == rdW) & reg_writeW) & (rs2E != 0))
            fwdB_e = FWD_WB_B;
        else
            fwdB_e = FWD_NONE_B;
    end

endmodule