# Load/Store Instruction Tests
addi x1, x0, 0 # x1 = 0 (base address)
addi x2, x0, -1 # x2 = -1
sw x2, 0(x1) # mem word @0 = -1
lw x3, 0(x1) # x3 = 0xFFFFFFFF (-1)

addi x4, x0, 0x7A # x4 = 122 (positive byte)
sb x4, 4(x1) # mem byte @4 = 0x7A
lb x5, 4(x1) # x5 = 0x0000007A = 122 (sign-extend, no change since positive)
lbu x6, 4(x1) # x6 = 0x0000007A = 122 (zero-extend, same value)

addi x7, x0, -2 # x7 = -2 = 0xFFFFFFFE (low byte = 0xFE)
sb x7, 8(x1) # mem byte @8 = 0xFE
lb x8, 8(x1) # x8 = 0xFFFFFFFE = -2 (sign-extended)
lbu x9, 8(x1) # x9 = 0x000000FE = 254 (zero-extended)

addi x10, x0, 0x3FF # x10 = 1023 (positive half-word)
sh x10, 12(x1) # mem halfword @12 = 0x03FF
lh x11, 12(x1) # x11 = 0x000003FF = 1023 (sign-extended, no change since positive)
lhu x12, 12(x1) # x12 = 0x000003FF = 1023 (zero-extended, same value)

addi x13, x0, -100 # x13 = -100 = 0xFFFFFF9C (low half = 0xFF9C)
sh x13, 16(x1) # mem halfword @16 = 0xFF9C
lh x14, 16(x1) # x14 = 0xFFFFFF9C = -100 (sign-extended)
lhu x15, 16(x1) # x15 = 0x0000FF9C = 65436 (zero-extended)

# Byte offsets 0-3 within one word:
addi x16, x0, 0x11 # x16 = 0x11
addi x17, x0, 0x22 # x17 = 0x22
addi x18, x0, 0x33 # x18 = 0x33
addi x19, x0, 0x44 # x19 = 0x44
sb x16, 20(x1) # mem byte offset 0 of word @20 = 0x11
sb x17, 21(x1) # mem byte offset 1 of word @20 = 0x22
sb x18, 22(x1) # mem byte offset 2 of word @20 = 0x33
sb x19, 23(x1) # mem byte offset 3 of word @20 = 0x44
lw x20, 20(x1) # x20 = 0x44332211

# Half-word offsets (low half vs high half) within one word:
addi x21, x0, 0x0AB # x21 = 0x0AB
addi x22, x0, 0x0CD # x22 = 0x0CD
sh x21, 24(x1) # mem low half of word @24 = 0x00AB
sh x22, 26(x1) # mem high half of word @24 = 0x00CD
lw x23, 24(x1) # x23 = 0x00CD00AB
