# Fibonacci Sequence -> UART Demo
#
# Computes and prints the first 50 terms of the Fibonacci sequence
# (F(0)=0, F(1)=1, F(2)=1, F(3)=2, ...) over the memory-mapped UART
# peripheral at address 0xFFFFFFF0 (-16), one term per line (decimal,
# CR/LF terminated).
#
# This core is RV32I only (no M extension), and F(47..49) exceed 2^32-1
# (F(49) = 7,778,742,049), so this program:
#   - carries Fibonacci state as 64-bit values split across two 32-bit
#     registers (lo/hi), using unsigned-overflow-via-sltu for the carry
#     out of the low word on each add.
#   - converts to decimal using repeated subtraction of powers of ten
#     (no divide instruction available), same trick as PRINT_NUMBER in
#     prime_sieve_uart.s but generalized to 10 digit places (0..999,999,999)
#     with 64-bit-aware compare/subtract, since every power of ten needed
#     here (10^0..10^9) is itself < 2^32 (fits in the low word alone).
#
# Register map:
#   x1  = ra (link register for all jal/jalr calls)
#   x2  = UART_ADDR (-16)
#   x3  = i, current term index (0..49)
#   x4  = term count limit (50)
#   x5  = a_lo, x7  = a_hi   -> current term F(i), 64-bit (lo,hi)
#   x9  = b_lo, x11 = b_hi   -> next term F(i+1), 64-bit (lo,hi)
#   x12,x13,x14 = scratch for the 64-bit add (sum_lo, carry, sum_hi)
#   x20,x21 = argument to PRINT_U64 (val_lo, val_hi)
#   x24,x25 = PRINT_U64/DIGIT_EXTRACT's running remainder (lo,hi)
#   x26 = current power-of-ten divisor (argument to DIGIT_EXTRACT)
#   x27 = extracted digit (0-9), return value of DIGIT_EXTRACT
#   x28 = PRINT_U64's saved return address (it calls DIGIT_EXTRACT/DELAY,
#         both of which clobber x1, so PRINT_U64 can't rely on x1 to get
#         back to its own caller)
#   x29 = "started" flag - once a nonzero digit has printed, every
#         subsequent digit prints too (suppresses leading zeros)
#   x30 = ASCII scratch
#   x6  = DELAY's internal cycle counter (only ever touched inside DELAY -
#         never used for anything else, so it's safe for DELAY to clobber
#         it even when called from deep inside PRINT_U64/DIGIT_EXTRACT)

# ---- Setup ----
addi x2, x0, -16        # x2 = UART_ADDR (0xFFFFFFF0)
addi x3, x0, 0          # i = 0
addi x4, x0, 50         # print 50 terms total: F(0)..F(49)

addi x5, x0, 0          # a_lo = 0   } F(0) = 0
addi x7, x0, 0          # a_hi = 0   }
addi x9, x0, 1          # b_lo = 1   } F(1) = 1
addi x11, x0, 0         # b_hi = 0   }

MAIN_LOOP:
bge x3, x4, MAIN_DONE   # stop once i == 50

# ---- Print current term F(i) = (a_lo, a_hi) ----
add x20, x5, x0         # val_lo = a_lo
add x21, x7, x0         # val_hi = a_hi
jal x1, PRINT_U64

addi x30, x0, 13        # '\r'
sw x30, 0(x2)
jal x1, DELAY
addi x30, x0, 10        # '\n'
sw x30, 0(x2)
jal x1, DELAY

# ---- Advance: (a,b) <- (b, a+b), 64-bit ----
add x12, x5, x9         # sum_lo = a_lo + b_lo
sltu x13, x12, x5       # carry = 1 if sum_lo wrapped past 2^32
add x14, x7, x11        # sum_hi = a_hi + b_hi
add x14, x14, x13       #        + carry

add x5, x9, x0          # a_lo = b_lo (old)
add x7, x11, x0         # a_hi = b_hi (old)
add x9, x12, x0         # b_lo = sum_lo
add x11, x14, x0        # b_hi = sum_hi

addi x3, x3, 1
jal x0, MAIN_LOOP

MAIN_DONE:
HALT:
jal x0, HALT             # spin forever until rst == 1'b1

# =====================================================================
# Subroutines (only reached via jal/jalr, never by fall-through)
# =====================================================================

# DIGIT_EXTRACT: counts how many times the 64-bit value (x24 lo, x25 hi)
# can have the power-of-ten x26 (< 2^32, so its own "hi" is implicitly 0)
# subtracted from it, 0-9 times, returning the count in x27 and reducing
# (x24,x25) by that many multiples of x26 in place. Leaf routine (calls
# nothing) - safe to call with a plain jal x1, matching MUL_FUNC's
# pattern in prime_sieve_uart.s.
DIGIT_EXTRACT:
addi x27, x0, 0
DE_LOOP:
bne x25, x0, DE_SUB      # nonzero hi word -> remaining is >= 2^32 > x26, always safe to subtract
bltu x24, x26, DE_DONE   # hi==0 and lo < power -> can't subtract any more
DE_SUB:
sltu x30, x24, x26       # borrow = 1 if lo < power (borrowing from hi)
sub x24, x24, x26
sub x25, x25, x30
addi x27, x27, 1
jal x0, DE_LOOP
DE_DONE:
jalr x0, 0(x1)

# PRINT_U64: prints the 64-bit value (x20 lo, x21 hi) in decimal, with
# leading zeros suppressed (matching a value of exactly 0 printing as a
# single "0"), no trailing characters. Calls DIGIT_EXTRACT and DELAY
# internally (both of which use x1), so it saves/restores its own return
# address in x28 - same pattern as PRINT_NUMBER in prime_sieve_uart.s.
PRINT_U64:
add x28, x1, x0          # save our return address
add x24, x20, x0         # remaining_lo = val_lo
add x25, x21, x0         # remaining_hi = val_hi
addi x29, x0, 0          # started = false

li x26, 1000000000       # ---- digit: 10^9 ----
jal x1, DIGIT_EXTRACT
bne x27, x0, PU_D9_FORCE
beq x29, x0, PU_D9_SKIP
PU_D9_FORCE:
addi x30, x27, 48
sw x30, 0(x2)
jal x1, DELAY
addi x29, x0, 1
PU_D9_SKIP:

li x26, 100000000        # ---- digit: 10^8 ----
jal x1, DIGIT_EXTRACT
bne x27, x0, PU_D8_FORCE
beq x29, x0, PU_D8_SKIP
PU_D8_FORCE:
addi x30, x27, 48
sw x30, 0(x2)
jal x1, DELAY
addi x29, x0, 1
PU_D8_SKIP:

li x26, 10000000         # ---- digit: 10^7 ----
jal x1, DIGIT_EXTRACT
bne x27, x0, PU_D7_FORCE
beq x29, x0, PU_D7_SKIP
PU_D7_FORCE:
addi x30, x27, 48
sw x30, 0(x2)
jal x1, DELAY
addi x29, x0, 1
PU_D7_SKIP:

li x26, 1000000          # ---- digit: 10^6 ----
jal x1, DIGIT_EXTRACT
bne x27, x0, PU_D6_FORCE
beq x29, x0, PU_D6_SKIP
PU_D6_FORCE:
addi x30, x27, 48
sw x30, 0(x2)
jal x1, DELAY
addi x29, x0, 1
PU_D6_SKIP:

li x26, 100000           # ---- digit: 10^5 ----
jal x1, DIGIT_EXTRACT
bne x27, x0, PU_D5_FORCE
beq x29, x0, PU_D5_SKIP
PU_D5_FORCE:
addi x30, x27, 48
sw x30, 0(x2)
jal x1, DELAY
addi x29, x0, 1
PU_D5_SKIP:

li x26, 10000            # ---- digit: 10^4 ----
jal x1, DIGIT_EXTRACT
bne x27, x0, PU_D4_FORCE
beq x29, x0, PU_D4_SKIP
PU_D4_FORCE:
addi x30, x27, 48
sw x30, 0(x2)
jal x1, DELAY
addi x29, x0, 1
PU_D4_SKIP:

li x26, 1000             # ---- digit: 10^3 ----
jal x1, DIGIT_EXTRACT
bne x27, x0, PU_D3_FORCE
beq x29, x0, PU_D3_SKIP
PU_D3_FORCE:
addi x30, x27, 48
sw x30, 0(x2)
jal x1, DELAY
addi x29, x0, 1
PU_D3_SKIP:

li x26, 100              # ---- digit: 10^2 ----
jal x1, DIGIT_EXTRACT
bne x27, x0, PU_D2_FORCE
beq x29, x0, PU_D2_SKIP
PU_D2_FORCE:
addi x30, x27, 48
sw x30, 0(x2)
jal x1, DELAY
addi x29, x0, 1
PU_D2_SKIP:

li x26, 10               # ---- digit: 10^1 ----
jal x1, DIGIT_EXTRACT
bne x27, x0, PU_D1_FORCE
beq x29, x0, PU_D1_SKIP
PU_D1_FORCE:
addi x30, x27, 48
sw x30, 0(x2)
jal x1, DELAY
addi x29, x0, 1
PU_D1_SKIP:

li x26, 1                # ---- digit: 10^0 (units - always printed) ----
jal x1, DIGIT_EXTRACT
addi x30, x27, 48
sw x30, 0(x2)
jal x1, DELAY

jalr x0, 0(x28)          # return to caller

# DELAY: burns ~131,000 cycles (~1.3ms @ 100MHz) so the UART has time
# to finish shifting out the previous byte before the next write.
# Leaf routine - safe to call with a plain jal x1.
DELAY:
lui x6, 0x20
DELAY_LOOP:
addi x6, x6, -1
bne x6, x0, DELAY_LOOP
jalr x0, 0(x1)
