# Control vs Data Hazard Impact Study for Ripes

A comprehensive "put everything together" experiment that quantifies the **separate impacts of data hazards vs. control hazards** on pipeline performance using the [Ripes](https://github.com/mortbopet/Ripes) RISC-V simulator.

This project provides a methodology to measure what percentage of wasted cycles comes from RAW (Read-After-Write) data hazards versus branch-related control hazards.

---

## 📁 Project Files

| File | Description |
|------|-------------|
| `hazards_combined.asm` | Program with both data hazards AND control hazards |
| `hazards_control_only.asm` | Same control flow but data hazards removed (NOPs) |

---

## 🎯 What This Demonstrates

- **Data Hazards (RAW)**: Tight dependency chains requiring stalls/forwarding
- **Control Hazards**: Branch mispredictions causing pipeline flushes
- **Hazard Isolation**: Technique to measure each hazard type separately
- **Performance Analysis**: Calculate percentage of cycles wasted by each hazard type

---

## 🔬 Understanding the Methodology

### The Problem

Ripes doesn't directly tell you "this stall was data / this flush was branch." We need to **isolate** each hazard type through careful experimentation.

### The Solution

1. **Run 1**: Single-Cycle CPU (baseline, no pipeline hazards)
2. **Run 2**: 5-Stage CPU with full program (data + control hazards)
3. **Run 3**: 5-Stage CPU with data hazards removed (control hazards only)

By comparing these runs, we can calculate:
- Total hazard overhead
- Data hazard contribution
- Control hazard contribution

---

## 🔧 Ripes Setup Instructions

### Common Settings

1. Open **Ripes** (or [ripes.me](https://ripes.me))
2. Go to the **Editor** tab
3. Set **Input type: Assembly (RISC-V)**
4. Paste the code (see below)
5. Click the **hammer icon** (Assemble)

In the **Processor** tab, open:
- **Registers** panel
- **Statistics** panel (for Cycles and Instructions)

Set a **breakpoint** on the `nop` at the `end:` label.

---

## 📝 Assembly Code: Full Hazards Version

This program has **both data hazards AND control hazards**:

```asm
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
```

### Data Hazard Chain Visualization

```
     x1 (from previous iteration)
      │
      ▼
    ┌───┐
    │D1 │ add x4, x1, x2    →  x4
    └───┘                       │
                                ▼
                            ┌───┐
                            │D2 │ add x5, x4, x3    →  x5
                            └───┘                       │
                                        ┌───────────────┘
                                        ▼
                                    ┌───┐
                                    │D3 │ add x6, x5, x4  →  x6
                                    └───┘                     │
                                              ┌───────────────┘
                                              ▼
                                          ┌───┐
                                          │D4 │ add x1, x6, x1  →  x1 (next iteration)
                                          └───┘
```

Every instruction depends on the previous one → **maximum data hazard stress!**

---

## 📝 Assembly Code: Control Hazards Only Version

Same program but with data hazards **removed** (replaced with NOPs):

```asm
############################################################
# Control Hazard Only Version
# Same control flow, but RAW chain replaced with NOPs
############################################################

    .data
N:      .word 10
RES_X1: .word 0
RES_X7: .word 0

    .text
    .globl _start
_start:
    la    x20, N
    lw    x21, 0(x20)

    addi  x7,  x0, 0
    addi  x1,  x0, 1
    addi  x2,  x0, 2
    addi  x3,  x0, 3
    addi  x9,  x0, 0
    addi  x10, x0, 0

loop:
    # ---------- NO DATA HAZARDS (NOPs instead) ----------
    nop                     # 4 NOPs preserve instruction count
    nop                     # but create NO RAW dependencies
    nop
    nop

    # ---------- INDEPENDENT INSTRUCTIONS ----------
    addi  x9,  x9, 1
    addi  x10, x10, 2

    # ---------- CONTROL HAZARD: LOOP BRANCH ----------
    addi  x7, x7, 1
    blt   x7, x21, loop     # Same branch as before

after_loop:
    la    x22, RES_X1
    sw    x1, 0(x22)

    la    x23, RES_X7
    sw    x7, 0(x23)

end:
    nop
```

**Key Point:** Both versions have:
- Same number of instructions in the loop
- Same control flow (same branch)
- **Different data dependencies** (RAW chain vs. NOPs)

---

## 🧪 Experiment Procedure

### Run 1: Single-Cycle CPU (Baseline)

1. Select **`RISC-V Single Cycle Processor`**
2. Load the **full hazards version**
3. Run to completion
4. Record:
   - `Cycles_SC` = ___
   - `Instructions_SC` = ___

This is your "ideal, no pipeline hazard" reference.

### Run 2: 5-Stage CPU with Full Hazards

1. Select **`RISC-V 5-Stage Processor`**
2. Load the **full hazards version**
3. Run to completion
4. Record:
   - `Cycles_5_full` = ___
   - `Instructions_5_full` = ___

This includes **both data + control hazards**.

### Run 3: 5-Stage CPU with Control Hazards Only

1. Keep **`RISC-V 5-Stage Processor`**
2. Load the **control hazards only version** (NOPs)
3. Run to completion
4. Record:
   - `Cycles_5_noData` = ___
   - `Instructions_5_noData` = ___

This includes **only control hazards** (no data hazards).

---

## ✅ Expected Output (N = 10)

### Register Values (Full Hazards Version)

| Register | Value | Description |
|----------|-------|-------------|
| `x7` | 10 | Loop counter (0→10) |
| `x9` | 10 | Independent counter (+1 each iteration) |
| `x10` | 20 | Independent counter (+2 each iteration) |
| `x1` | 265717 | Result of recurrence: $x1_{next} = 3 \times x1 + 7$ |
| `x21` | 10 | N (loop bound) |

### Memory Values

| Label | Value | Description |
|-------|-------|-------------|
| `RES_X1` | 265717 | Final x1 after 10 iterations |
| `RES_X7` | 10 | Loop counter == N |

### Recurrence Explanation

The data hazard chain computes:
- `x4 = x1 + 2`
- `x5 = x4 + 3 = x1 + 5`
- `x6 = x5 + x4 = 2*x1 + 7`
- `x1_new = x6 + x1 = 3*x1 + 7`

Starting with $x1_0 = 1$, after 10 iterations: $x1_{10} = 265717$

---

## 📊 Hazard Impact Calculation

### Step 1: Calculate Total Hazard Overhead

$$\Delta_{\text{total}} = \text{Cycles}_{5\_\text{full}} - \text{Instructions}_{5\_\text{full}}$$

$$\%_{\text{hazards\_total}} = \frac{\Delta_{\text{total}}}{\text{Cycles}_{5\_\text{full}}} \times 100\%$$

### Step 2: Calculate Data Hazard Contribution

$$\Delta_{\text{data}} = \text{Cycles}_{5\_\text{full}} - \text{Cycles}_{5\_\text{noData}}$$

### Step 3: Calculate Control Hazard Contribution

$$\Delta_{\text{control}} = \text{Cycles}_{5\_\text{noData}} - \text{Instructions}_{5\_\text{noData}}$$

### Step 4: Calculate Percentages

$$\%_{\text{data}} = \frac{\Delta_{\text{data}}}{\Delta_{\text{total}}} \times 100\%$$

$$\%_{\text{control}} = \frac{\Delta_{\text{control}}}{\Delta_{\text{total}}} \times 100\%$$

---

## 📈 Example Results Table

| Run | CPU | Version | Cycles | Instructions | CPI |
|-----|-----|---------|--------|--------------|-----|
| 1 | Single-Cycle | Full | ~100 | ~100 | 1.0 |
| 2 | 5-Stage | Full | ~140 | ~100 | ~1.4 |
| 3 | 5-Stage | No Data | ~115 | ~100 | ~1.15 |

### Calculations

| Metric | Formula | Value |
|--------|---------|-------|
| $\Delta_{\text{total}}$ | 140 - 100 | 40 cycles |
| $\Delta_{\text{data}}$ | 140 - 115 | 25 cycles |
| $\Delta_{\text{control}}$ | 115 - 100 | 15 cycles |
| $\%_{\text{data}}$ | 25/40 × 100 | **62.5%** |
| $\%_{\text{control}}$ | 15/40 × 100 | **37.5%** |

**Interpretation:** In this example, ~62.5% of wasted cycles are from data hazards, ~37.5% from control hazards.

---

## 🔍 Visualizing the Hazards

### Data Hazard (RAW Chain)

```
Cycle:    1     2     3     4     5     6     7     8
add x4:   IF    ID    EX    MEM   WB
add x5:         IF    ID    --    EX    MEM   WB     (stall for x4)
add x6:               IF    ID    --    EX    MEM   WB  (stall for x5)
add x1:                     IF    ID    --    EX   ...  (stall for x6)
```

### Control Hazard (Branch)

```
Cycle:    1     2     3     4     5     6
blt:      IF    ID    EX    MEM   WB
loop:           IF    ID    [FLUSH if mispredicted]
next:                 IF    [FLUSH]
target:                     IF    ID    EX    ...
```

---

## 🧠 Why This Methodology Works

### Isolating Data Hazards

- Both versions have **identical control flow**
- Same branch, same number of iterations
- Only difference: RAW dependencies vs. NOPs
- Therefore: `Cycles_full - Cycles_noData ≈ Data hazard overhead`

### Isolating Control Hazards

- The "no data hazard" version still has branches
- NOPs don't create any dependencies
- Therefore: `Cycles_noData - Instructions ≈ Control hazard overhead`

### Assumptions

- Single-cycle CPI ≈ 1.0 (ideal baseline)
- NOPs don't create RAW hazards
- Pipeline fill/drain overhead is minimal

---

## 📋 Lab Report Template

### Aim
To measure and compare the performance impact of data hazards versus control hazards in a 5-stage pipelined RISC-V processor.

### Theory
Pipeline hazards cause performance degradation:
- **Data hazards (RAW)**: Occur when an instruction needs data from a previous instruction not yet written back
- **Control hazards**: Occur when branch direction is unknown, causing speculative execution errors

### Apparatus
- Ripes RISC-V Simulator
- Two test programs: full hazards and control-only hazards

### Procedure
1. Run full hazards program on Single-Cycle CPU (baseline)
2. Run full hazards program on 5-Stage CPU
3. Run control-only program on 5-Stage CPU
4. Calculate hazard contributions using formulas

### Observations

| Run | CPU | Version | Cycles | Instructions |
|-----|-----|---------|--------|--------------|
| 1 | Single-Cycle | Full | ___ | ___ |
| 2 | 5-Stage | Full | ___ | ___ |
| 3 | 5-Stage | Control Only | ___ | ___ |

### Calculations

| Metric | Value |
|--------|-------|
| $\Delta_{\text{total}}$ | ___ cycles |
| $\Delta_{\text{data}}$ | ___ cycles |
| $\Delta_{\text{control}}$ | ___ cycles |
| % Data Hazard | ___% |
| % Control Hazard | ___% |

### Result
- Data hazards account for ___% of wasted cycles
- Control hazards account for ___% of wasted cycles

### Discussion
1. Data hazards cause significant overhead due to tight RAW dependencies
2. Control hazards cause overhead due to branch mispredictions
3. Forwarding reduces but doesn't eliminate data hazard penalties
4. Branch prediction can reduce control hazard overhead
5. Understanding hazard distribution helps target optimization efforts

---

## 🚀 Extensions

### 1. Vary N (Loop Iterations)

| N | Total Overhead | % Data | % Control |
|---|----------------|--------|-----------|
| 5 | ___ | ___ | ___ |
| 10 | ___ | ___ | ___ |
| 20 | ___ | ___ | ___ |
| 50 | ___ | ___ | ___ |

### 2. Compare Forwarding vs. No Forwarding

| Configuration | Cycles | % Overhead |
|--------------|--------|------------|
| 5-Stage w/ Forwarding | ___ | ___ |
| 5-Stage w/o Forwarding | ___ | ___ |

### 3. Different Dependency Patterns

Modify the data hazard chain:
- Longer chain (8 dependent instructions)
- Shorter chain (2 dependent instructions)
- Load-use hazards instead of ALU-ALU

---

## 📚 Key Concepts

| Concept | Definition |
|---------|------------|
| **Data Hazard** | Conflict where instruction needs data not yet available |
| **RAW (Read After Write)** | Most common data hazard - reading before write completes |
| **Control Hazard** | Conflict caused by branch/jump instructions |
| **Pipeline Stall** | Inserting bubbles to wait for data |
| **Pipeline Flush** | Discarding speculatively executed instructions |
| **Forwarding** | Bypassing register file to reduce data hazard stalls |
| **CPI** | Cycles Per Instruction - lower is better |

---

## 📚 References

- [Ripes GitHub Repository](https://github.com/mortbopet/Ripes)
- [RISC-V Specification](https://riscv.org/specifications/)
- Patterson & Hennessy, *Computer Organization and Design*

---

## 📄 License

This educational material is provided for learning purposes. Feel free to use and modify for your coursework and labs.
