# Function Call Overhead Analysis - Inline Implementation
# This program demonstrates inline code execution without function calls

.data
    result: .word 0
    iterations: .word 1000

.text
.globl main

main:
    # Initialize registers
    li t0, 0              # Counter
    lw t1, iterations     # Load iteration count
    li t2, 0              # Accumulator for result
    
loop:
    # Inline computation (no function call overhead)
    # Simple arithmetic: result += (counter * 2) + 5
    slli t3, t0, 1        # t3 = counter * 2
    addi t3, t3, 5        # t3 = t3 + 5
    add t2, t2, t3        # accumulator += t3
    
    # Increment counter
    addi t0, t0, 1
    
    # Check loop condition
    blt t0, t1, loop
    
    # Store result
    la t4, result
    sw t2, 0(t4)
    
    # Exit program
    li a7, 10
    ecall