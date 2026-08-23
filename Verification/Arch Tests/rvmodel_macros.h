// rvmodel_macros.h
//
// DUT-specific macro header for riscv-arch-test / ACT4.
// This core (RISC-V-CPU) has NO CSR file and NO trap/exception entry -
// OP_SYSTEM (ecall/ebreak) is decoded as legal but does nothing (see
// main_decoder.sv). The stock arch-test macros assume a CSR-capable DUT
// that traps to mtvec on ecall to signal test completion, so they can't
// be used as-is. Instead this header uses the same trick the design
// already uses for its UART peripheral: a dedicated, reserved RAM word
// that the testbench polls to detect "test finished", plus a signature
// region the testbench dumps directly out of dmem.ram via $writememh.
//
// Pair this with:
//   - link.ld           (places .signature.* below the reserved halt word)
//   - arch_test_tb.sv   (polls the halt word, dumps the signature)
//
// NOTE: This targets rv32i_m/I only. Tests under M, C, Zicsr, Zifencei,
// and privilege are out of scope until the core gains those extensions.
// Some individual I-suite tests may also assume Zicsr/traps for
// bookkeeping (rare, but check test source if one hangs instead of
// halting) - those should be skipped/xfailed rather than "fixed" here.

#ifndef RVMODEL_MACROS_H
#define RVMODEL_MACROS_H

//----------------------------------------------------------------------
// Memory map (must match the `top` instantiation used for arch tests):
//   ram_size = 4096 words (16KB)   -> byte range 0x0000_0000-0x0000_3FFF
//   Reserved halt word:            0x0000_3FFC  (last word of ram)
//----------------------------------------------------------------------
#define RVMODEL_HALT_ADDR   0x00003FFC
#define RVMODEL_HALT_CODE   1           // any nonzero sentinel works

//----------------------------------------------------------------------
// RVMODEL_BOOT: runs before rvtest_init. pc.sv already resets to 0 and
// there's no privilege/CSR state to initialize, so this is empty.
//----------------------------------------------------------------------
#define RVMODEL_BOOT

//----------------------------------------------------------------------
// RVMODEL_DATA_SECTION: standard signature-region wrapper. begin_signature
// / end_signature (declared by the test source itself) land inside this
// section, which link.ld places below the reserved halt word.
//----------------------------------------------------------------------
#define RVMODEL_DATA_SECTION \
        .align 4;             \
        .global begin_signature; \
        begin_signature:

//----------------------------------------------------------------------
// RVMODEL_HALT: instead of ecall+mtvec, write a sentinel to the reserved
// halt word and spin forever - mirrors the "halt: jal x0, halt" idiom
// already used in Peripherals/uart_test.s. The testbench (arch_test_tb.sv)
// polls this word every cycle; once nonzero it lets a few more cycles
// settle (in case of in-flight pipeline writebacks) and then dumps the
// signature and finishes the simulation.
//----------------------------------------------------------------------
#define RVMODEL_HALT                        \
        li  x31, RVMODEL_HALT_ADDR;         \
        li  x30, RVMODEL_HALT_CODE;         \
        sw  x30, 0(x31);                    \
rvmodel_halt_loop:                          \
        jal x0, rvmodel_halt_loop

//----------------------------------------------------------------------
// I/O macros: no UART/console wired up for arch tests, so these are
// no-ops. (The core's real UART peripheral is FPGA-only, see
// Peripherals/uart_tx.sv / FPGA/fpga_top.sv - not present in the plain
// `top` module used for simulation.)
//----------------------------------------------------------------------
#define RVMODEL_IO_INIT
#define RVMODEL_IO_WRITE_STR(_R, _STR)
#define RVMODEL_IO_CHECK()
#define RVMODEL_IO_ASSERT_GPR_EQ(_S, _R, _I)
#define RVMODEL_IO_ASSERT_SFPR_EQ(_F, _R, _I)
#define RVMODEL_IO_ASSERT_DFPR_EQ(_D, _R, _I)

//----------------------------------------------------------------------
// No interrupt support - stub out.
//----------------------------------------------------------------------
#define RVMODEL_SET_MSW_INT
#define RVMODEL_CLEAR_MSW_INT
#define RVMODEL_CLEAR_MTIMER_INT
#define RVMODEL_CLEAR_MEXT_INT

#endif // RVMODEL_MACROS_H
