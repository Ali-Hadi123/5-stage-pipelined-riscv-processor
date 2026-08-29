import riscv_pkg::*;

module regf (
  input logic clk,
  input logic [REG_ADDR_W-1:0] rs1, rs2, rd,
  input logic [XLEN-1:0] wd,
  input logic reg_write,
  output logic [XLEN-1:0] rdata1, rdata2
);

  logic [XLEN-1:0] regs [0:REG_COUNT-1];

  integer i;
  initial begin
    for (i = 0; i < REG_COUNT; i++)
      regs[i] = '0;
  end

  assign rdata1 = (reg_write & rd == rs1 & rd != 0) ? wd : (rs1 == 0 ? 0 : regs[rs1]);
  assign rdata2 = (reg_write & rd == rs2 & rd != 0) ? wd : (rs2 == 0 ? 0 : regs[rs2]);

  always_ff @(posedge clk)
    if (reg_write & rd != 0)
      regs[rd] <= wd;
endmodule