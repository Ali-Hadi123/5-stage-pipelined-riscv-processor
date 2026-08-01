import riscv_pkg::*;
`timescale 1ns/1ps

module top_tb;

  logic clk;
  logic rst;
  logic illegal_instr;

  //Counters:
  int unsigned total_tests = 0;
  int unsigned passed_tests = 0;

  always #5 clk = ~clk;

  top #(
    .ram_size(1024),
    .rom_size(27),
    .init_mem("arithmatic_test.hex")
  ) duv_arithmatic (
    .clk(clk),
    .rst(rst),
    .illegal_instr(illegal_instr)
  );

  top #(
    .ram_size(1024),
    .rom_size(43),
    .init_mem("branch_test.hex")
  ) duv_branch (
    .clk(clk),
    .rst(rst),
    .illegal_instr(illegal_instr)
  );

  top #(
    .ram_size(1024),
    .rom_size(7),
    .init_mem("jump_test.hex")
  ) duv_jump (
    .clk(clk),
    .rst(rst),
    .illegal_instr(illegal_instr)
  );

  top #(
    .ram_size(1024),
    .rom_size(34),
    .init_mem("load_store_test.hex")
  ) duv_load_store (
    .clk(clk),
    .rst(rst),
    .illegal_instr(illegal_instr)
  );

  top #(
    .ram_size(1024),
    .rom_size(5),
    .init_mem("upper_immediate_test.hex")
  ) duv_upper_immediate (
    .clk(clk),
    .rst(rst),
    .illegal_instr(illegal_instr)
  );

  task verify_register(
    input logic [XLEN-1:0] regs [0:REG_COUNT-1],
    input logic [REG__ADDR_W-1:0] rn,
    input logic [XLEN-1:0] exp_rdata,
    input string test_name
  );

    @(posedge clk) begin
      total_tests++;
      assert (exp_rdata === regs[rn]) begin
        passed_tests++;
        $display("Passed %s!", test_name);
      end
      else
        $error("Failed %s!\nExpected: %0d\nGot: %0d", test_name, exp_rdata, regs[rn]);
    end
  endtask

  task verify_memory(
    input logic [XLEN-1:0] ram [0:1023], //ram_size - 1 = 1023
    input logic [XLEN-1:0] addr,
    input logic [XLEN-1:0] exp_rdata,
    input string test_name
  );

    @(posedge clk) begin
      total_tests++;
      assert (exp_rdata === ram[addr]) begin
        passed_tests++;
        $display("Passed %s!", test_name);
      end
      else
        $error("Failed %s!\nExpected: %0d\nGot: %0d", test_name, exp_rdata, ram[addr]);
    end
  endtask
  
  initial begin
    clk = 0;
    rst = 1;
    #10;
    rst = 0;

    #10;

    $display("STARTING ARITHMATIC TESTING:\n");

    verify_register(duv_arithmatic.u_regf.regs, 5'd1, 32'd5, "ARTH Test 1");
    verify_register(duv_arithmatic.u_regf.regs, 5'd2, 32'd3, "ARTH Test 2");
    verify_register(duv_arithmatic.u_regf.regs, 5'd3, 32'd8, "ARTH Test 3");
    verify_register(duv_arithmatic.u_regf.regs, 5'd4, 32'd2, "ARTH Test 4");
    verify_register(duv_arithmatic.u_regf.regs, 5'd5, -32'd1, "ARTH Test 5");
    verify_register(duv_arithmatic.u_regf.regs, 5'd6, 32'd5, "ARTH Test 6");
    verify_register(duv_arithmatic.u_regf.regs, 5'd7, 32'd7, "ARTH Test 7");
    verify_register(duv_arithmatic.u_regf.regs, 5'd8, 32'd6, "ARTH Test 8");
    verify_register(duv_arithmatic.u_regf.regs, 5'd9, -32'd10, "ARTH Test 9");
    verify_register(duv_arithmatic.u_regf.regs, 5'd10, 32'd1, "ARTH Test 10");
    verify_register(duv_arithmatic.u_regf.regs, 5'd11, 32'd0, "ARTH Test 11");
    verify_register(duv_arithmatic.u_regf.regs, 5'd12, 32'd0, "ARTH Test 12");
    verify_register(duv_arithmatic.u_regf.regs, 5'd13, 32'd1, "ARTH Test 13");
    verify_register(duv_arithmatic.u_regf.regs, 5'd14, 32'd1, "ARTH Test 14");
    verify_register(duv_arithmatic.u_regf.regs, 5'd15, 32'd16, "ARTH Test 15");
    verify_register(duv_arithmatic.u_regf.regs, 5'd16, 32'd32, "ARTH Test 16");
    verify_register(duv_arithmatic.u_regf.regs, 5'd17, 32'd8, "ARTH Test 17");
    verify_register(duv_arithmatic.u_regf.regs, 5'd18, -32'd8, "ARTH Test 18");
    verify_register(duv_arithmatic.u_regf.regs, 5'd19, -32'd4, "ARTH Test 19");
    verify_register(duv_arithmatic.u_regf.regs, 5'd20, 32'd8, "ARTH Test 20");
    verify_register(duv_arithmatic.u_regf.regs, 5'd21, 32'd4, "ARTH Test 21");
    verify_register(duv_arithmatic.u_regf.regs, 5'd22, -32'd1, "ARTH Test 22");
    verify_register(duv_arithmatic.u_regf.regs, 5'd23, 32'd1, "ARTH Test 23");
    verify_register(duv_arithmatic.u_regf.regs, 5'd24, 32'd7, "ARTH Test 24");
    verify_register(duv_arithmatic.u_regf.regs, 5'd25, 32'd0, "ARTH Test 25");
    verify_register(duv_arithmatic.u_regf.regs, 5'd26, 32'd1, "ARTH Test 26");
    verify_register(duv_arithmatic.u_regf.regs, 5'd27, 32'd0, "ARTH Test 27");

    int unsigned total_tests_arth = total_tests;
    int unsigned passed_tests_arth = passed_tests;
    
    $display("\nTESTING COMPLETED\nResults: %0d/%0d tests passed.", passed_tests_arth, total_tests_arth);
    $display("\nARITHMATIC TESTING COMPLETED.\n");

    $display("STARTING BRANCH TESTING:\n");

    assert (duv_branch.u_regf.regs[5'd3] === 37) begin
      $display("\nTESTING COMPLETED\nResults: 7/7 tests passed.");
      $display("\nBRANCH TESTING COMPLETED.\n");
    end
    else begin
      
