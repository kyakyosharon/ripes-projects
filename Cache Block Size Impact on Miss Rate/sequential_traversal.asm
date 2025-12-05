.data
    # Allocate a contiguous array of 128 words (512 bytes)
    # .zero 512 reserves 512 bytes initialized to 0
array:
    .zero 512    

.text
.globl main
main:
    la   s0, array        # s0 = base address of array
    li   t0, 128          # t0 = loop counter: 128 elements

traverse_loop:
    lw   t1, 0(s0)        # Load word at current address (sequential access)
    addi s0, s0, 4        # Move to next word (4 bytes)
    addi t0, t0, -1       # Decrement counter
    bnez t0, traverse_loop

    li   a7, 10
    ecall                 # Exit (semantics may vary in Ripes)
