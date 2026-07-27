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
  int unsigned passed_tests = 0;

  dmem #(.ram_size(1024)) duv (
    .clk(clk),
    .byte_addr(tb_byte_addr),
    .wdata(tb_wdata),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_size(mem_size),
    .mem_unsigned(mem_unsigned),
    .read_data(tb_read_data)
  );

  always #5 clk = ~clk;

  task write_data(
    input logic [XLEN-1:0] addr,
    input logic [XLEN-1:0] data,
    input logic size, is_unsigned
  );

    @(negedge clk);
    mem_read = 1'b0;
    mem_write = 1'b1;

    tb_byte_addr = addr;
    tb_wdata = data;
    mem_size = size;
    mem_unsigned = is_unsigned;

    @(negedge clk);
    mem_write = 1'b0;
  endtask
