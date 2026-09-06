import riscv_pkg::*;

module hzrd_unit(
    input logic clk,
    input logic rst,
    input logic mem_readE,
    input logic [REG_ADDR_W-1:0] rs1D, rs2D,
    input logic [REG_ADDR_W-1:0] rdE,
    input logic is_branchD, is_jalrD,
    input pc_src_e pc_srcM,
    output logic stallF, stallD,
    output logic flushD, flushE, flushM 
);

    logic lw_stall;
    logic branch_mispredict, branch_mispredict_q;
    logic extra_stall_d, extra_stall_q;

    always_comb begin
        lw_stall = ((mem_readE & ((rdE == rs1D) | (rdE == rs2D))) & (rdE != 0));
        branch_mispredict = (pc_srcM != PC_PLUS4);
        
        extra_stall_d = lw_stall & (is_branchD | is_jalrD);

        stallF = lw_stall | extra_stall_q;
        stallD = lw_stall | extra_stall_q;

        flushD = branch_mispredict | branch_mispredict_q;
        flushE = lw_stall | branch_mispredict | branch_mispredict_q | extra_stall_q;
        flushM = branch_mispredict;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            extra_stall_q <= 1'b0;
            branch_mispredict_q <= 1'b0;
        end
        else begin
            extra_stall_q <= extra_stall_d;
            branch_mispredict_q <= branch_mispredict;
        end
    end

endmodule