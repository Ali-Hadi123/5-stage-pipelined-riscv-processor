; Branch Instruction Test
; if every branch behaves correctly, x3 ends at 37.

addi x1, x0, 5 ; x1 = 5
addi x2, x0, 5 ; x2 = 5
addi x3, x0, 0 ; x3 = checksum, starts at 0

beq x1, x2, L1 ; 5 == 5 -> taken, skips next line
addi x3, x3, 100 ; should be SKIPPED
L1:
addi x3, x3, 1 ; x3 = 1

addi x4, x0, 7 ; x4 = 7 (not equal to x1)
bne x1, x4, L2 ; 5 != 7 -> taken, skips next line
addi x3, x3, 100 ; should be SKIPPED
L2:
addi x3, x3, 1 ; x3 = 2

beq x1, x4, L3 ; 5 != 7 -> NOT taken, next line runs
addi x3, x3, 1 ; x3 = 3
L3:
addi x3, x3, 10 ; x3 = 13 (always runs)

addi x5, x0, -1 ; x5 = -1 = 0xFFFFFFFF
blt x5, x1, L4 ; -1 < 5 (signed) -> taken, skips next line
addi x3, x3, 100 ; should be SKIPPED
L4:
addi x3, x3, 1 ; x3 = 14

bltu x5, x1, L5 ; 0xFFFFFFFF < 5 (unsigned) is false -> NOT taken, next line runs
addi x3, x3, 1 ; x3 = 15
L5:
addi x3, x3, 10 ; x3 = 25 (always runs)

bge x1, x5, L6 ; 5 >= -1 (signed) -> taken, skips next line
addi x3, x3, 100 ; should be SKIPPED
L6:
addi x3, x3, 1 ; x3 = 26

bgeu x1, x5, L7 ; 5 >= 0xFFFFFFFF (unsigned) is false -> NOT taken, next line runs
addi x3, x3, 1 ; x3 = 27
L7:
addi x3, x3, 10 ; x3 = 37
