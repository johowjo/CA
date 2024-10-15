.globl __start

.rodata
    msge: .string "\n "
    msg0: .string "This is HW1-1: Extended Euclidean Algorithm\n"
    msg1: .string "Enter a number for input x: "
    msg2: .string "Enter a number for input y: "
    msg3: .string "The result is:\n "
    msg4: .string "GCD: "
    msg5: .string "a: "
    msg6: .string "b: "
    msg7: .string "inv(x modulo y): "

.text
################################################################################
  # You may write function here
  #  x in a0, y in a1
    
    
################################################################################
__start:
  # Prints msg0
    addi a0, x0, 4
    la a1, msg0
    ecall

  # Prints msg1
    addi a0, x0, 4
    la a1, msg1
    ecall

  # Reads int1
    addi a0, x0, 5
    ecall
    add t0, x0, a0
    
  # Prints msg2
    addi a0, x0, 4
    la a1, msg2
    ecall
    
  # Reads int2
    addi a0, x0, 5
    ecall
    add a1, x0, a0
    add a0, x0, t0
    addi t0, x0, 0
    
################################################################################ 
  # You can do your main function here

  # a0 > a1
  # s5 = 0 if no swap, = 1 if swap
  addi s5, x0, 0
  add s6, x0, a1
  addi s7, x0, 1
  ble a0, a1, next 
  addi x28, a0, 0
  addi a0, a1, 0
  addi a1, x28, 0
  addi s5, x0, 1

next:
  addi s0, x0, 1
  addi s1, x0, 0
  addi s2, x0, 0
  addi s3, s0, 1

loop:
  beq a1, x0, exit
  # xori s5, s5, 1
  # s4 = a / b
  # handle a, b
  div s4, a0, a1
  mul x28, a1, s4
  sub x28, a0, x28
  addi a0, a1, 0
  addi a1, x28, 0
  # handle s
  mul x28, s1, s4
  sub x28, s0, x28
  addi s0, s1, 0
  addi s1, x28, 0
  # handle t
  mul x28, s3, s4
  sub x28, s2, x28
  addi s2, s3, 0
  addi s3, x28, 0
  beq x0, x0, loop

  


exit:
  addi s1, s0, 0
  addi s0, a0, 0
  addi s3, x0, 0
  bne s0, s7, result
  addi s3, s1, 0

loop2:
  bge s3 x0, result
  add s3, s3, s6
  beq x0, x0, loop2


result:
    addi t0,a0,0
  # Prints msg
    addi a0, x0, 4
    la a1, msg3
    ecall
    
    addi a0, x0, 4
    la a1, msg4
    ecall

  # Prints the result in s0
    addi a0, x0, 1
    add a1, x0, s0
    ecall
    
    addi a0, x0, 4
    la a1, msge
    ecall
    addi a0, x0, 4
    la a1, msg5
    ecall
    
  # Prints the result in s1
    addi a0, x0, 1
    add a1, x0, s1
    ecall
    
    addi a0, x0, 4
    la a1, msge
    ecall
    addi a0, x0, 4
    la a1, msg6
    ecall
    
  # Prints the result in s2
    addi a0, x0, 1
    add a1, x0, s2
    ecall
    
    addi a0, x0, 4
    la a1, msge
    ecall
    addi a0, x0, 4
    la a1, msg7
    ecall
    
  # Prints the result in s3
    addi a0, x0, 1
    add a1, x0, s3
    ecall
    
  # Ends the program with status code 0
    addi a0, x0, 10
    ecall
