# Makefile: assembles every *.s file in this directory into a *.hex file
# ready for $readmemh in your imem module.
#
# Usage:
#   make            # build all .hex files
#   make clean      # remove intermediate/output files

PREFIX   ?= riscv64-unknown-elf-
AS       := $(PREFIX)as
LD       := $(PREFIX)ld
OBJCOPY  := $(PREFIX)objcopy

ASFLAGS  := -march=rv32i -mabi=ilp32
LDFLAGS  := -Ttext=0x0

SOURCES  := $(wildcard *.s)
HEXFILES := $(SOURCES:.s=.hex)

all: $(HEXFILES)

%.clean.s: %.s
	sed 's/;.*//' $< > $@

%.o: %.clean.s
	$(AS) $(ASFLAGS) -o $@ $<

%.elf: %.o
	$(LD) $(LDFLAGS) -o $@ $<

%.bin: %.elf
	$(OBJCOPY) -O binary -j .text $< $@

%.hex: %.bin bin_to_hex.py
	python3 bin_to_hex.py $< $@

clean:
	rm -f *.clean.s *.o *.elf *.bin *.hex

.PRECIOUS: %.clean.s %.o %.elf %.bin
.PHONY: all clean
