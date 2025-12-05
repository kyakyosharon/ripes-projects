.data
    # LCG Parameters
seed:
    .word 42                # Initial seed X_0
multiplier:
    .word 1103515245        # a
increment:
    .word 12345             # c
mask:
    .word 0x7FFFFFFF        # m = 2^31 - 1 (approx; mask for lower 31 bits)

    # Data array: 1024 words (4096 bytes)
array_base:
    .zero 4096              # 1024 * 4 bytes

.text
.globl main
main:
    # Load base addresses
    la   s0, array_base     # s0 = base of data array
    la   s1, seed           # s1 = &seed

    # Load LCG state and parameters
    lw   t0, 0(s1)          # t0 = X_n (current seed)
    lw   t1, multiplier     # t1 = a
    lw   t2, increment      # t2 = c
    lw   t3, mask           # t3 = m mask (for modulo)

    li   t4, 100            # Perform 100 random accesses

random_loop:
    # --- LCG Step: X_(n+1) = (aX_n + c) mod m ---
    mul  t0, t0, t1         # t0 = a * X_n
    add  t0, t0, t2         # t0 = a * X_n + c
    and  t0, t0, t3         # t0 = (a * X_n + c) mod 2^31 (mask)

    # --- Scale random number to array index [0, 1023] ---
    andi t5, t0, 1023       # t5 = index (lower 10 bits)
    slli t5, t5, 2          # index * 4 -> byte offset (since word = 4 bytes)

    # --- Effective Address & Random Load ---
    add  t6, s0, t5         # t6 = &array_base[index]
    lw   zero, 0(t6)        # Perform the random load (value ignored)

    addi t4, t4, -1
    bnez t4, random_loop

    # Exit
    li   a7, 10
    ecall
