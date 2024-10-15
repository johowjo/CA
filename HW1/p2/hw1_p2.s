.globl __start

.rodata
    msg0: .string "This is HW1-2: Longest Substring without Repeating Characters\n"
    msg1: .string "Enter a string: "
    msg2: .string "Answer: "
.text

# Please use "result" to print out your final answer
################################################################################
# result function
# Usage: 
#     1. Store the beginning address in t4
#     2. Use "j print_char"
#     The function will print the string stored t4
#     When finish, the whole program will return value 0
result:
    addi a0, x0, 4
    la a1, msg2
    ecall
    
    add a1, x0, t4
    ecall
# Ends the program with status code 0
    addi a0, x0, 10
    ecall
################################################################################

__start:
# Prints msg
    addi a0, x0, 4
    la a1, msg0
    ecall
    
    la a1, msg1
    ecall
    
    addi a0, x0, 8
    
    li a1, 0x10200
    addi a2, x0, 2047
    ecall
# Load address of the input string into a0
    add a0, x0, a1

################################################################################
# DO NOT MODIFY THE CODE ABOVE
################################################################################  
# Write your main function here. 
# a0 stores the beginning address (66048(0x10200)) of the  Plaintext
  addi s0, x0, 0x00 # s0 is the enter character
  addi s1, x0, 0x80 # s1 is 128 
  addi s2, x0, 0 # s2 is the beginning position of the target substring
  addi s3, x0, 0 # s3 is the ending position of the target substring
  addi s4, x0, 0 # s4 is the length of the string
  addi s8, x0, 1 # s8 is 8
  li a2, 0x10300 # new array at a2

# count the length of the input string
count_length:
  mul t1, s4, s8
  add a0, a0, t1
  lb t2, 0(a0) # t2 is the character at index s4
  sub a0, a0, t1
  beq t2, s0, exit_1 
  # beq t2, t2, exit_1
  addi s4, s4, 1
  beq x0, x0, count_length

# print:
#   li a0, 4
#   mv a0, t2
#   ecall
#   jalr x0, 0(x1)

##############

# call exit_1 after counting length
exit_1:
  jal x1, clear
  addi t0, x0, 0
##### testing ######
  # mul t1, s4, s8
  # sub t1, t1, s8
  # add t4, a0, t1
  # beq x0, x0, result


loop_1:
  beq t0, s4, finish
  addi t1, t0, 0
  jal x1, loop_2
  sub t3, s3, s2 # length of current longest subtring
  sub t4, t1, t0 # length of this substring
  bge t3, t4, no_update
  addi s3, t1, 0
  addi s2, t0, 0
no_update:
  jal x1, clear
  addi t0, t0, 1
  addi t1, t0, 0
  beq x0, x0, loop_1



loop_2:
  beq t1, s4, exit_2
  add a0, a0, t1
  lb t2, 0(a0)
  sub a0, a0, t1
  add a2, a2, t2
  lb t3, 0(a2)
  sub a2, a2, t2
  addi t4, x0, 1
  beq t3, t4, exit_2
  add a2, a2, t2
  sb t4, 0(a2)
  sub a2, a2, t2
  addi t1, t1, 1
  beq x0, x0, loop_2
  ####################
  # addi t2, t1, 0
  # add a0, a0, t2
  # lb t3, 0(a0) # store s[t1] at t3
  # sub a0, a0, t2
  # mul t2, t3, s8
  # add a2, a2, t2
  # lb t3, 0(a2)
  # sub a2, a2, t2
  # addi t4, x0, 1
  # beq t3, t4, exit_2
  # add a2, a2, t2
  # sw t4, 0(a2)
  # sub a2, a2, t2
  # addi t1, t1, 1
  # beq x0, x0, loop_2
  

exit_2:
  jalr x0, 0(x1)

clear:
  addi t2, x0, 0

clear_dic:
  bne t2, s1, proceed
  jalr x0, 0(x1)
proceed:
  mul t4, t2, s8 
  add a2, a2, t4
  sb x0, 0(a2)
  sub a2, a2, t4
  addi t2, t2, 1
  beq x0, x0, clear_dic


finish:
  mul t2, s2, s8
  add a0, a0, s3
  sb s0, 0(a0)
  sub a0, a0, s3
  add t4, a0, t2
  beq x0, x0, result











