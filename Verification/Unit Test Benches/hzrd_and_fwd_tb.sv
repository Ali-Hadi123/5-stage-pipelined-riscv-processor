import riscv_pkg::*;
`timescale 1ns/1ps

module hazard_tb;
  logic [REG_ADDR_W-1:0] fwd_rs1E, fwd_rs2E, fwd_rdM1, fwd_rdM2, fwd_rdW;
  logic fwd_reg_writeM1, fwd_reg_writeM2, fwd_reg_writeW;
  fwdA_e fwd_fwdA;
  fwdB_e fwd_fwdB;

  //Counters:
  int unsigned total_tests = 0;
  int unsigned passed_tests = 0;


  fwd_unit duv_fwd(
    .rs1E(fwd_rs1E),
    .rs2E(fwd_rs2E),
    .rdM1(fwd_rdM1),
    .rdM2(fwd_rdM2),
    .rdW(fwd_rdW),
    .reg_writeM1(fwd_reg_writeM1),
    .reg_writeM2(fwd_reg_writeM2),
    .reg_writeW(fwd_reg_writeW),
    .fwdA(fwd_fwdA),
    .fwdB(fwd_fwdB)
  );

  task verify_fwd(
    input logic [REG_ADDR_W-1:0] rs1E, rs2E, rdM1, rdM2, rdW,
    input logic reg_writeM1, reg_writeM2, reg_writeW,
    input fwdA_e exp_fwdA,
    input fwdB_e exp_fwdB,
    input string test_name
  );

    fwd_rs1E = rs1E;
    fwd_rs2E = rs2E;
    fwd_rdM1 = rdM1;
    fwd_rdM2 = rdM2;
    fwd_rdW = rdW;
    fwd_reg_writeM1 = reg_writeM1;
    fwd_reg_writeM2 = reg_writeM2;
    fwd_reg_writeW = reg_writeW;

    #10;

    total_tests++;

    assert (fwd_fwdA === exp_fwdA && fwd_fwdB === exp_fwdB) begin
      passed_tests++;
      $display("Passed: %s", test_name);
    end
    else
      $error(
        "Failed: %s\nExpected fwdA=%0d fwdB=%0d\nGot fwdA=%0d fwdB=%0d",
        test_name, exp_fwdA, exp_fwdB, fwd_fwdA, fwd_fwdB
      );
  endtask

  logic hzrd_mem_readE;
  logic [REG_ADDR_W-1:0] hzrd_rs1D, hzrd_rs2D, hzrd_rdE;
  pc_src_e hzrd_pc_srcE;
  logic hzrd_stallF, hzrd_stallD, hzrd_flushD, hzrd_flushE;

  hzrd_unit duv_hzrd(
    .mem_readE(hzrd_mem_readE),
    .rs1D(hzrd_rs1D),
    .rs2D(hzrd_rs2D),
    .rdE(hzrd_rdE),
    .pc_srcE(hzrd_pc_srcE),
    .stallF(hzrd_stallF),
    .stallD(hzrd_stallD),
    .flushD(hzrd_flushD),
    .flushE(hzrd_flushE)
  );

  task verify_hzrd(
    input logic mem_readE,
    input logic [REG_ADDR_W-1:0] rs1D, rs2D, rdE,
    input pc_src_e pc_srcE,
    input logic exp_stallF, exp_stallD, exp_flushD, exp_flushE,
    input string test_name
  );

    hzrd_mem_readE = mem_readE;
    hzrd_rs1D = rs1D;
    hzrd_rs2D = rs2D;
    hzrd_rdE = rdE;
    hzrd_pc_srcE = pc_srcE;

    #10;

    total_tests++;

    assert (
      hzrd_stallF === exp_stallF && hzrd_stallD === exp_stallD &&
      hzrd_flushD === exp_flushD && hzrd_flushE === exp_flushE
    ) begin
      passed_tests++;
      $display("Passed: %s", test_name);
    end
    else
      $error(
        "Failed: %s\nExpected stallF=%b stallD=%b flushD=%b flushE=%b\nGot stallF=%b stallD=%b flushD=%b flushE=%b",
        test_name, exp_stallF, exp_stallD, exp_flushD, exp_flushE,
        hzrd_stallF, hzrd_stallD, hzrd_flushD, hzrd_flushE
      );
  endtask

  initial begin
    $dumpfile("hazard_tb.vcd");
    $dumpvars(0, hazard_tb);

    //Clearing all signals before testing.
    fwd_rs1E = 0; fwd_rs2E = 0; fwd_rdM1 = 0; fwd_rdM2 = 0; fwd_rdW = 0;
    fwd_reg_writeM1 = 0; fwd_reg_writeM2 = 0; fwd_reg_writeW = 0;

    hzrd_mem_readE = 0;
    hzrd_rs1D = 0; hzrd_rs2D = 0; hzrd_rdE = 0;
    hzrd_pc_srcE = PC_PLUS4;

    #10;

    $display("STARTING HAZARD/FORWARDING UNIT TESTING:");
    
    $display("FORWARDING TESTING:");

    verify_fwd(5'd1, 5'd2, 5'd3, 5'd4, 5'd6, 1'b1, 1'b1, 1'b1, FWD_NONE_A, FWD_NONE_B, "Test 1: No hazard, no forwarding"); //Testing that unrelated regs don't forward.
    verify_fwd(5'd5, 5'd2, 5'd5, 5'd0, 5'd0, 1'b1, 1'b0, 1'b0, FWD_MEM1_A, FWD_NONE_B, "Test 2: rs1E forwards from MEM1"); //Testing rs1E == rdM1 forwards from the first MEM stage.
    verify_fwd(5'd5, 5'd2, 5'd3, 5'd5, 5'd0, 1'b1, 1'b1, 1'b0, FWD_MEM2_A, FWD_NONE_B, "Test 3: rs1E forwards from MEM2"); //Testing rs1E == rdM2 (no M1 match) forwards from the second MEM stage.
    verify_fwd(5'd5, 5'd2, 5'd3, 5'd4, 5'd5, 1'b1, 1'b1, 1'b1, FWD_WB_A, FWD_NONE_B, "Test 4: rs1E forwards from WB"); //Testing rs1E == rdW (no M1/M2 match) forwards from WB stage.
    verify_fwd(5'd0, 5'd2, 5'd0, 5'd0, 5'd0, 1'b1, 1'b1, 1'b1, FWD_NONE_A, FWD_NONE_B, "Test 5: x0 never forwards (rs1E)"); //Testing that x0 is never forwarded even on a match.
    verify_fwd(5'd1, 5'd7, 5'd7, 5'd0, 5'd0, 1'b1, 1'b0, 1'b0, FWD_NONE_A, FWD_MEM1_B, "Test 6: rs2E forwards from MEM1"); //Testing rs2E == rdM1 forwards from the first MEM stage.
    verify_fwd(5'd1, 5'd7, 5'd3, 5'd7, 5'd0, 1'b1, 1'b1, 1'b0, FWD_NONE_A, FWD_MEM2_B, "Test 7: rs2E forwards from MEM2"); //Testing rs2E == rdM2 (no M1 match) forwards from the second MEM stage.
    verify_fwd(5'd1, 5'd7, 5'd3, 5'd4, 5'd7, 1'b1, 1'b1, 1'b1, FWD_NONE_A, FWD_WB_B, "Test 8: rs2E forwards from WB"); //Testing rs2E == rdW (no M1/M2 match) forwards from WB stage.
    verify_fwd(5'd0, 5'd0, 5'd0, 5'd0, 5'd0, 1'b1, 1'b1, 1'b1, FWD_NONE_A, FWD_NONE_B, "Test 9: x0 never forwards (rs2E)"); //Testing that x0 is never forwarded on rs2E either.
    verify_fwd(5'd5, 5'd6, 5'd5, 5'd6, 5'd5, 1'b1, 1'b1, 1'b1, FWD_MEM1_A, FWD_MEM1_B, "Test 10: MEM1 takes priority over MEM2 and WB"); //Testing that MEM1 forwarding wins when M1, M2, and WB all match.
    verify_fwd(5'd5, 5'd6, 5'd5, 5'd6, 5'd5, 1'b0, 1'b1, 1'b1, FWD_MEM2_A, FWD_MEM2_B, "Test 11: MEM2 takes priority over WB when MEM1 is inactive"); //Testing that a matching rdM1 doesn't forward if reg_writeM1 is deasserted, falling through to MEM2 which takes priority over WB.
    verify_fwd(5'd5, 5'd6, 5'd5, 5'd6, 5'd5, 1'b0, 1'b0, 1'b1, FWD_WB_A, FWD_WB_B, "Test 12: WB used when MEM1 and MEM2 are both inactive"); //Testing that with reg_writeM1 and reg_writeM2 both deasserted, forwarding falls all the way through to WB.

    $display("HAZARD UNIT TESTING:");

    verify_hzrd(1'b0, 5'd1, 5'd2, 5'd3, PC_PLUS4, 1'b0, 1'b0, 1'b0, 1'b0, "Test 13: No hazard, no stall/flush"); //Testing the default, no-hazard case.
    verify_hzrd(1'b1, 5'd5, 5'd2, 5'd5, PC_PLUS4, 1'b1, 1'b1, 1'b0, 1'b1, "Test 14: Load-use hazard on rs1D"); //Testing a load-use hazard through rs1D stalls fetch/decode and flushes execute.
    verify_hzrd(1'b1, 5'd2, 5'd6, 5'd6, PC_PLUS4, 1'b1, 1'b1, 1'b0, 1'b1, "Test 15: Load-use hazard on rs2D"); //Testing a load-use hazard through rs2D.
    verify_hzrd(1'b1, 5'd0, 5'd0, 5'd0, PC_PLUS4, 1'b0, 1'b0, 1'b0, 1'b0, "Test 16: Load-use hazard ignored for x0"); //Testing that a load-use hazard targeting x0 is ignored.
    verify_hzrd(1'b1, 5'd1, 5'd2, 5'd9, PC_PLUS4, 1'b0, 1'b0, 1'b0, 1'b0, "Test 17: mem_readE with no matching rs1D/rs2D"); //Testing that a load in EX with no dependent regs in ID causes no stall.
    verify_hzrd(1'b0, 5'd1, 5'd2, 5'd3, PC_TARGET, 1'b0, 1'b0, 1'b1, 1'b1, "Test 18: Branch misprediction flushes D and E"); //Testing a taken branch (PC_TARGET) causes flushD and flushE, no stalling.
    verify_hzrd(1'b0, 5'd1, 5'd2, 5'd3, PC_RESULT, 1'b0, 1'b0, 1'b1, 1'b1, "Test 19: JALR misprediction flushes D and E"); //Testing PC_RESULT (JALR) also causes flushD and flushE.
    verify_hzrd(1'b1, 5'd5, 5'd2, 5'd5, PC_TARGET, 1'b1, 1'b1, 1'b1, 1'b1, "Test 20: Simultaneous load-use hazard and branch misprediction"); //Testing that both hazards together stall fetch/decode and flush both D and E.

    $display("HAZARD/FORWARDING UNIT TESTING COMPLETE!");
    $display("Results: %0d/%0d tests passed.", passed_tests, total_tests);
    $finish;
  end
endmodule