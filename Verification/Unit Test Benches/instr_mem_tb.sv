import riscv_pkg::*;
`timescale 1ns/1ps

module imem_tb;

  int unsigned total_tests = 0;
  int unsigned passed_tests = 0;
  logic default_is_correct;
  int word_index;

  logic [XLEN-1:0] default_pc_addr;
  logic [XLEN-1:0] default_instr;

  imem #(                         //DUV1: IMEM when nothing is uploaded.
    .init_mem(""),
    .rom_size(1024)
  ) duv_default (
    .pc_addr(default_pc_addr),
    .instr(default_instr)
  );

  logic [XLEN-1:0] init_pc_addr;
  logic [XLEN-1:0] init_instr; 

  imem #(                         //DUV2: IMEM when memory is initialized.
    .init_mem("instr_mem_test.hex"),
    .rom_size(16)
  ) duv_init (
    .pc_addr(init_pc_addr),
    .instr(init_instr)
  );

  task verify_init(                      //Used to test the initialized imem.
    input logic [XLEN-1:0] addr,
    input logic [XLEN-1:0] exp_instr,
    input string test_name
  );
    init_pc_addr = addr;

    #10;

    total_tests++;
 
    assert (init_instr === exp_instr) begin
      passed_tests++;
      $display("Passed: %s", test_name);
    end
    else
      $error("Failed: %s\nExpected instr = %h\nGot instr = %h", test_name, exp_instr, init_instr);
  endtask

  initial begin
    $dumpfile("instr_mem_tb.vcd");
    $dumpvars(0, imem_tb);

    default_pc_addr = 32'd0;
    init_pc_addr = 32'd0;

    #10;

    $display("STARTING IMEM TESTING!");

    //Testing default imem:
    total_tests++;
    default_is_correct = 1'b1;

    for(word_index = 0; word_index < 1024; word_index++) begin
      default_pc_addr = word_index * 4;

      #10;

      if (default_instr !== 32'h0000_0013) begin
        default_is_correct = 1'b0;
        $error(
          "Failed: Default NOP check at word %0d (addr %h)\nExpected instr = 00000013\nGot instr = %h",
          word_index, default_pc_addr, default_instr
        );
      end
    end

    if (default_is_correct) begin
      passed_tests++;
      $display("Passed: Test 1: Default ROM fully NOP-filled (1024 words)");
    end
    
    //Testiing initialized imem:
    verify_init(32'h0000_0000, 32'h0000_0093, "Test 2: Word 0 loaded from hex file");
    verify_init(32'h0000_0004, 32'h0011_0113, "Test 3: Word 1 loaded from hex file");
    verify_init(32'h0000_0008, 32'h0022_0193, "Test 4: Word 2 loaded from hex file");
    verify_init(32'h0000_003C, 32'hDEAD_BEEF, "Test 5: Last word (word 15) loaded from hex file");
    verify_init(32'h0000_0001, 32'h0000_0093, "Test 6: Byte offset 1 aliases to word 0");
    verify_init(32'h0000_0002, 32'h0000_0093, "Test 7: Byte offset 2 aliases to word 0");
    verify_init(32'h0000_0003, 32'h0000_0093, "Test 8: Byte offset 3 aliases to word 0");
    verify_init(32'h0000_0005, 32'h0011_0113, "Test 9: Byte offset 1 aliases to word 1");

    $display("INSTRUCTION MEMORY TESTING COMPLETE!");
    $display("Results: %0d/%0d tests passed.", passed_tests, total_tests);
  end
endmodule
