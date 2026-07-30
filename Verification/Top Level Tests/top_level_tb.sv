import riscv_pkg::*;
`timescale 1ns/1ps

module top_tb;

  logic clk;
  logic rst;
  logic illegal_instr;

  top #(
    .ram_size(1024),
    .rom_size(27),
    .init_mem("arithmatic_test.hex")
  ) duv_arithmatic (
    .clk(clk),
    .rst(rst),
    .illegal_instr(illegal_instr)
  );
