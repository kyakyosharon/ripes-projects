#######################################################
# Pipeline RAW Hazard Demo for Ripes (RV32I)
# - Demonstrates RAW hazards on:
#   * ALU-ALU dependencies
#   * LOAD -> ALU dependency (load-use hazard)
# - Works with:
#   * 5-stage w/o forwarding/hazard (needs NOPs, see below)
#   * 5-stage with hazard detection + forwarding (no NOPs needed)
#######################################################

    .data
A:  .word 5          # A = 5
B:  .word 7          # B = 7
C:  .word 0          # will store A+B here

    .text
    .globl _start
_start:
    ###################################################
    # 1. Load operands (no hazards yet)
    ###################################################
    la   x10, A          # base address of A
    la   x11, B          # base address of B
    la   x12, C          # base address of C

    lw   x1, 0(x10)      # I1: x1 = A   (from memory)
    lw   x2, 0(x11)      # I2: x2 = B   (from memory)

    ###################################################
    # 2. RAW hazard chain (ALU -> ALU)
    # These 3 adds are back-to-back and all dependent.
    # On a 5-stage pipeline:
    # * without forwarding, this sequence needs NOPs.
    # * with forwarding, no NOPs are needed.
    ###################################################
    add  x3, x1, x2      # I3: x3 = x1 + x2       (12)
    add  x4, x3, x1      # I4: x4 = x3 + x1       (17)
    add  x5, x4, x3      # I5: x5 = x4 + x3       (29)

    ###################################################
    # 3. LOAD -> USE hazard (classic load-use RAW)
    ###################################################
    sw   x3, 0(x12)      # I6: C = x3 (12)
    lw   x6, 0(x12)      # I7: x6 = C   (load just-written value!)
    add  x7, x6, x5      # I8: x7 = x6 + x5  (12 + 29 = 41)
                         #     RAW: depends on LW result of I7

    ###################################################
    # 4. Loop with many RAW hazards (for CPI comparison)
    # x8 accumulates (x3 + x4) 10 times:
    #   each iteration:
    #     x8 = x8 + x3
    #     x8 = x8 + x4
    # RAW hazards on x8 every cycle.
    ###################################################
    addi x8, x0, 0       # I9 : x8 = 0
    addi x9, x0, 10      # I10: loop counter = 10

loop:
    add  x8, x8, x3      # I11: RAW on x8 (uses previous x8)
    add  x8, x8, x4      # I12: RAW on x8 again
    addi x9, x9, -1      # I13: decrement loop counter
    bne  x9, x0, loop    # I14: branch if x9 != 0

    ###################################################
    # 5. End marker
    # Put a breakpoint on the 'end' label in Ripes.
    ###################################################
end:
    nop                  # I15: final instruction (safe to break here)
