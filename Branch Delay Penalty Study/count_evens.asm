.data
    # 10 numbers: Mix of Odds and Evens
    # This forces the "Is it Even?" branch to switch behavior frequently
    array:  .word 12, 5, 8, 11, 20, 31, 42, 53, 60, 75 
    result: .word 0

.text
.globl main

main:
    la   a0, array      # Base address of array
    li   t0, 10         # Loop counter (N=10)
    li   t1, 0          # Current index (i)
    li   s0, 0          # Even number counter (Result)

loop:
    beq  t1, t0, end    # 1. LOOP EXIT BRANCH: Taken only once at the end
    
    lw   t2, 0(a0)      # Load array[i]
    
    # Check if Odd or Even
    andi t3, t2, 1      # Get Last Bit (1=Odd, 0=Even)
    
    # 2. CONDITIONAL BRANCH: "The Decision Maker"
    # If t3 != 0 (Odd), jump to 'skip'. 
    # If the predictor guesses wrong here, we lose 2-3 cycles!
    bne  t3, zero, skip 
    
    addi s0, s0, 1      # Increment Even Counter (Only if Even)

skip:
    addi a0, a0, 4      # Move array pointer
    addi t1, t1, 1      # i++
    
    # 3. UNCONDITIONAL JUMP (implicit loop back)
    j    loop           

end:
    la   a1, result
    sw   s0, 0(a1)      # Store result
    nop