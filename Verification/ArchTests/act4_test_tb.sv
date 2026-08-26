// act4_test_tb.sv
//
// Generic runner for one ACT4 self-checking test, loaded as a hex file
// (converted from the ELF ACT4 produces - see run_act4_tests.sh).
//
// ram_size/rom_size MUST match link.ld's RAM_LENGTH, and the sentinel
// values MUST match RVMODEL_PASS_CODE/RVMODEL_FAIL_CODE in
// rvmodel_macros.h.
//
// Usage:
//   vvp act4_test_tb.vvp +HEXFILE=path/to/test.hex

`timescale 1ns/1ps

module act4_test_tb;

  localparam int unsigned RAM_SIZE = 81920;   // words, must match link.ld RAM_LENGTH
  localparam int unsigned ROM_SIZE = 81920;

  localparam int unsigned MAX_CYCLES = 500000; // safety timeout per test

  localparam logic [31:0] PASS_SENTINEL = 32'h0000_0001; // must match RVMODEL_PASS_CODE
  localparam logic [31:0] FAIL_SENTINEL = 32'h0000_0003; // must match RVMODEL_FAIL_CODE

  logic clk;
  logic rst;
  logic illegal_instr;

  logic [31:0] fpga_mem_addr;
  logic [31:0] fpga_mem_wdata;
  logic fpga_mem_write;

  top #(
    .ram_size(RAM_SIZE),
    .rom_size(ROM_SIZE),
    .init_mem("")
  ) duv (
    .clk(clk),
    .rst(rst),
    .illegal_instr(illegal_instr),
    .fpga_mem_addr(fpga_mem_addr),
    .fpga_mem_wdata(fpga_mem_wdata),
    .fpga_mem_write(fpga_mem_write)
  );

  always #5 clk = ~clk;

  string hexfile;
  logic [31:0] tohost_addr;
  logic [31:0] tohost_word_idx;
  int unsigned cycle_count;
  bit done, timed_out, illegal_seen;
  logic [31:0] halt_word;

  initial begin
    clk = 0;
    rst = 1;

    if (!$value$plusargs("HEXFILE=%s", hexfile)) begin
      $display("ERROR: +HEXFILE=<path> not provided");
      $finish(1);
    end

    if (!$value$plusargs("TOHOST_ADDR=%h", tohost_addr)) begin
      $display("ERROR: +TOHOST_ADDR=<hex byte address> not provided");
      $finish(1);
    end
    tohost_word_idx = tohost_addr >> 2;

    $display("");
    $display("============================================================");
    $display("ACT4 DEBUG");
    $display("HEXFILE      = %s", hexfile);
    $display("TOHOST_ADDR  = %08h", tohost_addr);
    $display("TOHOST_INDEX = %0d", tohost_word_idx);
    $display("============================================================");
    $display("");

    #10;
    rst = 0;

    // Load after reset, same reasoning as arch_test_tb.sv: imem's own
    // NOP-fill initial block races with this one at time 0 otherwise.
    $readmemh(hexfile, duv.u_imem.rom);
    $readmemh(hexfile, duv.u_dmem.ram);

    done = 1'b0;
    timed_out = 1'b0;
    illegal_seen = 1'b0;
    cycle_count = 0;
    halt_word = 32'h0;

    while (!done && !timed_out) begin
      @(posedge clk);
      #1;
      cycle_count++;

      halt_word = duv.u_dmem.ram[tohost_word_idx];

      if (cycle_count <= 100) begin
        $display(
          "cycle=%0d  PC=%08h  instr=%08h  illegal=%b  mem_write=%b addr=%08h wdata=%08h",
          cycle_count,
          duv.pc_out,
          duv.instrF,
          illegal_instr,
          duv.em_out.alu_result,
          duv.fpga_mem_write,
          duv.fpga_mem_addr,
          duv.fpga_mem_wdata
        );

        $display(
          "DEBUG: rs1E=%0d rdM=%0d rdW=%0d fwdA=%0d rdata1E=%08h wb=%08h mem=%08h alu=%08h",
          duv.de_out.rs1_addr,
          duv.em_out.rd_addr,
          duv.mw_out.rd_addr,
          duv.fwdA,
          duv.de_out.rdata1,
          duv.wb_data,
          duv.em_out.alu_result,
          duv.alu_resultE
        );
      end

      if (fpga_mem_write) begin
        $display(
          "STORE: cycle=%0d addr=%08h data=%08h",
          cycle_count,
          fpga_mem_addr,
          fpga_mem_wdata
        );
      end

      
      if (illegal_instr && !illegal_seen) begin

        illegal_seen = 1;

        $display("");
        $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        $display("ILLEGAL INSTRUCTION DETECTED");
        $display("cycle      = %0d", cycle_count);
        $display("PC         = %08h", duv.pc_out);
        $display("instr      = %08h", duv.instrF);
        $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        $display("");

        // Don't immediately stop.
        // Let the CPU continue so we can see what happens
      end

      // dmem.ram is not reset/zeroed, so it reads as X until written -
      // match the exact sentinels rather than "nonzero" to avoid a
      // false trigger from X on cycle 1.
      if (halt_word === PASS_SENTINEL || halt_word === FAIL_SENTINEL)
        done = 1'b1;

      if (illegal_instr && !illegal_seen) begin
        illegal_seen = 1'b1;
        $display("NOTE: illegal_instr asserted at cycle %0d (pc frozen) - failing fast instead of waiting out the timeout", cycle_count);
        timed_out = 1'b1;
      end

      if (cycle_count >= MAX_CYCLES)
        timed_out = 1'b1;
    end

    $display("");
    $display("============================================================");
    $display("ACT4 DEBUG RESULT");
    $display("============================================================");
    $display("cycles       = %0d", cycle_count);
    $display("tohost addr  = %08h", tohost_addr);
    $display("tohost value = %08h", halt_word);
    $display("illegal seen = %b", illegal_seen);
    $display("final PC     = %08h", duv.pc_out);
    $display("final instr  = %08h", duv.instrF);
    $display("============================================================");

    if (timed_out) begin
      $display("RVCP-SUMMARY: TEST FAILED - Test File \"%s\" (%s at cycle %0d)",
                hexfile, illegal_seen ? "illegal instruction" : "timed out", cycle_count);
      $finish(1);
    end
    else if (halt_word === PASS_SENTINEL) begin
      $display("RVCP-SUMMARY: TEST PASSED - Test File \"%s\"", hexfile);
      $finish(0);
    end
    else begin
      $display("RVCP-SUMMARY: TEST FAILED - Test File \"%s\"", hexfile);
      $finish(1);
    end
  end

endmodule
