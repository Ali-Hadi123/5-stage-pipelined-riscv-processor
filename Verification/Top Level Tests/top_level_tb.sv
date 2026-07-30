import riscv_pkg::*;
`timescale 1ns/1ps

module top_tb;

  logic clk;
  logic rst;
  logic illegal_instr;

  //Counters:
  int unsigned total_tests = 0;
  int unsigned passed_tests = 0;
  
  top #(
    .ram_size(1024),
    .rom_size(27),
    .init_mem("arithmatic_test.hex")
  ) duv_arithmatic (
    .clk(clk),
    .rst(rst),
    .illegal_instr(illegal_instr)
  );

  always #5 clk = ~clk;

  task verify_register(
    input logic [XLEN-1:0] rn,
    input logic [XLEN-1:0] exp_rdata,
    input string test_name
  );

    total_tests++;
    assert (exp_rdata === duv_arithmatic.u_regf.regs[rn]) begin
      passed_tests++;
      $display("Passed %s!", test_name);
    end
    else
      $error("Failed %s!\nExpected: %0d\nGot: %0d", test_name, exp_rdata, duv_arithmatic.u_regf.regs[rn]);
  endtask

  initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars(0, top_tb);

    clk = 0;
    rst = 0;
    illegal_instr = 0;

    #10;

    $display("STARTING ARITHMATIC TESTING:\n");

    verify_register(32'd1, 32'd5, "Test 1");
    verify_register(32'd2, 32'd3, "Test 2");
    verify_register(32'd3, 32'd8, "Test 3");
    verify_register(32'd4, 32'd2, "Test 4");
    verify_register(32'd5, -32'd1, "Test 5");
    verify_register(32'd6, 32'd5, "Test 6");
    verify_register(32'd7, 32'd7, "Test 7");
    verify_register(32'd8, 32'd6, "Test 8");
    verify_register(32'd9, -32'd10, "Test 9");
