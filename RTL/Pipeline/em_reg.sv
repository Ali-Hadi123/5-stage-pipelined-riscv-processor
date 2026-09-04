import riscv_pkg::*;

module em_reg(
    input logic clk,
    input logic rst,
    input logic flush,
    input em_reg_t d_in,
    output em_reg_t d_out
);

    function automatic em_reg_t bubble();
        bubble.alu_result    = '0;
        bubble.write_data    = '0;
        bubble.pc_plus4      = '0;
        bubble.pc_target     = '0;
        
        bubble.rd_addr       = '0;
        
        bubble.result_src    = RESULT_ALU;
        bubble.mem_read      = 1'b0;
        bubble.mem_write     = 1'b0;
        bubble.mem_size      = MEM_WORD;
        bubble.mem_unsigned  = 1'b0;
        bubble.reg_write     = 1'b0;
        
        bubble.illegal_instr = 1'b0;
    endfunction

    always_ff @(posedge clk or posedge rst) begin
        if (rst || flush)
            d_out <= bubble();
        else
            d_out <= d_in;
    end

endmodule