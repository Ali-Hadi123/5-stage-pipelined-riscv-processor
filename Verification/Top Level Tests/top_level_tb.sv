import riscv_pkg::*;
`timescale 1ns/1ps

module top_tb;

  logic clk;
  logic rst;
  logic illegal_instr_arth, illegal_instr_branch, illegal_instr_jump, illegal_instr_load_store, illegal_instr_upper_immediate;

  //Counters:
  int unsigned total_tests = 0;
  int unsigned passed_tests = 0;
  int unsigned total_tests_arth, passed_tests_arth;
  int unsigned total_tests_branch, passed_tests_branch;
  int unsigned total_tests_jump, passed_tests_jump;
  int unsigned total_tests_load_store, passed_tests_load_store;
  int unsigned total_tests_upper_immediate, passed_tests_upper_immediate;

  always #5 clk = ~clk;

  top #(
    .ram_size(1024),
    .rom_size(27),
    .init_mem("Assembly Programs/arithmatic_test.hex")
  ) duv_arithmatic (
    .clk(clk),
    .rst(rst),
    .illegal_instr(illegal_instr_arth)
  );

  top #(
    .ram_size(1024),
    .rom_size(43),
    .init_mem("Assembly Programs/branch_test.hex")
  ) duv_branch (
    .clk(clk),
    .rst(rst),
    .illegal_instr(illegal_instr_branch)
  );

  top #(
    .ram_size(1024),
    .rom_size(7),
    .init_mem("Assembly Programs/jump_test.hex")
  ) duv_jump (
    .clk(clk),
    .rst(rst),
    .illegal_instr(illegal_instr_jump)
  );

  top #(
    .ram_size(1024),
    .rom_size(34),
    .init_mem("Assembly Programs/load_store_test.hex")
  ) duv_load_store (
    .clk(clk),
    .rst(rst),
    .illegal_instr(illegal_instr_load_store)
  );

  top #(
    .ram_size(1024),
    .rom_size(5),
    .init_mem("Assembly Programs/upper_immediate_test.hex")
  ) duv_upper_immediate (
    .clk(clk),
    .rst(rst),
    .illegal_instr(illegal_instr_upper_immediate)
  );

  task verify_register(
    input logic [XLEN-1:0] rdata,
    input logic [XLEN-1:0] exp_rdata,
    input string test_name
  );

    @(posedge clk) begin
      #1;
      total_tests++;
      assert (exp_rdata === rdata) begin
        passed_tests++;
        $display("Passed %s!", test_name);
      end
      else
        $error("Failed %s!\nExpected: %0d\nGot: %0d", test_name, exp_rdata, rdata);
    end
  endtask

  task verify_memory(
    input logic [XLEN-1:0] rdata,
    input logic [XLEN-1:0] exp_rdata,
    input string test_name
  );
 
    @(posedge clk) begin
      #1;
      total_tests++;
      assert (exp_rdata === rdata) begin
        passed_tests++;
        $display("Passed %s!", test_name);
      end
      else
        $error("Failed %s!\nExpected: %0d\nGot: %0d", test_name, exp_rdata, rdata);
    end
  endtask
  
  initial begin
    clk = 0;
    rst = 1;
    #10;
    rst = 0;

    #10;

    repeat (600) @(posedge clk);
    #1;

    $display("STARTING ARITHMATIC TESTING:\n");

    verify_register(duv_arithmatic.u_regf.regs[5'd1], 32'd5, "ARTH Test 1");
    verify_register(duv_arithmatic.u_regf.regs[5'd2], 32'd3, "ARTH Test 2");
    verify_register(duv_arithmatic.u_regf.regs[5'd3], 32'd8, "ARTH Test 3");
    verify_register(duv_arithmatic.u_regf.regs[5'd4], 32'd2, "ARTH Test 4");
    verify_register(duv_arithmatic.u_regf.regs[5'd5], -32'd1, "ARTH Test 5");
    verify_register(duv_arithmatic.u_regf.regs[5'd6], 32'd5, "ARTH Test 6");
    verify_register(duv_arithmatic.u_regf.regs[5'd7], 32'd7, "ARTH Test 7");
    verify_register(duv_arithmatic.u_regf.regs[5'd8], 32'd6, "ARTH Test 8");
    verify_register(duv_arithmatic.u_regf.regs[5'd9], -32'd10, "ARTH Test 9");
    verify_register(duv_arithmatic.u_regf.regs[5'd10], 32'd1, "ARTH Test 10");
    verify_register(duv_arithmatic.u_regf.regs[5'd11], 32'd0, "ARTH Test 11");
    verify_register(duv_arithmatic.u_regf.regs[5'd12], 32'd0, "ARTH Test 12");
    verify_register(duv_arithmatic.u_regf.regs[5'd13], 32'd1, "ARTH Test 13");
    verify_register(duv_arithmatic.u_regf.regs[5'd14], 32'd1, "ARTH Test 14");
    verify_register(duv_arithmatic.u_regf.regs[5'd15], 32'd16, "ARTH Test 15");
    verify_register(duv_arithmatic.u_regf.regs[5'd16], 32'd32, "ARTH Test 16");
    verify_register(duv_arithmatic.u_regf.regs[5'd17], 32'd8, "ARTH Test 17");
    verify_register(duv_arithmatic.u_regf.regs[5'd18], -32'd8, "ARTH Test 18");
    verify_register(duv_arithmatic.u_regf.regs[5'd19], -32'd4, "ARTH Test 19");
    verify_register(duv_arithmatic.u_regf.regs[5'd20], 32'd8, "ARTH Test 20");
    verify_register(duv_arithmatic.u_regf.regs[5'd21], 32'd4, "ARTH Test 21");
    verify_register(duv_arithmatic.u_regf.regs[5'd22], -32'd1, "ARTH Test 22");
    verify_register(duv_arithmatic.u_regf.regs[5'd23], 32'd1, "ARTH Test 23");
    verify_register(duv_arithmatic.u_regf.regs[5'd24], 32'd7, "ARTH Test 24");
    verify_register(duv_arithmatic.u_regf.regs[5'd25], 32'd0, "ARTH Test 25");
    verify_register(duv_arithmatic.u_regf.regs[5'd26], 32'd1, "ARTH Test 26");
    verify_register(duv_arithmatic.u_regf.regs[5'd27], 32'd0, "ARTH Test 27");


    total_tests_arth = total_tests;
    passed_tests_arth = passed_tests;
    
    $display("\nTESTING COMPLETED\nResults: %0d/%0d tests passed.", passed_tests_arth, total_tests_arth);
    $display("\nARITHMATIC TESTING COMPLETED.\n");

    repeat (600) @(posedge clk);
    #1;
    
    $display("STARTING BRANCH TESTING:\n");

    total_tests_branch = 7;
    
    assert (~(duv_branch.u_regf.regs[5'd3] === 37)) begin
      verify_register(duv_branch.u_regf.regs[5'd31], 32'd1, "TEST BEQ TAKEN");
      verify_register(duv_branch.u_regf.regs[5'd30], 32'd1, "TEST BNE");
      verify_register(duv_branch.u_regf.regs[5'd29], 32'd1, "TEST BEQ NOT TAKEN");
      verify_register(duv_branch.u_regf.regs[5'd28], 32'd1, "TEST BLT");
      verify_register(duv_branch.u_regf.regs[5'd27], 32'd1, "TEST BLTU");
      verify_register(duv_branch.u_regf.regs[5'd26], 32'd1, "TEST BGE");
      verify_register(duv_branch.u_regf.regs[5'd25], 32'd1, "TEST BGEU");

      passed_tests_branch = passed_tests - passed_tests_arth;
    end
    else begin
      passed_tests_branch = 7;
      passed_tests = passed_tests + 7;
      total_tests = total_tests + 7;
    end

    $display("\nTESTING COMPLETED\nResults: %0d/%0d tests passed.", passed_tests_branch, total_tests_branch);
    $display("\nBRANCH TESTING COMPLETED.\n");

    repeat (600) @(posedge clk);
    #1;
    
    $display("STARTING JUMP TESTING:\n");

    total_tests_jump = 1;

    assert (~(duv_jump.u_regf.regs[5'd1] === 1101)) begin
      verify_register(duv_jump.u_regf.regs[5'd10], 32'd8, "TEST JAL");

      passed_tests_jump = passed_tests - (passed_tests_arth + passed_tests_branch);
    end
    else begin
      passed_tests_jump = 1;
      passed_tests++;
      total_tests++;
    end

    $display("\nTESTING COMPLETED\nResults: %0d/%0d tests passed.", passed_tests_jump, total_tests_jump);
    $display("\nJUMP TESTING COMPLETED.\n");
    
    repeat (600) @(posedge clk);
    #1;
    
    $display("STARTING LOAD/STORE TESTING:\n");

    total_tests_load_store = 22;

    verify_memory(duv_load_store.u_dmem.ram[32'd0], -32'd1, "TEST SW");
    verify_register(duv_load_store.u_regf.regs[5'd3], -32'd1, "TEST LW");
    verify_memory({24'b0, duv_load_store.u_dmem.ram[32'd1][7:0]}, 32'h0000_007A, "TEST SB, +ve");
    verify_register(duv_load_store.u_regf.regs[5'd5], 32'd122, "TEST LB, +ve");
    verify_register(duv_load_store.u_regf.regs[5'd6], 32'd122, "TEST LBU, +ve");
    verify_memory({24'b0, duv_load_store.u_dmem.ram[32'd2][7:0]}, 32'h0000_00FE, "TEST SB, -ve");
    verify_register(duv_load_store.u_regf.regs[5'd8], -32'd2, "TEST LB, -ve");
    verify_register(duv_load_store.u_regf.regs[5'd9], 32'd254, "TEST LBU, -ve");
    verify_memory({16'b0, duv_load_store.u_dmem.ram[32'd3][15:0]}, 32'h0000_03FF, "TEST SH, +ve");
    verify_register(duv_load_store.u_regf.regs[5'd11], 32'd1023, "TEST LH, +ve");
    verify_register(duv_load_store.u_regf.regs[5'd12], 32'd1023, "TEST LHU, +ve");
    verify_memory({16'b0, duv_load_store.u_dmem.ram[32'd4][15:0]}, 32'h0000_FF9C, "TEST SH, -ve");
    verify_register(duv_load_store.u_regf.regs[5'd14], -32'd100, "TEST LH, -ve");
    verify_register(duv_load_store.u_regf.regs[5'd15], 32'd65436, "TEST LHU, -ve");
    verify_memory({24'b0, duv_load_store.u_dmem.ram[32'd5][7:0]},   32'h0000_0011, "TEST SB, byte offset = 0");
    verify_memory({24'b0, duv_load_store.u_dmem.ram[32'd5][15:8]},  32'h0000_0022, "TEST SB, byte offset = 1");
    verify_memory({24'b0, duv_load_store.u_dmem.ram[32'd5][23:16]}, 32'h0000_0033, "TEST SB, byte offset = 2");
    verify_memory({24'b0, duv_load_store.u_dmem.ram[32'd5][31:24]}, 32'h0000_0044, "TEST SB, byte offset = 3");
    verify_register(duv_load_store.u_regf.regs[5'd20], 32'h4433_2211, "TEST LW from offset bytes");
    verify_memory({16'b0, duv_load_store.u_dmem.ram[32'd6][15:0]},  32'h0000_00AB, "TEST SH, half offset = 0");
    verify_memory({16'b0, duv_load_store.u_dmem.ram[32'd6][31:16]}, 32'h0000_00CD, "TEST SH, half offset = 1");
    verify_register(duv_load_store.u_regf.regs[5'd23], 32'h00CD_00AB, "TEST LW from offset halfs");

    passed_tests_load_store = passed_tests - (passed_tests_arth + passed_tests_branch + passed_tests_jump);

    $display("\nTESTING COMPLETED\nResults: %0d/%0d tests passed.", passed_tests_load_store, total_tests_load_store);
    $display("\nLOAD/STORE TESTING COMPLETED.\n");

    repeat (600) @(posedge clk);
    #1;

    $display("STARTING UPPER IMMEDIATE TESTING:\n");

    total_tests_upper_immediate = 4;

    verify_register(duv_upper_immediate.u_regf.regs[5'd1], 32'h00000000, "TEST AUIPC AT 0");
    verify_register(duv_upper_immediate.u_regf.regs[5'd2], 32'h00001004, "TEST AUIPC");
    verify_register(duv_upper_immediate.u_regf.regs[5'd3], 32'h12345000, "TEST LUI, +ve");
    verify_register(duv_upper_immediate.u_regf.regs[5'd5], 32'hFFFFF001, "TEST LUI, -ve");

    passed_tests_upper_immediate = passed_tests - (passed_tests_arth + passed_tests_branch + passed_tests_jump + passed_tests_load_store);

    $display("\nTESTING COMPLETED\nResults: %0d/%0d tests passed.", passed_tests_upper_immediate, total_tests_upper_immediate);
    $display("\nUPPER IMMEDIATE TESTING COMPLETED.\n");

    $display("ALL TESTING IS DONE!");
    $display("RESULTS: %0d/%0d tests passed!", passed_tests, total_tests);
    $finish;
  end
endmodule
