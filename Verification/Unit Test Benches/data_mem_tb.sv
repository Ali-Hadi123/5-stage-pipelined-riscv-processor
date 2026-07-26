import riscv_pkg::*;
`timescale 1ns/1ps

module dmem_tb;
  logic clk;
  logic [XLEN-1:0] tb_byte_addr;
  logic [XLEN-1:0] tb_wdata;
  logic mem_read, mem_write;
  logic mem_size, mem_unsigned;
  logic [XLEN-1:0] tb_read_data;

  int unsigned total_tests = 0;
