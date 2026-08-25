// rvtest_config.svh
//
// SystemVerilog-level ACT4 test configuration for riscv-cpu-rv32i (this
// repo's 5-stage pipelined `top` module).
//
// This is the SV counterpart to rvtest_config.h and mirrors the same
// source of truth, riscv-cpu-rv32i.yaml: RV32I only, Sm "implemented"
// only because UDB gates MXLEN/other base hart params on it, every
// optional M-mode feature actually turned off (no CSR file, no PMP, no
// privilege modes below M, no traps other than the core's own
// illegal-instruction halt), and test_config.yaml (include_priv_tests:
// False).
//
// NOTE: the ACT4 README states rvtest_config.h/.svh will eventually be
// auto-generated from the UDB config file, but that generator does not
// exist yet, so this file is handwritten to match riscv-cpu-rv32i.yaml.
// If a newer riscv-arch-test release ships that generator, prefer
// regenerating this file over hand-maintaining it.

`ifndef RVTEST_CONFIG_SVH
`define RVTEST_CONFIG_SVH

  //===== Base ISA / XLEN =====

  localparam int unsigned RVTEST_XLEN = 32;
  localparam int unsigned XLEN = 32;

  //===== Implemented extensions =====
  // Only the base integer extension. Everything else - M, A, F, D, C, B,
  // V, Zicsr, Zifencei, and all Zk/Zv/Zs/Sv/Ss extensions - is absent.

  `define RVTEST_I

  `undef RVTEST_E
  `undef RVTEST_M
  `undef RVTEST_A
  `undef RVTEST_F
  `undef RVTEST_D
  `undef RVTEST_C
  `undef RVTEST_B
  `undef RVTEST_V
  `undef RVTEST_ZICSR
  `undef RVTEST_ZIFENCEI

  //===== Privilege modes =====
  // Sm is nominally "implemented" per riscv-cpu-rv32i.yaml only because
  // UDB requires a base hart to gate MXLEN/other params on it; this core
  // has no CSR file (misa/marchid/mimpid/mtvec/etc. simply don't exist)
  // and no M-mode features below are actually present. No S-mode, no
  // U-mode.

  `define RVTEST_SM

  `undef RVTEST_S
  `undef RVTEST_U

  //===== CSR / trap behavior =====
  // No CSR file at all, so no CSR-based exception mechanism exists. The
  // core instead halts (freezes PC) on any illegal instruction - see
  // illegal_instr in RTL/Top/top_level.sv.

  `undef RVTEST_MISA_CSR_IMPLEMENTED
  `undef RVTEST_MARCHID_IMPLEMENTED
  `undef RVTEST_MIMPID_IMPLEMENTED
  `undef RVTEST_TRAP_ON_ECALL_FROM_M
  `undef RVTEST_TRAP_ON_EBREAK

  //===== PMP / HPM counters =====
  // No PMP entries, no hardware performance monitor counters beyond
  // what's mandatory (none).

  localparam int unsigned RVTEST_NUM_PMP_ENTRIES = 0;

  `undef RVTEST_MCOUNTINHIBIT_IMPLEMENTED

  //===== Memory / alignment behavior =====
  // RTL/Data Path/data_mem.sv performs byte/half/word accesses via a raw
  // byte address with no alignment check, so misaligned loads/stores are
  // allowed and never fault - they simply don't correctly merge across a
  // word boundary.

  localparam bit RVTEST_MISALIGNED_LDST_ALLOWED = 1'b1;

  //===== Physical memory =====

  localparam int unsigned RVTEST_PHYS_ADDR_WIDTH = 32;

`endif // RVTEST_CONFIG_SVH
