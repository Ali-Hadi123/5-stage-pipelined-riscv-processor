#This makefile is used to convert the .s assembly programs into .hex files.

#Usage:
# make         -->     buils all .hex files from the .s files.
# make clean   -->     removes intermediate files.

.SUFFIX:		#Cancels built-in rules from the GNU toolchain.

PREFIX ?= riscv-none-elf-

AS := $(PREFIX)as                    #Defining variables/shortcuts:
LD := $(PREFIX)ld
OBJCOPY := $(PREFIX)objcopy
ASFLAGS := -march=rv32i -mabi=ilp32
LDFLAGS := -Ttext=0x0

ASMFILES := $(wildcard *.s)
HEXFILES := $(ASMFILES:.s=.hex)

all: $(HEXFILES)

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

%.elf: %.o
	$(LD) $(LDFLAGS) -o $@ $<
 
%.bin: %.elf
	$(OBJCOPY) -O binary -j .text $< $@
 
%.hex: %.bin bin_to_hex.py
	python3 bin_to_hex.py $< $@

clean:                             #Deletes all intermediate files (leaves only .s and .hex).
	rm -f *.clean.s *.o *.elf *.bin

.PHONY: all clean #Prevents make from getting confused by files named "clean" or "all" in a directory.
