# Static Branch Prediction Analysis for Ripes

A comprehensive analysis of **static branch prediction strategies** using the [Ripes](https://github.com/mortbopet/Ripes) RISC-V simulator.

This project compares three static prediction schemes:
- **Always-Taken**
- **Always-Not-Taken**  
- **BTFNT (Backward Taken, Forward Not Taken)**

---

## 📁 Project Files

| File | Description |
|------|-------------|
| `branch_analysis.asm` | Test program with backward loop branch and forward conditional branch |

---

## 🎯 What This Demonstrates

- **Static branch prediction** strategies and their accuracy
- **Backward vs. Forward branches** and their typical behavior patterns
- **Misprediction analysis** with concrete branch outcome sequences
- **Performance impact** calculation using misprediction penalties

---

## 🔬 Understanding Static Prediction

Static predictors make predictions based on **compile-time information only** (no runtime history):

| Strategy | Rule | Rationale |
|----------|------|-----------|
| **Always-Taken** | Predict all branches as taken | Simple, works for loops |
| **Always-Not-Taken** | Predict all branches as not taken | Simple, works for error checks |
| **BTFNT** | Backward=Taken, Forward=Not Taken | Loops go backward (taken), conditionals go forward (often not taken) |

---

## 📝 Assembly Code

This program contains two distinct branch types for comprehensive analysis:

1. **B1**: Backward loop branch (mostly taken)
2. **B2**: Forward conditional branch (rarely/never taken)

```asm
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
```

---

## 🔧 Ripes Setup Instructions

### Step 1: Load the Program

1. Open **Ripes** (or [ripes.me](https://ripes.me))
2. In the **Editor** tab, set **`Input type: Assembly`**
3. Paste the code above
4. Click the **hammer icon** (Assemble) to build

### Step 2: Select Processor

1. Go to the **Processor** tab
2. Click the **CPU/chip icon** (Select processor)
3. Choose: **`RISC-V 5-Stage Processor`** (with hazard detection + forwarding)
4. Click **Reset** (circular arrow icon)

> **Note:** For this analysis, we focus on **branch outcome sequences**, not the hardware predictor. The static strategies are analyzed **theoretically** based on observed branch behavior.

### Step 3: Run the Program

1. In the **Program** view, set a **breakpoint** at the `end:` label
2. Open **Registers** pane (to verify x5, x6, x7, x8, x9, x14)
3. Open **Statistics** pane (for cycle/instruction counts)
4. Click **Run** – execution stops at `end:`

---

## ✅ Expected Output

With **N = 10**, **X = 3**:

### Register Values

| Register | Value | Description |
|----------|-------|-------------|
| `x5` | 10 | N (loop bound) |
| `x6` | 3 | X (comparison value) |
| `x7` | 10 | i = N at loop exit |
| `x8` | 45 | sum(0..9) = 0+1+...+9 |
| `x9` | 1 | Branch B2 NOT taken (fall-through executed) |
| `x14` | 0 | Branch B2 taken path never executed |

### Memory Values

| Label | Value | Description |
|-------|-------|-------------|
| `SUM1` | 45 | Sum of 0..N-1 |
| `FWD_RES` | 1 | Indicates fall-through path was taken |

### Verification Formula

$$\text{SUM1} = \sum_{i=0}^{N-1} i = \frac{(N-1) \times N}{2} = \frac{9 \times 10}{2} = 45$$

---

## 📊 Branch Behavior Analysis

### Branch B1: Backward Loop Branch

**Instruction:** `blt x7, x5, loop1` (if i < N goto loop1)

**Target:** `loop1` is **above** (backward branch)

For N = 10, the branch executes 10 times:

| Execution | i (x7) | Condition (i < 10) | Result |
|-----------|--------|-------------------|--------|
| 1 | 1 | 1 < 10 = TRUE | **TAKEN** |
| 2 | 2 | 2 < 10 = TRUE | **TAKEN** |
| 3 | 3 | 3 < 10 = TRUE | **TAKEN** |
| 4 | 4 | 4 < 10 = TRUE | **TAKEN** |
| 5 | 5 | 5 < 10 = TRUE | **TAKEN** |
| 6 | 6 | 6 < 10 = TRUE | **TAKEN** |
| 7 | 7 | 7 < 10 = TRUE | **TAKEN** |
| 8 | 8 | 8 < 10 = TRUE | **TAKEN** |
| 9 | 9 | 9 < 10 = TRUE | **TAKEN** |
| 10 | 10 | 10 < 10 = FALSE | **NOT TAKEN** |

**Pattern for B1:** `T T T T T T T T T N`

| Metric | Value |
|--------|-------|
| Total Executions | 10 |
| Taken | 9 |
| Not Taken | 1 |
| Branch Direction | **Backward** |

---

### Branch B2: Forward Conditional Branch

**Instruction:** `blt x5, x6, branch_taken` (if N < X goto branch_taken)

**Target:** `branch_taken` is **below** (forward branch)

With N = 10, X = 3:
- Condition: 10 < 3 = **FALSE**
- Executed **once**, **NOT TAKEN**

**Pattern for B2:** `N`

| Metric | Value |
|--------|-------|
| Total Executions | 1 |
| Taken | 0 |
| Not Taken | 1 |
| Branch Direction | **Forward** |

---

## 📈 Static Predictor Comparison

### Branch B1 Analysis (Backward Loop)

Actual pattern: `T T T T T T T T T N` (9 Taken, 1 Not Taken)

| Predictor | Prediction | Correct | Mispredictions | Accuracy |
|-----------|------------|---------|----------------|----------|
| **Always-Taken** | All T | 9 | 1 | 90% |
| **Always-Not-Taken** | All N | 1 | 9 | 10% |
| **BTFNT** | T (backward) | 9 | 1 | 90% |

### Branch B2 Analysis (Forward Conditional)

Actual pattern: `N` (0 Taken, 1 Not Taken)

| Predictor | Prediction | Correct | Mispredictions | Accuracy |
|-----------|------------|---------|----------------|----------|
| **Always-Taken** | T | 0 | 1 | 0% |
| **Always-Not-Taken** | N | 1 | 0 | 100% |
| **BTFNT** | N (forward) | 1 | 0 | 100% |

### Combined Results (B1 + B2)

| Predictor | Total Correct | Total Mispredictions | Overall Accuracy |
|-----------|---------------|---------------------|------------------|
| **Always-Taken** | 9 | 2 | 81.8% (9/11) |
| **Always-Not-Taken** | 2 | 9 | 18.2% (2/11) |
| **BTFNT** | 10 | 1 | **90.9%** (10/11) |

---

## 🔢 Performance Impact Calculation

### Misprediction Penalty

In a classic 5-stage RISC-V pipeline (branch resolved in EX stage):

$$\text{Penalty} = 2 \text{ cycles per misprediction}$$

### Extra Cycles Calculation

$$\text{Extra Cycles} = \text{Mispredictions} \times \text{Penalty}$$

| Predictor | Mispredictions | Extra Cycles |
|-----------|----------------|--------------|
| **Always-Taken** | 2 | 4 cycles |
| **Always-Not-Taken** | 9 | 18 cycles |
| **BTFNT** | 1 | **2 cycles** |

### Relative Performance

$$\text{Speedup}_{\text{BTFNT vs Not-Taken}} = \frac{18}{2} = 9\times \text{ fewer penalty cycles}$$

---

## 🧠 Why BTFNT Works

### Backward Branches (Loops)

```
loop:
    ; loop body
    blt x7, x5, loop    ← Branch target is ABOVE (backward)
```

- Loops iterate many times before exiting
- **Taken** probability is high (N-1 out of N iterations)
- BTFNT predicts **Taken** → High accuracy

### Forward Branches (Conditionals)

```
    blt x5, x6, error_handler    ← Branch target is BELOW (forward)
    ; normal path
error_handler:
    ; rarely executed
```

- Error checks, boundary conditions are rarely triggered
- **Not Taken** probability is typically high
- BTFNT predicts **Not Taken** → High accuracy

---

## 📋 Lab Report Template

### Aim
To analyze and compare static branch prediction strategies (Always-Taken, Always-Not-Taken, BTFNT) using branch outcome patterns.

### Theory
Static branch predictors use compile-time information to guess branch direction:
- **Always-Taken**: Assumes all branches jump to target
- **Always-Not-Taken**: Assumes all branches fall through
- **BTFNT**: Uses branch direction (backward=taken, forward=not taken)

### Apparatus
- Ripes RISC-V Simulator
- Test program with backward and forward branches

### Procedure
1. Load and run the assembly program in Ripes
2. Verify correct execution (SUM1=45, FWD_RES=1)
3. Analyze branch outcome patterns for B1 and B2
4. Calculate prediction accuracy for each strategy
5. Compute performance impact using misprediction penalty

### Observations

#### Branch Outcome Patterns

| Branch | Direction | Pattern | Taken | Not Taken |
|--------|-----------|---------|-------|-----------|
| B1 | Backward | T T T T T T T T T N | 9 | 1 |
| B2 | Forward | N | 0 | 1 |

#### Prediction Accuracy

| Predictor | B1 Correct | B2 Correct | Total Accuracy |
|-----------|------------|------------|----------------|
| Always-Taken | 9/10 | 0/1 | ___% |
| Always-Not-Taken | 1/10 | 1/1 | ___% |
| BTFNT | 9/10 | 1/1 | ___% |

#### Performance Impact (Penalty = 2 cycles)

| Predictor | Mispredictions | Extra Cycles |
|-----------|----------------|--------------|
| Always-Taken | ___ | ___ |
| Always-Not-Taken | ___ | ___ |
| BTFNT | ___ | ___ |

### Result
BTFNT provides the best accuracy (___%) with only ___ misprediction(s) and ___ extra penalty cycles.

### Discussion
1. Backward branches (loops) favor Always-Taken and BTFNT
2. Forward branches (conditionals) favor Always-Not-Taken and BTFNT
3. BTFNT combines the strengths of both strategies
4. Dynamic predictors can further improve accuracy by learning runtime patterns

---

## 🚀 Extensions

Try these variations to deepen your understanding:

### 1. Change Loop Iterations
```asm
N: .word 100    # Larger loop → more pronounced differences
```

### 2. Make Forward Branch Taken
```asm
X: .word 20     # Now N < X is TRUE → B2 is taken
```

### 3. Add More Branch Types
- Nested loops (multiple backward branches)
- Switch statements (multiple forward branches)
- Function calls with conditional returns

### 4. Compare with Dynamic Prediction
Run on Ripes with different branch predictor settings (if available) and compare hardware vs. theoretical static prediction.

---

## 📚 Key Concepts

| Concept | Definition |
|---------|------------|
| **Static Prediction** | Prediction based on compile-time information only |
| **Backward Branch** | Target address is lower than branch instruction (loops) |
| **Forward Branch** | Target address is higher than branch instruction (conditionals) |
| **BTFNT** | Backward Taken, Forward Not Taken - exploits typical branch patterns |
| **Misprediction Penalty** | Cycles wasted when prediction is wrong |
| **Branch Resolution** | Pipeline stage where branch outcome is determined |

---

## 📚 References

- [Ripes GitHub Repository](https://github.com/mortbopet/Ripes)
- [RISC-V Specification](https://riscv.org/specifications/)
- [Classic RISC Pipeline - Wikipedia](https://en.wikipedia.org/wiki/Classic_RISC_pipeline)
- [Branch Prediction with Visualization for RISC-V](https://wiki.control.fel.cvut.cz/mediawiki/images/9/99/Dp_2024_stefan_jiri.pdf)
- Patterson & Hennessy, *Computer Organization and Design*

---

## 📄 License

This educational material is provided for learning purposes. Feel free to use and modify for your coursework and labs.
