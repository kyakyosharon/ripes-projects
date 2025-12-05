.data
    # 1024 words = 4096 bytes
    # Size chosen so random indexing in [0, 1023] is meaningful in the next experiment
array:
    .zero 4096

.text
.globl main
main:
    la   s0, array        # s0 = base of array
    li   t0, 1024         # Loop over 1024 elements (words)

seq_loop:
    lw   t1, 0(s0)        # Load array[i]
    addi s0, s0, 4        # Move to next word (i++)
    addi t0, t0, -1
    bnez t0, seq_loop

    li   a7, 10
    ecall
