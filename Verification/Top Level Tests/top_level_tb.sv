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

    @(posedge clk) begin
      total_tests++;
      assert (exp_rdata === duv_arithmatic.u_regf.regs[rn]) begin
        passed_tests++;
        $display("Passed %s!", test_name);
      end
      else
        $error("Failed %s!\nExpected: %0d\nGot: %0d", test_name, exp_rdata, duv_arithmatic.u_regf.regs[rn]);
    end
  endtask

  initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars(0, top_tb);

    clk = 0;
    rst = 1;
    #10;
    rst = 0;

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
    verify_register(32'd10, 32'd1, "Test 10");
    verify_register(32'd11, 32'd0, "Test 11");
    verify_register(32'd12, 32'd0, "Test 12");
    verify_register(32'd13, 32'd1, "Test 13");
    verify_register(32'd14, 32'd1, "Test 14");
    verify_register(32'd15, 32'd16, "Test 15");
    verify_register(32'd16, 32'd32, "Test 16");
    verify_register(32'd17, 32'd8, "Test 17");
    verify_register(32'd18, -32'd8, "Test 18");
    verify_register(32'd19, -32'd4, "Test 19");
    verify_register(32'd20, 32'd8, "Test 20");
    verify_register(32'd21, 32'd4, "Test 21");
    verify_register(32'd22, -32'd1, "Test 22");
    verify_register(32'd23, 32'd1, "Test 23");
    verify_register(32'd24, 32'd7, "Test 24");
    verify_register(32'd25, 32'd0, "Test 25");
    verify_register(32'd26, 32'd1, "Test 26");
    verify_register(32'd27, 32'd0, "Test 27");

    $display("\nTESTING COMPLETED\nResults: %0d/%0d tests passed.", passed_tests, total_tests);
    $display("\nARITHMATIC TESTING COMPLETED.\n");
    $finish;
  end
endmodule
