import riscv_pkg::*;

module de_reg(
    input logic clk,
    input logic rst,
    input logic flush,
    input de_reg_t d_in,
    output de_reg_t d_out
);

  always_ff @(posedge clk or posedge rst) begin
    d_out <= d_in;
    
    if (rst | flush) begin
      d_out.mem_read            <= 1'b0;
      d_out.mem_write           <= 1'b0;
      d_out.reg_write           <= 1'b0;
      d_out.illegal_instr_main  <= 1'b0;
      d_out.illegal_instr_mem   <= 1'b0;
      d_out.illegal_instr_alu   <= 1'b0;
    end
  end
  
endmodule