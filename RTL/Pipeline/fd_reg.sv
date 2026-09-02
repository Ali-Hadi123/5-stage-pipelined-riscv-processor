import riscv_pkg::*;

module fd_reg(
    input logic clk,
    input logic rst,
    input logic stall,       
    input logic flush,         
    input fd_reg_t d_in,
    output fd_reg_t d_out
);

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      d_out.instr    <= 32'h0000_0013;
      d_out.pc       <= '0;
      d_out.pc_plus4 <= '0;
    end
    else begin
      if (~stall) begin
          d_out.pc       <= d_in.pc;
          d_out.pc_plus4 <= d_in.pc_plus4;
      end

      if (flush)
        d_out.instr <= 32'h0000_0013;
      else if (~stall)
        d_out.instr <= d_in.instr;
    end
  end

endmodule