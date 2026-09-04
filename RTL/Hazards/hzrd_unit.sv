import riscv_pkg::*;

module hzrd_unit(
    input logic mem_readE,
    input logic [REG_ADDR_W-1:0] rs1D, rs2D,
    input logic [REG_ADDR_W-1:0] rdE,
    input pc_src_e pc_srcM,
    output logic stallF, stallD,
    output logic flushD, flushE, flushM 
);

    logic lw_stall;
    logic branch_mispredict;

    always_comb begin
        lw_stall = ((mem_readE & ((rdE == rs1D) | (rdE == rs2D))) & (rdE != 0));
        branch_mispredict = (pc_srcM != PC_PLUS4);

        stallF = lw_stall;
        stallD = lw_stall;

        flushD = branch_mispredict;
        flushE = lw_stall | branch_mispredict;
        flushM = branch_mispredict;
    end

endmodule