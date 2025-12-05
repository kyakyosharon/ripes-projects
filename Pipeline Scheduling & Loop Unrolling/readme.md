# Pipeline Scheduling & Loop Unrolling Demonstration for Ripes

A classic computer architecture experiment demonstrating **Pipeline Scheduling** and **Loop Unrolling** optimizations in the [Ripes](https://github.com/mortbopet/Ripes) RISC-V simulator.

This project uses **Vector Addition** ($C[i] = A[i] + B[i]$) to show how data dependencies cause **Load-Use Hazards** and how software optimizations can eliminate stalls.

---

## 📁 Project Files

| File | Description |
|------|-------------|
| `naive_loop.asm` | Baseline implementation - processes one element at a time (has Load-Use hazards) |
| `optimized_loop.asm` | Optimized implementation - 4x loop unrolling with instruction scheduling |

---

## 🎯 What This Demonstrates

- **Load-Use Hazards**: Pipeline stalls when loading a value and immediately using it
- **Loop Unrolling**: Processing multiple iterations per loop cycle to reduce overhead
- **Instruction Scheduling**: Reordering instructions to hide memory latency
- **Performance Comparison**: Measurable CPI improvement through optimization

---

## 🔧 Ripes Setup Instructions (Crucial)

### Step 1: Configure the Processor

1. Open **Ripes**
2. Click the **Processor Selection** icon (top left chip icon)
3. Select **RISC-V 32-bit**
4. Choose the layout: **5-Stage Processor** (Do NOT choose Single Cycle)

### Step 2: Enable Hazard Detection (Critical Setting)

| Processor Model | Behavior |
|-----------------|----------|
| `5-Stage Processor w/o Forwarding` | Full bubbles/stalls visible |
| `5-Stage Processor w/ Forwarding` | Stalls only for Load-Use hazards |

> **Recommendation:** Select **5-Stage Processor (w/ Forwarding)** for the most realistic modern scenario.

### Step 3: Run and Compare

1. Load `naive_loop.asm` first
2. Run to completion and record **Cycles** and **CPI** from the Statistics tab
3. Reset, then load `optimized_loop.asm`
4. Run and compare the metrics

---

## 📝 The Assembly Code

### Version A: Naive Loop (Baseline)

This code processes **one element at a time** and suffers from **Load-Use Hazards** because values are loaded and immediately used.

```asm
.data
    # Define two source arrays (A and B) and one destination array (C)
    # Size: 16 words (integers)
    arrayA: .word 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
    arrayB: .word 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160
    arrayC: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

.text
.globl main

main:
    la a0, arrayA       # Base address of A
    la a1, arrayB       # Base address of B
    la a2, arrayC       # Base address of C
    li t0, 16           # Loop count (N = 16)
    li t1, 0            # Iterator i = 0

loop:
    beq t1, t0, end     # If i == 16, exit
    
    lw t2, 0(a0)        # Load A[i]
    lw t3, 0(a1)        # Load B[i]
    
    # --- STALL HAPPENS HERE ---
    # The processor must wait for t3 to arrive from memory 
    # before the ADD can execute.
    
    add t4, t2, t3      # C[i] = A[i] + B[i]
    
    sw t4, 0(a2)        # Store C[i]
    
    addi a0, a0, 4      # Increment address A
    addi a1, a1, 4      # Increment address B
    addi a2, a2, 4      # Increment address C
    addi t1, t1, 1      # i++
    
    j loop

end:
    # End of program
    nop
```

**Problem:** The `add t4, t2, t3` instruction must wait for `t3` to arrive from memory, causing a pipeline stall.

---

### Version B: Loop Unrolling & Scheduling (Optimized)

This code performs **4 iterations at once** (Unroll Factor = 4). Instructions are "scheduled" by loading all data first, then doing the math. This fills the memory latency with other useful work.

```asm
.data
    arrayA: .word 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
    arrayB: .word 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160
    arrayC: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

.text
.globl main

main:
    la a0, arrayA
    la a1, arrayB
    la a2, arrayC
    li t0, 16           # Loop count
    li t1, 0

loop:
    beq t1, t0, end
    
    # --- PHASE 1: BURST LOADS (Fill the pipeline) ---
    # We load 4 items from A and 4 from B immediately.
    # While t2 is being loaded, the CPU processes the load for t3, etc.
    
    lw t2, 0(a0)        # Load A[i]
    lw t3, 4(a0)        # Load A[i+1]
    lw t4, 8(a0)        # Load A[i+2]
    lw t5, 12(a0)       # Load A[i+3]
    
    lw t6, 0(a1)        # Load B[i]
    lw a3, 4(a1)        # Load B[i+1]
    lw a4, 8(a1)        # Load B[i+2]
    lw a5, 12(a1)       # Load B[i+3]

    # --- PHASE 2: CALCULATIONS ---
    # By the time we get here, t2 and t6 are definitely ready.
    # No stalls required!
    
    add s1, t2, t6      # Sum 0
    add s2, t3, a3      # Sum 1
    add s3, t4, a4      # Sum 2
    add s4, t5, a5      # Sum 3

    # --- PHASE 3: BURST STORES ---
    sw s1, 0(a2)
    sw s2, 4(a2)
    sw s3, 8(a2)
    sw s4, 12(a2)

    # --- LOOP MAINTENANCE ---
    # Only done once every 4 items (Reduced overhead)
    addi a0, a0, 16     # Jump 4 words forward
    addi a1, a1, 16
    addi a2, a2, 16
    addi t1, t1, 4      # i += 4
    
    j loop

end:
    nop
```

**Key Optimizations:**
1. **Burst Loads**: Load 8 values before any computation
2. **Delayed Use**: By the time calculations begin, loaded values are ready
3. **Reduced Overhead**: Loop counter/branches execute only once per 4 elements

---

## ✅ Expected Output

### Functional Verification

Check the **Memory** tab in Ripes. Navigate to the address of `arrayC` (typically `0x10000080`).

**Expected Result:**
```
11, 22, 33, 44, 55, 66, 77, 88, 99, 110, 121, 132, 143, 154, 165, 176
```

Since: $1+10=11$, $2+20=22$, $3+30=33$, etc.

> ⚠️ **Both versions must produce this exact same memory state** - the optimization only affects performance, not correctness.

---

## 📊 Performance Comparison

Check the **Statistics** tab (bottom right of Ripes interface) after running each version.

### Expected Metrics (Approximation)

| Metric | Version A (Naive) | Version B (Optimized) | Reason |
|--------|-------------------|----------------------|--------|
| **Cycles** | ~160-200 | ~80-100 | Fewer loop iterations, fewer branches |
| **CPI** | 1.2 - 1.5 | ~1.0 | Stalls eliminated by instruction scheduling |
| **Stalls** | Frequent | Near Zero | Independent instructions fill the "Load Delay Slot" |

### Performance Improvement

$$\text{Speedup} = \frac{\text{Cycles}_{\text{naive}}}{\text{Cycles}_{\text{optimized}}} \approx 1.5\text{x} - 2\text{x}$$

---

## 🔍 How to Observe Pipeline Stalls

In **Version A (Naive Loop)**, you can visually see the stalls:

1. Go to the **Pipeline** view in Ripes
2. Locate the instruction `lw t3, 0(a1)`
3. Step forward once (single-step execution)
4. Observe:
   - The `add` instruction enters the pipeline
   - It gets **stuck in the ID (Decode) stage**
   - A **bubble (nop)** is inserted into the **EX (Execute) stage**

This bubble is the hardware protecting data integrity by stalling until the load completes.

### Pipeline Diagram (Naive Version)

```
Cycle:      1    2    3    4    5    6    7
lw t2:      IF   ID   EX   MEM  WB
lw t3:           IF   ID   EX   MEM  WB
add t4:               IF   ID   --   EX   MEM  WB  ← STALL (bubble inserted)
```

### Pipeline Diagram (Optimized Version)

```
Cycle:      1    2    3    4    5    6    7    8    9   10   11
lw t2:      IF   ID   EX   MEM  WB
lw t3:           IF   ID   EX   MEM  WB
lw t4:                IF   ID   EX   MEM  WB
lw t5:                     IF   ID   EX   MEM  WB
lw t6:                          IF   ID   EX   MEM  WB
...
add s1:                                   IF   ID   EX   MEM  WB  ← NO STALL!
```

By the time `add s1` executes, `t2` and `t6` have long since completed their loads.

---

## 🧪 Experiment Workflow

### Experiment 1: Measure Baseline Performance

1. Load `naive_loop.asm`
2. Select `5-Stage Processor w/ Forwarding`
3. Run to completion
4. Record: Cycles = ___, CPI = ___

### Experiment 2: Measure Optimized Performance

1. Reset the processor
2. Load `optimized_loop.asm`
3. Run to completion
4. Record: Cycles = ___, CPI = ___

### Experiment 3: Calculate Improvement

$$\text{Speedup} = \frac{\text{Cycles}_{\text{naive}}}{\text{Cycles}_{\text{optimized}}}$$

$$\text{CPI Reduction} = \text{CPI}_{\text{naive}} - \text{CPI}_{\text{optimized}}$$

---

## 📈 Why This Works

### Load-Use Hazard Problem

In a pipelined processor, a `lw` instruction doesn't have its result until the **MEM** stage. If the next instruction needs that value in **EX**, a stall is required:

```
lw  t3, 0(a1)    # Result available at end of cycle 4
add t4, t2, t3   # Needs t3 at beginning of cycle 3 → STALL!
```

### Solution: Instruction Scheduling

By inserting independent instructions between the load and its use, we "hide" the latency:

```
lw t2, 0(a0)     # Start loading t2
lw t3, 4(a0)     # Start loading t3 (t2 still loading)
lw t4, 8(a0)     # Start loading t4 (independent)
lw t5, 12(a0)    # Start loading t5 (independent)
lw t6, 0(a1)     # By now, t2 is ready!
...
add s1, t2, t6   # No stall - both t2 and t6 are ready
```

---

## 📚 Key Concepts

| Concept | Definition |
|---------|------------|
| **Load-Use Hazard** | A RAW hazard where a load instruction is immediately followed by an instruction that uses the loaded value |
| **Loop Unrolling** | Replicating loop body multiple times to reduce loop overhead and enable better scheduling |
| **Instruction Scheduling** | Reordering instructions to minimize stalls while maintaining correctness |
| **Pipeline Bubble** | A NOP inserted by hardware to resolve hazards |

---

## 🚀 Extensions

Want to see even more dramatic improvements? Try:

- **Floating-point operations** (`flw` and `fadd.s`) - higher latency makes scheduling even more beneficial
- **Larger unroll factors** (8x or 16x) - further reduces loop overhead
- **Different array sizes** - see how optimization scales

---

## 📚 References

- [Ripes GitHub Repository](https://github.com/mortbopet/Ripes)
- [RISC-V Specification](https://riscv.org/specifications/)
- Patterson & Hennessy, *Computer Organization and Design*

---

## 📄 License

This educational material is provided for learning purposes. Feel free to use and modify for your coursework and labs.
