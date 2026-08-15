import riscv_pkg::*;

module mw_reg(
    input logic clk,
    input logic rst,
    input mw_reg_t d_in,
    output mw_reg_t d_out
);

    function automatic mw_reg_t bubble();
        bubble.mem_rdata     = '0;
        bubble.alu_result    = '0;
        bubble.pc_plus4      = '0;
        bubble.pc_target     = '0;
    
        bubble.rd_addr       = '0;
    
        bubble.reg_write     = 1'b0;
        bubble.result_src    = RESULT_ALU;
    
        bubble.illegal_instr = 1'b0;
    endfunction

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            d_out <= bubble();
        else
            d_out <= d_in;
    end

endmodule