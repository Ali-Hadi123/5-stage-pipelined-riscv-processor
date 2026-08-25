/* link.ld
 *
 * ACT4 linker script for the RISC-V-CPU `top` module.
 *
 * Follows the section-layout contract from the "Linker Script" section
 * of https://github.com/riscv/riscv-arch-test (act4 branch) README:
 *   - ENTRY is rvtest_entry_point
 *   - .text.init starts at TEST_BASE
 *   - .text.rvtest follows .text.init
 *   - .rodata / .data / .bss exist, .bss defines __bss_start/__bss_end
 *   - __stack_bottom / __stack_top defined, STACK_SIZE * NUM_HARTS bytes
 *   - .text.rvmodel is a catch-all that comes LAST (after data/stack) so
 *     DUT-specific code size doesn't perturb data symbol addresses
 */

OUTPUT_ARCH("riscv")
ENTRY(rvtest_entry_point)

RAM_ORIGIN = 0x00000000;
RAM_LENGTH = 0x00050000;   /* 328KB */
TEST_BASE  = RAM_ORIGIN;
NUM_HARTS  = 1;

MEMORY
{
  ram (rwx) : ORIGIN = 0x00000000, LENGTH = 0x00050000  /* must equal RAM_ORIGIN/RAM_LENGTH above */
}

STACK_SIZE = 0x1000;   /* 4KB - conservative given this core's small RAM; grow if tests fault on stack use */

SECTIONS
{
  .text.init TEST_BASE : { *(.text.init) } > ram

  . = ALIGN(4);
  .text.rvtest . : { *(.text.rvtest) *(.text.rvtest.*) } > ram

  . = ALIGN(4);
  .rodata . : { *(.rodata) *(.rodata.*) } > ram

  . = ALIGN(4);
  .data . : { *(.data) *(.data.*) } > ram

  . = ALIGN(4);
  .bss . : {
    __bss_start = .;
    *(.bss) *(.bss.*) *(COMMON)
    __bss_end = .;
  } > ram

  . = ALIGN(8);
  .tohost . : { *(.tohost) } > ram

  . = ALIGN(16);
  __stack_bottom = .;
  . += STACK_SIZE * NUM_HARTS;
  __stack_top = .;

  /* Catch-all for DUT-specific (RVMODEL_*) code - must be last. */
  . = ALIGN(4);
  .text.rvmodel . : {
    *(.text.rvmodel) *(.text.rvmodel.*)
    *(.text) *(.text.*)
  } > ram

  ASSERT(. <= RAM_ORIGIN + RAM_LENGTH,
    "ACT4 test image overflowed RAM_LENGTH - grow RAM_LENGTH here AND ram_size/rom_size in act4_test_tb.sv")
}
