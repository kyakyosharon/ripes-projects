###########################################################
# Static Branch Prediction Analysis in Ripes (RV32I)
#
# Branch B1: Backward loop branch (mostly taken)
#   - Pattern: T T T ... T N    (for N=10 → 9 taken, 1 not taken)
#
# Branch B2: Forward conditional branch (mostly NOT taken)
#   - Pattern: N                (never taken with current data)
#
# Use this to compare static predictors:
#   - Always-taken
#   - Always-not-taken
#   - BTFNT (Backward Taken, Forward Not Taken)
###########################################################

    .data
N:          .word 10        # Loop bound N (change to test other patterns)
X:          .word 3         # Value smaller than N, so condition N < X is false
SUM1:       .word 0         # Will hold sum of 0..N-1
FWD_RES:    .word 0         # Will hold a marker for B2 fall-through

    .text
    .globl _start
_start:
    #######################################################
    # Load data
    #######################################################
    la      x10, N          # x10 = &N
    la      x11, X          # x11 = &X
    la      x12, SUM1       # x12 = &SUM1
    la      x13, FWD_RES    # x13 = &FWD_RES

    lw      x5, 0(x10)      # x5 = N
    lw      x6, 0(x11)      # x6 = X

    #######################################################
    # Branch B1: Backward loop
    #   sum = 0 + 1 + ... + (N-1)
    #   i runs 0,1,...,N-1
    #   Branch pattern (for N=10): T T T T T T T T T N
    #######################################################
    addi    x7, x0, 0       # x7 = i = 0
    addi    x8, x0, 0       # x8 = sum = 0

loop1:
    add     x8, x8, x7      # sum += i
    addi    x7, x7, 1       # i++

    # B1: backward branch (target label 'loop1' is above)
    blt     x7, x5, loop1   # if (i < N) goto loop1

    # After loop1: x7 = N, x8 = sum(0..N-1)

    sw      x8, 0(x12)      # store SUM1 = x8

    #######################################################
    # Branch B2: Forward conditional branch
    #
    # Condition: if (N < X) then go to 'branch_taken'
    # With N=10, X=3 → N < X is FALSE → branch NOT taken
    # Pattern: N (never taken for these values)
    #######################################################
    addi    x9,  x0, 0      # x9  = 0  (will mark NOT-taken path)
    addi    x14, x0, 0      # x14 = 0  (would mark taken path)

    # B2: forward branch (target 'branch_taken' is below)
    blt     x5, x6, branch_taken   # if (N < X) goto branch_taken

    # Branch NOT taken (expected path)
    addi    x9, x9, 1              # x9 = 1 if branch falls through
    j       after_branch           # skip 'branch_taken'

branch_taken:
    # This part is never executed for N=10, X=3
    addi    x14, x14, 1            # x14 = 1 if branch taken

after_branch:
    sw      x9, 0(x13)             # FWD_RES = x9 (1 if fall-through executed)

    #######################################################
    # End marker
    #######################################################
end:
    nop                             # Put a breakpoint here in Ripes
