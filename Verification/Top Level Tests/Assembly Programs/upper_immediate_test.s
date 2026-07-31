; Upper Immediate Test (LUI / AUIPC)

auipc x1, 0 ; x1 = PC + (0<<12) = 0x00000000 (this is the 1st instruction, at address 0)
auipc x2, 1 ; x2 = PC + (1<<12) = 0x00000004 + 0x00001000 = 0x00001004 (2nd instr, at address 4)
lui x3, 0x12345 ; x3 = 0x12345 << 12 = 0x12345000
lui x4, 0xFFFFF ; x4 = 0xFFFFF << 12 = 0xFFFFF000 (top 20 bits all 1 = -4096 signed)
addi x5, x4, 1 ; x5 = 0xFFFFF000 + 1 = 0xFFFFF001
