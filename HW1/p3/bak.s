.globl __start

.rodata
    O_RDWR: .word 0b0000100
    msg1: .string "This is problem 3\n"
    msg2: .string " "
.text

__start:
  li a0, 4
  la a1, msg1
  ecall
  li a0, 13      # ecall code
  la a1, pattern
  lw a2, O_RDWR  # load O_RDWR open flag
  ecall
  # Load address of the input string into a0
  add a1, x0, a0
  li a0, 14      # ecall code
  li a2, 0x10200 # modify to a bigger number if your code is too long
  li a3, 94      # number of bytes to read
  ecall
  li a0, 16
  ecall
  addi t0, x0, 94
  add t1, x0, x0
Shift_ascii:
  add t3, t1, a2
  lb t2, 0(t3)
  addi t2, t2, -32
  add t3, t1, a2
  sb t2, 0(t3)
  addi t1, t1, 1
  bne t0, t1, Shift_ascii
  jal x0, your_function

Exit:
  li a0, 1
  add a1, x0, t0
  ecall
  beq t0, x0, Terminate
  li a0, 4
  la a1, msg2
  ecall
  li a0, 1
  add a1, x0, t1
  ecall
Terminate:
  addi a0, x0, 10
  ecall
################################################################################
# DO NOT MODIFY THE CODE ABOVE
################################################################################

.rodata
    pattern: .string "./pattern2.txt"
    # pattern: .string "../../{student id}_hw1/p3/pattern0.txt"
    # pattern: .string "../../{student id}_hw1/p3/pattern1.txt"
    # pattern: .string "../../{student id}_hw1/p3/pattern2.txt"
.text

# Write your main function here.
# a2(i.e.,x12) stores the heads address
# store whether there is cycle in t0
# store the entry point in t1
# go to Exit when your function is finish

your_function:
  li a3, 0x10300 # new array at a3
  addi s0, x0, 0x5e # s0 = 94
  addi s1, x0, 0
loop_1:
  beq s1, s0, Exit
  add a2, a2, s1
  lb t0, 0(a2)
  sub a2, a2, s1
  addi t1, x0, 0x00
  beq t0, t1, Exit
  addi t0, x0, 0
  jal x1, init # initialize a3[]
  addi t0, x0, 0
  addi t1, s1, 0
  jal x1, loop
  bne t0, x0, Exit
  addi s1, s1, 1
  beq x0, x0, loop_1
  jal x0, Exit

# loop:
#   bne t1, s0, cont
#   jalr x0, 0(x1)
loop:
  add a2, a2, t1
  lb t2, 0(a2)
  sub a2, a2, t1
  bne t2, s0, cont
  jalr x0, 0(x1)
cont:
  add a3, a3, t2
  lb t3, 0(a3)
  sub a3, a3, t2
  bne t3, x0, finish
  add a3, a3, t1
  addi t4, x0, 1
  sb t4, 0(a3)
  sub a3, a3, t1
  addi t1, t2, 0
  beq x0, x0, loop

finish:
  addi t0, t0, 1
  jalr x0, 0(x1)


init:
  beq t0, s0, exit
  add a3, a3, t0
  sb x0, 0(a3)
  sub a3, a3, t0
  addi t0, t0, 1
  beq x0, x0, init

exit:
  jalr x0, 0(x1)
