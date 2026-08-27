# Prime Sieve of Eratosthenes -> UART Demo
# Computes all primes from 2 to 100 using the Sieve of Eratosthenes and
# prints each one in decimal (followed by CR/LF) over the memory-mapped
# UART peripheral at address 0xFFFFFFF0 (-16). This core is RV32I only
# (no M extension), so all multiplication is done with a repeated-addition
# subroutine and all decimal conversion is done with repeated subtraction.
#
# Memory map used in dmem:
#   byte addresses 0..100  -> sieve[0..100], 1 = "still prime", 0 = "composite"
#
# Register map:
#   x1  = ra (link register for all jal/jalr calls)
#   x2  = constant 100 (sieve limit N, also used as the "hundreds" divisor)
#   x3  = i (loop counter, reused across phases)
#   x4  = j (sieve inner-loop counter)
#   x5  = scratch
#   x6  = DELAY's internal cycle counter (only ever touched inside DELAY)
#   x7  = UART_ADDR (-16)
#   x12 = N+1 (loop bound, = 101)
#   x13,x14 = MUL_FUNC operands a,b
#   x15 = MUL_FUNC result / i*i
#   x16 = MUL_FUNC internal counter
#   x20 = argument to PRINT_NUMBER
#   x21 = hundreds digit
#   x22 = remaining value during digit extraction / units digit at the end
#   x23 = tens digit
#   x24 = ASCII scratch
#   x26 = constant 10
#   x28 = PRINT_NUMBER's saved return address

# ---- Setup ----
addi x2, x0, 100        # x2 = 100  (N, and the "hundreds" constant)
addi x26, x0, 10        # x26 = 10  (the "tens" constant)
addi x7, x0, -16        # x7 = UART_ADDR (0xFFFFFFF0)
addi x12, x2, 1          # x12 = N + 1 = 101 (inclusive loop bound)

# ---- Initialize sieve[0..100] = 1 ----
addi x5, x0, 1           # x5 = 1 (the "prime" flag)
addi x3, x0, 0            # i = 0
INIT_LOOP:
sb x5, 0(x3)               # sieve[i] = 1
addi x3, x3, 1
blt x3, x12, INIT_LOOP

sb x0, 0(x0)              # sieve[0] = 0 (not prime)
sb x0, 1(x0)              # sieve[1] = 0 (not prime)

# ---- Sieve of Eratosthenes ----
addi x3, x0, 2             # i = 2
SIEVE_OUTER:
add x13, x3, x0            # a = i
add x14, x3, x0            # b = i
jal x1, MUL_FUNC             # x15 = i*i
blt x2, x15, SIEVE_OUTER_DONE  # if N < i*i, stop (i*i > N)

lbu x5, 0(x3)                # x5 = sieve[i]
beq x5, x0, SIEVE_OUTER_NEXT # if not prime, skip marking

add x4, x15, x0              # j = i*i
SIEVE_INNER:
blt x2, x4, SIEVE_INNER_DONE  # if N < j, done marking this i
sb x0, 0(x4)                    # sieve[j] = 0
add x4, x4, x3                  # j += i
jal x0, SIEVE_INNER
SIEVE_INNER_DONE:

SIEVE_OUTER_NEXT:
addi x3, x3, 1
jal x0, SIEVE_OUTER
SIEVE_OUTER_DONE:

# ---- Print every remaining prime, each followed by CR LF ----
addi x3, x0, 2               # i = 2
PRINT_OUTER:
bge x3, x12, PRINT_DONE       # loop while i <= N
lbu x5, 0(x3)
beq x5, x0, PRINT_NEXT          # not prime, skip

add x20, x3, x0                 # arg for PRINT_NUMBER
jal x1, PRINT_NUMBER

addi x24, x0, 13                # '\r'
sw x24, 0(x7)
jal x1, DELAY
addi x24, x0, 10                 # '\n'
sw x24, 0(x7)
jal x1, DELAY

PRINT_NEXT:
addi x3, x3, 1
jal x0, PRINT_OUTER
PRINT_DONE:

# ---- Done: spin forever ----
HALT:
jal x0, HALT

# =====================================================================
# Subroutines (only reached via jal/jalr, never by fall-through)
# =====================================================================

# MUL_FUNC: x15 = x13 * x14 (repeated addition, no RV32M needed).
# Clobbers x15, x16. Leaf routine - safe to call with a plain jal x1.
MUL_FUNC:
addi x15, x0, 0
addi x16, x0, 0
MUL_LOOP:
beq x16, x14, MUL_DONE
add x15, x15, x13
addi x16, x16, 1
jal x0, MUL_LOOP
MUL_DONE:
jalr x0, 0(x1)

# DELAY: burns ~131,000 cycles (~1.3ms @ 100MHz) so the UART has time
# to finish shifting out the previous byte before the next write.
# Leaf routine - safe to call with a plain jal x1.
DELAY:
lui x6, 0x20
DELAY_LOOP:
addi x6, x6, -1
bne x6, x0, DELAY_LOOP
jalr x0, 0(x1)

# PRINT_NUMBER: prints x20 (0-999) in decimal with leading zeros
# suppressed, no trailing characters. Calls DELAY internally (which
# uses x1), so it saves/restores its own return address in x28.
PRINT_NUMBER:
add x28, x1, x0              # save our return address

addi x21, x0, 0                # hundreds digit = 0
add x22, x20, x0               # remaining = number
H_LOOP:
blt x22, x2, H_DONE
sub x22, x22, x2
addi x21, x21, 1
jal x0, H_LOOP
H_DONE:

addi x23, x0, 0                 # tens digit = 0
T_LOOP:
blt x22, x26, T_DONE
sub x22, x22, x26
addi x23, x23, 1
jal x0, T_LOOP
T_DONE:
                                  # x22 is now the units digit

beq x21, x0, SKIP_HUNDRED
addi x24, x21, 48                 # ASCII '0'-'9'
sw x24, 0(x7)
jal x1, DELAY
SKIP_HUNDRED:

bne x21, x0, PRINT_TENS_FORCE     # hundreds printed -> tens is mandatory
beq x23, x0, SKIP_TENS
PRINT_TENS_FORCE:
addi x24, x23, 48
sw x24, 0(x7)
jal x1, DELAY
SKIP_TENS:

addi x24, x22, 48                  # units digit always prints
sw x24, 0(x7)
jal x1, DELAY

jalr x0, 0(x28)                    # return to caller
