.data
    dummy: .word 0

.text
.globl main

main:
    li s0, 4            # Outer Loop Limit (N=4)
    li s1, 4            # Inner Loop Limit (M=4)
    li t0, 0            # Outer Counter (i)
    li a0, 0            # Accumulator (Result)

outer_loop:
    beq t0, s0, end     # Exit outer if i == 4
    
    li t1, 0            # Reset Inner Counter (j=0)

inner_loop:
    beq t1, s1, inner_end # Exit inner if j == 4
    
    addi a0, a0, 1      # WORK: Do the math
    
    addi t1, t1, 1      # j++
    j inner_loop        # Jump back to start of inner

inner_end:
    addi t0, t0, 1      # i++
    j outer_loop        # Jump back to start of outer

end:
    nop