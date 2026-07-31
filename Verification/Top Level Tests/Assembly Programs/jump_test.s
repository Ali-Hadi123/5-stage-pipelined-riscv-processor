; Jump Instruction Test
; x1 accumulates a checksum that results in 1101 if the program runs as intended.

addi x1, x0, 0 ; x1 = 0
jal x10, FUNC ; x10 = return address (addr of next instr), jump to FUNC
addi x1, x1, 1 ; (runs AFTER jalr returns here) x1 += 1
jal x0, DONE ; unconditional jump to DONE, discard link (rd = x0)

FUNC:
addi x1, x1, 100 ; x1 += 100 (proves FUNC body ran)
jalr x0, 0(x10) ; return to caller using saved address in x10

DONE:
addi x1, x1, 1000 ; x1 += 1000 (proves DONE was reached only once, at the end)
