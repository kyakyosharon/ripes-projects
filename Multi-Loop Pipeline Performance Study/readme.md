# Multi-Loop Pipeline Performance Study for Ripes

A comprehensive study of **Control Flow Efficiency** in pipelined processors using the [Ripes](https://github.com/mortbopet/Ripes) RISC-V simulator.

This project demonstrates how "complex control flow" (nested loops) hurts performance more than "simple control flow" (one long loop), even when the amount of computation is identical. The difference comes from **Branch Prediction Pollution** and instruction overhead.

---

## 📁 Project Files

| File | Description |
|------|-------------|
| `nested_loop.asm` | 4×4 nested loop structure (16 iterations total) |
| `flat_loop.asm` | Single flattened loop (16 iterations) |

---

## 🎯 What This Demonstrates

- **Control Flow Efficiency**: How loop structure affects performance
- **Branch Prediction Pollution**: Nested loops confuse predictors
- **Instruction Overhead**: Extra instructions for loop management
- **Loop Flattening**: Optimization technique to improve performance

---

## 🔬 Understanding the Problem

### Nested Loop Behavior

In a nested loop, the inner loop branch constantly changes direction:

```
Inner Loop Iteration: 1  2  3  4  (exit)  1  2  3  4  (exit)  ...
Branch Direction:     T  T  T  N         T  T  T  N        ...
                              ↑                   ↑
                         Misprediction!      Misprediction!
```

The predictor learns "Taken" but gets surprised when the loop exits. This happens **every time** the inner loop completes!

### Flattened Loop Behavior

In a single loop, the branch direction is predictable:

```
Loop Iteration: 1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 (exit)
Branch Direction: T  T  T  T  T  T  T  T  T  T  T  T  T  T  T  N
                                                               ↑
                                                    Only 1 misprediction!
```

The predictor learns "Taken" once and stays correct for 15 iterations.

---

## 🔧 Ripes Setup Instructions

### Step 1: Select Processor

1. Open **Ripes**
2. Click the **Processor Selection** icon
3. Select **RISC-V 32-bit**
4. Choose: **`5-Stage Processor (w/ Forwarding)`**

### Step 2: Configure Branch Predictor (Crucial!)

If your Ripes version allows selecting the predictor:

1. Click the **Branch Predictor** component in the processor diagram
2. Select **2-bit Saturating Counter**

**Why 2-bit?** A 2-bit predictor "learns" patterns. In a long loop, it learns quickly. In a nested loop, the inner loop constantly "resets," confusing the predictor.

### Step 3: Run Both Versions

1. Load `nested_loop.asm`, run to completion, record statistics
2. Reset, load `flat_loop.asm`, run to completion, record statistics
3. Compare the results

---

## 📝 Assembly Code

### Version A: Nested Loops (4×4)

**Structure:** Outer loop runs 4 times; Inner loop runs 4 times
**Total Work:** 16 additions
**Pipeline Stress:** High - inner loop branch changes direction frequently

```asm
.data
    dummy: .word 0

.text
.globl main

main:
    li s0, 4            # Outer Loop Limit (N=4)
    li s1, 4            # Inner Loop Limit (M=4)
    li t0, 0            # Outer Counter (i)
    li a0, 0            # Accumulator (Result)

outer_loop:
    beq t0, s0, end     # Exit outer if i == 4
    
    li t1, 0            # Reset Inner Counter (j=0)

inner_loop:
    beq t1, s1, inner_end # Exit inner if j == 4
    
    addi a0, a0, 1      # WORK: Do the math
    
    addi t1, t1, 1      # j++
    j inner_loop        # Jump back to start of inner

inner_end:
    addi t0, t0, 1      # i++
    j outer_loop        # Jump back to start of outer

end:
    nop
```

### Nested Loop Execution Flow

```
┌─────────────────────────────────────────────────────────────┐
│  OUTER LOOP (i=0)                                           │
│  ├── Reset j=0                                              │
│  ├── INNER LOOP: j=0→1→2→3→EXIT (Misprediction!)           │
│  └── i++                                                    │
├─────────────────────────────────────────────────────────────┤
│  OUTER LOOP (i=1)                                           │
│  ├── Reset j=0                                              │
│  ├── INNER LOOP: j=0→1→2→3→EXIT (Misprediction!)           │
│  └── i++                                                    │
├─────────────────────────────────────────────────────────────┤
│  ... (2 more outer iterations, each with misprediction)     │
└─────────────────────────────────────────────────────────────┘
Total Mispredictions: 4+ (one per inner loop exit)
```

---

### Version B: Flattened Loop (1×16)

**Structure:** Single loop running 16 times
**Total Work:** 16 additions (identical to Version A)
**Pipeline Stress:** Very low - branch is "Taken" 15 times in a row

```asm
.data
    dummy: .word 0

.text
.globl main

main:
    li s0, 16           # Single Loop Limit (Total=16)
    li t0, 0            # Counter (k)
    li a0, 0            # Accumulator (Result)

flat_loop:
    beq t0, s0, end     # Exit if k == 16
    
    addi a0, a0, 1      # WORK: Do the math
    
    addi t0, t0, 1      # k++
    j flat_loop         # Jump back

end:
    nop
```

### Flattened Loop Execution Flow

```
┌─────────────────────────────────────────────────────────────┐
│  SINGLE LOOP: k=0→1→2→3→4→5→6→7→8→9→10→11→12→13→14→15→EXIT │
│                                                       ↑     │
│                                          Only 1 misprediction│
└─────────────────────────────────────────────────────────────┘
Total Mispredictions: 1-2 (initial learning + final exit)
```

---

## ✅ Expected Output

### Functional Verification

Both versions compute the same result:

| Register | Value | Description |
|----------|-------|-------------|
| `a0` | 16 | Total additions performed |
| `t0` | 4 (nested) or 16 (flat) | Final counter value |

---

## 📊 Performance Comparison

### Statistics Tab Results

| Metric | Version A (Nested) | Version B (Flattened) | Difference |
|--------|-------------------|----------------------|------------|
| **Instructions Retired** | ~85 | ~68 | -17 (~20% fewer) |
| **Total Cycles** | ~110 | ~80 | -30 (~27% fewer) |
| **CPI** | Higher | Lower | Better |
| **Speedup** | Baseline | **~25-30% Faster** | |

### Instruction Count Breakdown

**Version A (Nested):**
- Setup: 4 instructions
- Per outer iteration: 3 instructions (reset j, check, increment)
- Per inner iteration: 4 instructions (check, work, increment, jump)
- Total: 4 + 4×(3 + 4×4) = ~85 instructions

**Version B (Flattened):**
- Setup: 3 instructions
- Per iteration: 4 instructions (check, work, increment, jump)
- Total: 3 + 16×4 = ~67 instructions

---

## 📈 Branch Prediction Analysis

### Version B (Flattened) - High Accuracy

```
Iteration:    1    2    3    4    5   ...  15   16
Actual:       T    T    T    T    T   ...   T    N
Predicted:    ?    T    T    T    T   ...   T    T
Result:      OK   OK   OK   OK   OK  ...  OK  MISS
```

- Branch taken 15 times, not taken 1 time
- Predictor learns "Taken" immediately
- **Mispredictions:** ~1-2 (initial + final exit)

### Version A (Nested) - Low Accuracy

**Inner loop (each of 4 times):**
```
j value:      1    2    3    4
Actual:       T    T    T    N
Predicted:    ?    T    T    T
Result:      OK   OK   OK  MISS  ← Flush!
```

- Inner loop exit causes misprediction **4 times** (once per outer iteration)
- Predictor re-learns "Taken" each time, then gets surprised
- **Mispredictions:** ~4+ (more than flattened)

### Misprediction Cost

Each misprediction costs **2 cycles** (pipeline flush):

| Version | Mispredictions | Penalty Cycles |
|---------|----------------|----------------|
| Nested | ~4-5 | ~8-10 cycles |
| Flattened | ~1-2 | ~2-4 cycles |
| **Difference** | ~3 more | ~6 extra cycles |

---

## 🔍 Visualizing Pipeline Flushes

### What Happens on Misprediction

```
Cycle:   1     2     3     4     5     6     7
beq:     IF    ID    EX   (wrong prediction detected!)
j inner:       IF    ID   [FLUSH]
addi:                IF   [FLUSH]
outer:                     IF    ID    EX    MEM   WB
                     ↑
            2 cycles wasted
```

### In Ripes

1. Set clock to **Manual** mode
2. Watch the inner loop exit (`beq t1, s1, inner_end`)
3. Observe the **RED** pipeline registers (flush signal)
4. Count the bubbles inserted

---

## 🧠 Why Nested Loops Hurt Performance

### 1. Instruction Overhead

Nested loops require extra instructions:

| Operation | Nested | Flattened |
|-----------|--------|-----------|
| Counter resets | 4 (`li t1, 0`) | 0 |
| Extra branches | 4 (inner exit) + 4 (outer) | 1 |
| Extra jumps | 8 (inner + outer) | 16 |
| **Total extra** | ~17 instructions | - |

### 2. Branch Prediction Pollution

The predictor "forgets" the pattern:

```
Inner Loop 1: Learn T→T→T→ (surprise! N) → FLUSH
Inner Loop 2: Re-learn T→T→T→ (surprise! N) → FLUSH
Inner Loop 3: Re-learn T→T→T→ (surprise! N) → FLUSH
Inner Loop 4: Re-learn T→T→T→ (surprise! N) → FLUSH
```

### 3. Pipeline Utilization

- **Nested:** Pipeline stalls frequently at inner loop exits
- **Flattened:** Pipeline runs smoothly with minimal interruption

---

## 🚀 Real-World Applications

### Matrix Multiplication Example

**Naive (Nested):**
```c
for (i = 0; i < N; i++)
    for (j = 0; j < N; j++)
        for (k = 0; k < N; k++)
            C[i][j] += A[i][k] * B[k][j];
```

**Optimized (Loop Tiling):**
```c
// Process in tiles to reduce branch overhead
for (ii = 0; ii < N; ii += TILE)
    for (jj = 0; jj < N; jj += TILE)
        for (kk = 0; kk < N; kk += TILE)
            // Inner loops run longer before exiting
```

### Loop Unrolling

Another technique to reduce branch overhead:

```asm
# Instead of:
loop:
    addi a0, a0, 1
    addi t0, t0, 1
    blt t0, s0, loop

# Use:
loop:
    addi a0, a0, 1    # Unrolled 4x
    addi a0, a0, 1
    addi a0, a0, 1
    addi a0, a0, 1
    addi t0, t0, 4
    blt t0, s0, loop
```

---

## 📋 Lab Report Template

### Aim
To study the impact of control flow complexity (nested vs. flattened loops) on pipeline performance.

### Theory
In pipelined processors, branch mispredictions cause pipeline flushes (2-cycle penalty). Nested loops cause frequent mispredictions because the inner loop exit direction changes predictably but frequently, confusing the branch predictor.

### Apparatus
- Ripes RISC-V Simulator
- Two test programs: nested loop and flattened loop

### Procedure
1. Run nested loop version, record Cycles and Instructions
2. Run flattened loop version, record Cycles and Instructions
3. Compare branch misprediction counts
4. Calculate speedup

### Observations

| Metric | Nested (4×4) | Flattened (1×16) |
|--------|--------------|------------------|
| Instructions | ___ | ___ |
| Cycles | ___ | ___ |
| CPI | ___ | ___ |
| Mispredictions | ___ | ___ |

### Result

$$\text{Speedup} = \frac{\text{Cycles}_{\text{nested}}}{\text{Cycles}_{\text{flat}}} = \_\_\_\times$$

$$\text{Instruction Reduction} = \frac{\text{Instr}_{\text{nested}} - \text{Instr}_{\text{flat}}}{\text{Instr}_{\text{nested}}} \times 100\% = \_\_\_\%$$

### Discussion
1. **Instruction overhead**: Nested loops require counter resets and extra jumps
2. **Branch pollution**: Inner loop exits cause repeated mispredictions
3. **Optimization**: Loop flattening, unrolling, and tiling reduce these penalties
4. **Trade-off**: Code complexity vs. performance

---

## 🧪 Extensions

### 1. Vary Loop Dimensions

Compare different configurations:

| Configuration | Cycles | Mispredictions |
|--------------|--------|----------------|
| 16×1 | ___ | ___ |
| 8×2 | ___ | ___ |
| 4×4 | ___ | ___ |
| 2×8 | ___ | ___ |
| 1×16 | ___ | ___ |

### 2. Triple Nested Loop

Add a third level:

```asm
outer:      # 2 iterations
  middle:   # 2 iterations
    inner:  # 4 iterations
```

### 3. Different Predictor Types

Compare with:
- Always Not Taken (static)
- 1-bit predictor
- 2-bit saturating counter

---

## 📚 Key Concepts

| Concept | Definition |
|---------|------------|
| **Control Flow** | The order in which instructions execute (branches, loops, jumps) |
| **Branch Prediction** | Hardware guess about branch direction before it's computed |
| **Prediction Pollution** | When branch patterns confuse the predictor |
| **Loop Flattening** | Converting nested loops to single loop |
| **Loop Unrolling** | Replicating loop body to reduce branch frequency |
| **Loop Tiling** | Processing data in blocks to improve locality |
| **Pipeline Flush** | Discarding speculatively executed instructions |

---

## 📚 References

- [Ripes GitHub Repository](https://github.com/mortbopet/Ripes)
- [RISC-V Specification](https://riscv.org/specifications/)
- Patterson & Hennessy, *Computer Organization and Design*
- Hennessy & Patterson, *Computer Architecture: A Quantitative Approach*

---

## 📄 License

This educational material is provided for learning purposes. Feel free to use and modify for your coursework and labs.
