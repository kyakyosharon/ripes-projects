.data
    .align 4                 # Force alignment for the base address
data_word:
    .word 0xDEADBEEF         # Stored at an address ending in ...00

.text
.globl main
main:
    la s0, data_word

    # -------------------------
    # 1. Aligned Load (Fast)
    # -------------------------
    lw t0, 0(s0)            # Correctly aligned (address ends in .00)

    # -------------------------
    # 2. Misaligned Load (Slow or Trap)
    # -------------------------
    addi s1, s0, 1          # Now address ends in .01 (misaligned)
    lw t1, 0(s1)            # Misaligned access!
    
    li a7, 10
    ecall
