// arch_test_tb.sv
//
// Generic runner for a single riscv-arch-test program. Unlike
// top_level_tb.sv (which hardcodes one .hex per DUV at compile time via
// the `init_mem` parameter), this testbench loads its program at runtime
// so run_arch_tests.sh can drive the whole rv32i_m/I suite through one
// compiled simulation binary.
//
// Usage (see run_arch_tests.sh for the full flow):
//   vvp arch_test_tb.vvp \
//       +HEXFILE=path/to/test.hex \
//       +SIGFILE=path/to/test.sig \
//       +SIGBEGIN=00000040 \
//       +SIGEND=00000080
//
// SIGBEGIN/SIGEND are byte addresses of the begin_signature/end_signature
// symbols, extracted from the ELF by run_arch_tests.sh (e.g. via `nm`).
//
// ram_size/rom_size here MUST match link.ld and RVMODEL_HALT_ADDR in
// rvmodel_macros.h (16KB / 4096 words, halt word = last word).

`timescale 1ns/1ps

module arch_test_tb;

  localparam int unsigned RAM_SIZE = 4096;   // words -> 16KB, matches link.ld
  localparam int unsigned ROM_SIZE = 4096;   // words -> program + data share the same 16KB window
  localparam int unsigned HALT_WORD_IDX = RAM_SIZE - 1; // 0x0000_3FFC / 4

  localparam int unsigned MAX_CYCLES = 200000; // safety timeout per test
  localparam logic [31:0] HALT_SENTINEL = 32'h0000_0001; // must match RVMODEL_HALT_CODE

  logic clk;
  logic rst;
  logic illegal_instr;

  logic [31:0] fpga_mem_addr;
  logic [31:0] fpga_mem_wdata;
  logic fpga_mem_write;

  // init_mem left blank: rom is loaded at runtime below, after reset,
  // via a hierarchical $readmemh into u_imem.rom.
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
  string sigfile;
  int unsigned sigbegin_byte, sigend_byte;
  int unsigned sigbegin_word, sigend_word;
  int unsigned cycle_count;
  bit timed_out;
  bit halted;
  bit illegal_seen;

  initial begin
    clk = 0;
    rst = 1;

    if (!$value$plusargs("HEXFILE=%s", hexfile)) begin
      $display("ERROR: +HEXFILE=<path> not provided");
      $finish(1);
    end
    if (!$value$plusargs("SIGFILE=%s", sigfile)) sigfile = "signature.txt";
    if (!$value$plusargs("SIGBEGIN=%h", sigbegin_byte)) sigbegin_byte = 0;
    if (!$value$plusargs("SIGEND=%h",   sigend_byte))   sigend_byte   = 0;

    #10;
    rst = 0;

    // Load the program after reset so it isn't clobbered by imem's own
    // NOP-fill initial block, which races with this one at time 0.
    $readmemh(hexfile, duv.u_imem.rom);

    halted = 1'b0;
    timed_out = 1'b0;
    illegal_seen = 1'b0;
    cycle_count = 0;

    while (!halted && !timed_out) begin
      @(posedge clk);
      cycle_count++;

      // dmem.ram is not reset/zeroed, so it reads as X until written -
      // and X !== 0 is true, which would false-trigger a halt on cycle 1.
      // Match the exact sentinel value instead of "nonzero".
      if (duv.u_dmem.ram[HALT_WORD_IDX] === HALT_SENTINEL)
        halted = 1'b1;

      if (illegal_instr && !illegal_seen) begin
        illegal_seen = 1'b1;
        $display("NOTE: illegal_instr asserted at cycle %0d (pc frozen) - core will not reach RVMODEL_HALT, failing fast instead of waiting out the timeout", cycle_count);
        timed_out = 1'b1; // no point burning the full timeout once the PC is frozen
      end

      if (cycle_count >= MAX_CYCLES)
        timed_out = 1'b1;
    end

    if (timed_out) begin
      if (illegal_seen)
        $display("FAIL: %s hit an illegal instruction at cycle %0d and never reached RVMODEL_HALT", hexfile, cycle_count);
      else
        $display("FAIL: %s timed out after %0d cycles without hitting the halt word", hexfile, MAX_CYCLES);
      $finish(1);
    end

    // Let a few more cycles pass so any in-flight writeback settles
    // before the signature is read out.
    repeat (10) @(posedge clk);

    sigbegin_word = sigbegin_byte >> 2;
    sigend_word   = (sigend_byte >> 2) - 1;

    if (sigend_word < sigbegin_word) begin
      $display("WARN: empty/invalid signature range [%0h:%0h] for %s - writing nothing", sigbegin_byte, sigend_byte, hexfile);
    end
    else begin
      $writememh(sigfile, duv.u_dmem.ram, sigbegin_word, sigend_word);
    end

    $display("DONE: %s halted after %0d cycles, signature written to %s", hexfile, cycle_count, sigfile);
    $finish(0);
  end

endmodule
