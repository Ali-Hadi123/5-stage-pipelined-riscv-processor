# Prints "Hello! :)\r\n" over the memory-mapped UART peripheral at address 0xFFFFFFF0 (-16).

  addi x2, x0, -16        # x2 = 0xFFFFFFF0 (UART TX address)

  addi x5, x0, 72         # 'H'
  sw   x5, 0(x2)
  jal  x1, delay

  addi x5, x0, 101        # 'e'
  sw   x5, 0(x2)
  jal  x1, delay

  addi x5, x0, 108        # 'l'
  sw   x5, 0(x2)
  jal  x1, delay

  addi x5, x0, 108        # 'l'
  sw   x5, 0(x2)
  jal  x1, delay

  addi x5, x0, 111        # 'o'
  sw   x5, 0(x2)
  jal  x1, delay

  addi x5, x0, 33         # '!'
  sw   x5, 0(x2)
  jal  x1, delay

  addi x5, x0, 32         # ' '
  sw   x5, 0(x2)
  jal  x1, delay

  addi x5, x0, 58         # ':'
  sw   x5, 0(x2)
  jal  x1, delay

  addi x5, x0, 41         # ')'
  sw   x5, 0(x2)
  jal  x1, delay

  addi x5, x0, 13         # '\r'
  sw   x5, 0(x2)
  jal  x1, delay

  addi x5, x0, 10         # '\n'
  sw   x5, 0(x2)
  jal  x1, delay

halt:
  jal x0, halt            # spin forever until rst == 1'b1

# Burns roughly 131,000 cycles (~1.3ms @ 100MHz)
delay:
  lui x6, 0x20

delay_loop:
  addi x6, x6, -1
  bne  x6, x0, delay_loop
  jalr x0, 0(x1)           # return to caller