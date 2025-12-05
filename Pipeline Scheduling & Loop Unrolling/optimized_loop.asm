.data
    arrayA: .word 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
    arrayB: .word 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160
    arrayC: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

.text
.globl main

main:
    la a0, arrayA
    la a1, arrayB
    la a2, arrayC
    li t0, 16           # Loop count
    li t1, 0

loop:
    beq t1, t0, end
    
    # --- PHASE 1: BURST LOADS (Fill the pipeline) ---
    # We load 4 items from A and 4 from B immediately.
    # While t2 is being loaded, the CPU processes the load for t3, etc.
    
    lw t2, 0(a0)        # Load A[i]
    lw t3, 4(a0)        # Load A[i+1]
    lw t4, 8(a0)        # Load A[i+2]
    lw t5, 12(a0)       # Load A[i+3]
    
    lw t6, 0(a1)        # Load B[i]
    lw a3, 4(a1)        # Load B[i+1]
    lw a4, 8(a1)        # Load B[i+2]
    lw a5, 12(a1)       # Load B[i+3]

    # --- PHASE 2: CALCULATIONS ---
    # By the time we get here, t2 and t6 are definitely ready.
    # No stalls required!
    
    add s1, t2, t6      # Sum 0
    add s2, t3, a3      # Sum 1
    add s3, t4, a4      # Sum 2
    add s4, t5, a5      # Sum 3

    # --- PHASE 3: BURST STORES ---
    sw s1, 0(a2)
    sw s2, 4(a2)
    sw s3, 8(a2)
    sw s4, 12(a2)

    # --- LOOP MAINTENANCE ---
    # Only done once every 4 items (Reduced overhead)
    addi a0, a0, 16     # Jump 4 words forward
    addi a1, a1, 16
    addi a2, a2, 16
    addi t1, t1, 4      # i += 4
    
    j loop

end:
    nop