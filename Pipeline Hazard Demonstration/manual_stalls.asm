    lw   x1, 0(x10)      # I1: x1 = A
    nop                  # stall for no-forwarding pipeline
    lw   x2, 0(x11)      # I2: x2 = B
    nop                  # stall for next dependency

    # RAW hazard chain with explicit NOP stalls
    add  x3, x1, x2      # uses x1, x2
    nop
    add  x4, x3, x1      # uses x3
    nop
    add  x5, x4, x3      # uses x4, x3
    nop

    sw   x3, 0(x12)      # store x3 into C
    nop
    lw   x6, 0(x12)      # load C (depends on previous SW)
    nop
    add  x7, x6, x5      # uses x6 result of LW
    nop

    # Loop part (still RAW on x8).
    # If you want to be extra safe on the no-forwarding CPU,
    # you can also put NOPs between these adds:
    addi x8, x0, 0
    addi x9, x0, 10

loop:
    add  x8, x8, x3
    nop
    add  x8, x8, x4
    nop
    addi x9, x9, -1
    bne  x9, x0, loop
