import riscv_pkg::*;

module m1m2_reg(
    input logic clk,
    input logic rst,
    input m1m2_reg_t d_in,
    output m1m2_reg_t d_out
);

    function automatic m1m2_reg_t bubble();
        bubble.alu_result    = '0;
        bubble.rd_addr       = '0;
        bubble.pc_target     = '0;
        bubble.pc_plus4      = '0;
        bubble.result_src    = '0;
        bubble.reg_write     = '0;
        bubble.illegal_instr = '0;
    endfunction

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            d_out <= bubble();
        else
            d_out <= d_in;
    end

endmodule