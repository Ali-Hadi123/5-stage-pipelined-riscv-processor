// rvmodel_macros.h
//
// This core (RISC-V-CPU) has NO CSR file, NO privilege modes, and NO
// trap/interrupt support - main_decoder.sv decodes OP_SYSTEM (ecall/
// ebreak) as legal but a no-op. That means:
//   - include_priv_tests: False in test_config.yaml (see sibling file)
//   - every optional macro in the README that's "for machine mode /
//     interrupts / MSIP / timers / console" is simply omitted below,
//     which the ACT README explicitly allows ("can be left blank if
//     no console is available" / "if machine mode is not supported" /
//     "if interrupts are not supported").
//
// Memory map (MUST match link.ld's RAM_ORIGIN/RAM_LENGTH and
// act4_test_tb.sv's ram_size/rom_size parameters on the `top`
// instantiation):
//   RAM_LENGTH words - 1  ->  reserved halt/result word

#ifndef RVMODEL_MACROS_H
#define RVMODEL_MACROS_H

//----------------------------------------------------------------------
// CHANGE ME IF YOU CHANGE link.ld's RAM_LENGTH: this must always equal
// (RAM_LENGTH - 4), i.e. the byte address of the LAST word of RAM.
//----------------------------------------------------------------------
#define RVMODEL_HALT_ADDR   0x0003FFFC     // last word of RAM
#define RVMODEL_PASS_CODE   0x00000001
#define RVMODEL_FAIL_CODE   0x00000002

//----------------------------------------------------------------------
// RVMODEL_DATA_SECTION: standard signature-region wrapper, unchanged
// from the classic-framework convention this repo already used.
//----------------------------------------------------------------------
#define RVMODEL_DATA_SECTION \
        .align 4;             \
        .global begin_signature; \
        begin_signature:

//----------------------------------------------------------------------
// Required macros: report PASS or FAIL by writing a distinct sentinel
// to the reserved halt word, then spin forever. act4_test_tb.sv polls
// this word and reports which sentinel showed up.
//----------------------------------------------------------------------
#define RVMODEL_HALT_PASS                   \
        li  x31, RVMODEL_HALT_ADDR;         \
        li  x30, RVMODEL_PASS_CODE;         \
        sw  x30, 0(x31);                    \
rvmodel_pass_loop:                          \
        jal x0, rvmodel_pass_loop

#define RVMODEL_HALT_FAIL                   \
        li  x31, RVMODEL_HALT_ADDR;         \
        li  x30, RVMODEL_FAIL_CODE;         \
        sw  x30, 0(x31);                    \
rvmodel_fail_loop:                          \
        jal x0, rvmodel_fail_loop

#define RVMODEL_IO_INIT(_R1, _R2, _R3)    \
#define RVMODEL_IO_WRITE_STR(_R1, _R2, _R3, _STR_PTR)               \

#define RVMODEL_INTERRUPT_LATENCY 10
#define RVMODEL_TIMER_INT_SOON_DELAY 100

#define RVMODEL_CLR_MEXT_INT(_R1, _R2)

#define RVMODEL_SET_MSW_INT(_R1, _R2) \
#define RVMODEL_CLR_MSW_INT(_R1, _R2) \

#define RVMODEL_SET_SEXT_INT(_R1, _R2)
#define RVMODEL_CLR_SEXT_INT(_R1, _R2)

#define RVMODEL_SET_SSW_INT(_R1, _R2) \
#define RVMODEL_CLR_SSW_INT(_R1, _R2) \

#endif // RVMODEL_MACROS_H
