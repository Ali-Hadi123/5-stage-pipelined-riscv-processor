import riscv_pkg::*;

module fd_reg(
    input logic clk,
    input logic rst,
    input logic stall,          //en  - 1: capture 'd' on this clock edge. 0: hold current contents (stall).
    input logic flush,          //clr - 1: synchronously clear to a bubble (flush). Takes priority over en.
    input fd_reg_t d_in,
    output fd_reg_t d_out
);

  function automatic fd_reg_t bubble();
    bubble.instr    = 32'h0000_0013;     //NOP machine code.
    bubble.pc       = '0;
    bubble.pc_plus4 = '0;
  endfunction

  always_ff @(posedge clk or posedge rst) begin
    if (rst | flush)
        d_out <= bubble();
    else if (~stall)
        d_out <= d_in;
  end

endmodule