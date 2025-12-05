.data
    dummy: .word 0

.text
.globl main

main:
    li s0, 16           # Single Loop Limit (Total=16)
    li t0, 0            # Counter (k)
    li a0, 0            # Accumulator (Result)

flat_loop:
    beq t0, s0, end     # Exit if k == 16
    
    addi a0, a0, 1      # WORK: Do the math
    
    addi t0, t0, 1      # k++
    j flat_loop         # Jump back

end:
    nop