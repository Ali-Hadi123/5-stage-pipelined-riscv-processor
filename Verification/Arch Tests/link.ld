/* link.ld
 *
 * Linker script for running riscv-arch-test (rv32i_m/I) programs against
 * this core's `top` module in simulation.
 *
 * Memory layout must match the ram_size/rom_size parameters used to
 * instantiate `top` in arch_test_tb.sv:
 *   0x0000_0000 - 0x0000_3FFB   .text / .data / .signature.*
 *   0x0000_3FFC - 0x0000_3FFF   reserved halt word (RVMODEL_HALT_ADDR)
 *
 * Tests are linked to run from address 0, matching how imem.sv indexes
 * pc_addr directly against word 0 of the ROM (same convention as the
 * existing Makefile: `LDFLAGS := -Ttext=0x0`).
 */

OUTPUT_ARCH("riscv")
ENTRY(rvtest_entry_point)

MEMORY
{
  ram (rwx) : ORIGIN = 0x00000000, LENGTH = 0x00004000  /* 16KB = 4096 words */
}

SECTIONS
{
  . = 0x00000000;

  .text.init : { *(.text.init) }              > ram
  .text      : { *(.text) *(.text.*) }        > ram

  . = ALIGN(4);
  .data      : { *(.data) *(.data.*) }        > ram

  . = ALIGN(4);
  .signature.begin : { *(.signature.begin) }  > ram
  .signature        : { *(.signature) }       > ram
  .signature.end    : { *(.signature.end) }   > ram

  /* Everything else the test declares (bss, stack, etc.) - kept well
     below the reserved halt word at the top of ram. */
  . = ALIGN(4);
  .bss  : { *(.bss) *(.bss.*) *(COMMON) }     > ram

  /* Reserve the very last word of ram for the halt sentinel so ordinary
     test data can never alias onto it. Must equal RVMODEL_HALT_ADDR in
     rvmodel_macros.h. */
  ASSERT(. <= 0x00003FFC, "arch-test program + data overflowed into the reserved halt word - shrink the test or grow ram_size in both link.ld and arch_test_tb.sv")
}
