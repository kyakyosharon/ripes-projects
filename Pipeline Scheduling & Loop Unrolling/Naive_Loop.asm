.data
    # Define two source arrays (A and B) and one destination array (C)
    # Size: 16 words (integers)
    arrayA: .word 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
    arrayB: .word 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160
    arrayC: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

.text
.globl main

main:
    la a0, arrayA       # Base address of A
    la a1, arrayB       # Base address of B
    la a2, arrayC       # Base address of C
    li t0, 16           # Loop count (N = 16)
    li t1, 0            # Iterator i = 0

loop:
    beq t1, t0, end     # If i == 16, exit
    
    lw t2, 0(a0)        # Load A[i]
    lw t3, 0(a1)        # Load B[i]
    
    # --- STALL HAPPENS HERE ---
    # The processor must wait for t3 to arrive from memory 
    # before the ADD can execute.
    
    add t4, t2, t3      # C[i] = A[i] + B[i]
    
    sw t4, 0(a2)        # Store C[i]
    
    addi a0, a0, 4      # Increment address A
    addi a1, a1, 4      # Increment address B
    addi a2, a2, 4      # Increment address C
    addi t1, t1, 1      # i++
    
    j loop

end:
    # End of program
    nop