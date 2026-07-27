import riscv_pkg::*;
`timescale 1ns/1ps

module dmem_tb;
  logic clk;
  logic [XLEN-1:0] tb_byte_addr;
  logic [XLEN-1:0] tb_wdata;
  logic mem_read, mem_write;
  mem_size_e mem_size, 
  logic mem_unsigned,
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
    input mem_size_e size, 
    input logic is_unsigned
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

  task read_data(
    input logic [XLEN-1:0] addr,
    input mem_size_e size,
    input logic is_unsigned
  );

    @(negedge clk);
    mem_read = 1'b1;
    mem_write = 1'b0;

    tb_byte_addr = addr;
    mem_size = size;
    mem_unsigned = is_unsigned;

    @(negedge clk);
    mem_read = 1'b0;
  endtask

  initial begin
    $dumpfile("data_mem_tb.vcd");
    $dumpvars(0, dmem_tb);

    clk = 0;
    tb_byte_addr = 0;
    tb_wdata = 0;
    mem_read = 0;
    mem_write = 0;
    mem_size = MEM_BYTE;
    mem_unsigned = 0;
    tb_read_data = 0;

    $display("STARTING DATA MEMORY TESTING:");

    write_data(32'd0, 32'd12345, MEM_WORD, 1'b1);  //Testing writing a word to dmem at address 0x0.
    read_data(32'd0, MEM_WORD, 1'b1);
    total_tests++;

    #10;

    assert(tb_read_data === 32'd12345) begin
      passed_tests++;
      $display("Test 1 Passed.");
    end
    else
      $error("TEST 1 Failed:\nExpected: 32'd12345\n Got: %0d", tb_read_data);
