############################################################
# Control vs Data Hazard Impact Study (RV32I, Ripes)
#
# - Data hazards:
#     A tight RAW chain on x1, x4, x5, x6 inside a loop
# - Control hazards:
#     A backward loop branch (blt x7, x21, loop)
#
# You will:
#   - Run this on Single-Cycle and 5-Stage pipeline
#   - Then run a "no data hazard" variant (explained below)
#   - Use the cycle counts to estimate % cycles lost to
#     data hazards vs control hazards.
############################################################

    .data
N:      .word 10        # Number of loop iterations
RES_X1: .word 0         # final value of x1 after loop
RES_X7: .word 0         # final loop counter (should be N)

    .text
    .globl _start
_start:
    # Load loop bound N into x21
    la    x20, N
    lw    x21, 0(x20)       # x21 = N

    # Initialize registers
    addi  x7,  x0, 0        # x7 = loop counter i = 0
    addi  x1,  x0, 1        # x1 = 1 (will be updated every iteration)
    addi  x2,  x0, 2        # constants for arithmetic
    addi  x3,  x0, 3
    addi  x9,  x0, 0        # independent counters (no RAW with x1,x4,x5,x6)
    addi  x10, x0, 0

############################################################
# Loop body:
#   - First part: RAW-heavy data dependence chain (data hazards)
#   - Second part: independent ALU work
#   - Third part: loop branch (control hazard)
############################################################
loop:
    # ---------- DATA HAZARD CHAIN (RAW) ----------
    add   x4, x1, x2        # D1: x4 = x1 + 2       (uses old x1)
    add   x5, x4, x3        # D2: x5 = x4 + 3       (RAW on x4)
    add   x6, x5, x4        # D3: x6 = x5 + x4      (RAW on x5, x4)
    add   x1, x6, x1        # D4: x1 = x6 + x1      (RAW on x6, x1)
                            # x1 carries value to next iteration

    # ---------- INDEPENDENT INSTRUCTIONS ----------
    addi  x9,  x9, 1        # independent from x1..x6
    addi  x10, x10, 2       # independent from x1..x6

    # ---------- CONTROL HAZARD: LOOP BRANCH ----------
    addi  x7, x7, 1         # i++
    blt   x7, x21, loop     # if (i < N) goto loop
                            # backward branch: taken N-1 times

after_loop:
    # Store results for checking in the Data view
    la    x22, RES_X1
    sw    x1, 0(x22)

    la    x23, RES_X7
    sw    x7, 0(x23)

end:
    nop                     # Put breakpoint here in Ripes
