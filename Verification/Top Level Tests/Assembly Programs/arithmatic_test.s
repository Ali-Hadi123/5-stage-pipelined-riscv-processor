# ALU Operation Test:
addi x1, x0, 5 # x1 = 5
addi x2, x0, 3 # x2 = 3
add x3, x1, x2 # x3 = x1 + x2 = 8
sub x4, x1, x2 # x4 = x1 - x2 = 2
addi x5, x0, -1 # x5 = -1
and x6, x1, x5 # x6 = x1 & x5 = 5
or x7, x1, x2 # x7 = x1 | x2 = 7
xor x8, x1, x2 # x8 = x1 ^ x2 = 6
addi x9, x0, -10 # x9 = -10
slt x10, x9, x1 # x10 = (x9 < x1) signed = 1
slt x11, x1, x9 # x11 = (x1 < x9) signed = 0
sltu x12, x9, x1 # x12 = (x9 < x1) unsigned = 0
sltu x13, x1, x9 # x13 = (x1 < x9) unsigned = 1
addi x14, x0, 1 # x14 = 1
slli x15, x14, 4 # x15 = x14 << 4 = 16
addi x16, x0, 32 # x16 = 32
srli x17, x16, 2 # x17 = x16 >> 2 = 8
addi x18, x0, -8 # x18 = -8
srai x19, x18, 1 # x19 = x18 >>> 1 = -4
sll x20, x14, x2 # x20 = x14 << x2 (x2=3) = 8
srl x21, x16, x2 # x21 = x16 >> x2 (x2=3) = 4
sra x22, x18, x2 # x22 = x18 >>> x2 (x2=3) = -1
andi x23, x1, 1 # x23 = x1 & 1 = 1
ori x24, x1, 2 # x24 = x1 | 2 = 7
xori x25, x1, 5 # x25 = x1 ^ 5 = 0
slti x26, x9, 0 # x26 = (x9 < 0) signed = 1
sltiu x27, x9, 5 # x27 = (x9 < 5) unsigned = 0
