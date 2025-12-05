# hazards_control_only.asm
# Control hazards only - Data hazards removed with NOPs
# This program demonstrates control hazards (branches) without data dependencies

.data
array: .word 1, 2, 3, 4, 5, 6, 7, 8, 9, 10

.text
.globl main

main:
    # Initialize registers with independent values
    li x5, 10           # Loop counter
    li x6, 0            # Initialize x6
    li x7, 0            # Initialize x7
    nop
    nop
    nop

loop:
    # Control hazard: branch instruction
    beq x5, x0, end     # Branch if counter reaches 0
    nop                 # Branch delay slot (control hazard)
    nop
    nop
    
    # Independent operations (no data hazards)
    addi x6, x0, 1      # x6 = 1
    nop
    nop
    nop
    
    addi x7, x0, 2      # x7 = 2 (independent of x6)
    nop
    nop
    nop
    
    addi x8, x0, 3      # x8 = 3 (independent of x6, x7)
    nop
    nop
    nop
    
    # Decrement counter
    addi x5, x5, -1     # x5 = x5 - 1
    nop
    nop
    nop
    
    # Control hazard: unconditional jump
    j loop              # Jump back to loop (control hazard)
    nop
    nop
    nop

end:
    # Conditional branch with control hazard
    li x10, 5
    nop
    nop
    nop
    
    li x11, 5
    nop
    nop
    nop
    
    beq x10, x11, finish  # Control hazard
    nop
    nop
    nop

finish:
    # Exit program
    li a7, 10           # Exit syscall
    ecall