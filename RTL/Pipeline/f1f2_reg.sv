import riscv_pkg::*;

module f1f2_reg(
    input logic clk,
    input logic rst,
    input logic stall,
    input f1f2_reg_t d_in,
    output f1f2_reg_t d_out,
);

    function automatic f1f2_reg_t bubble();
        bubble.pc       = '0;
        bubble.pc_plus4 = '0;
    endfunction

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            d_out <= bubble();
        else if (~stall)
            d_out <= d_in;
    end

endmodule