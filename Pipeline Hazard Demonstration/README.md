# Pipeline RAW Hazard Demonstration for Ripes

A complete setup for demonstrating **RAW (Read After Write) hazards**, **stalling**, **forwarding**, and **performance comparison** in the [Ripes](https://github.com/mortbopet/Ripes) RISC-V simulator.

---

## 📁 Project Files

| File | Description |
|------|-------------|
| `raw_hazards.asm` | Original program demonstrating RAW hazards (for processors with forwarding) |
| `manual_stalls.asm` | Modified version with explicit NOP stalls (for processors without forwarding) |

---

## 🎯 What This Demonstrates

- **RAW (Read After Write) hazards** on:
  - ALU → ALU dependencies
  - LOAD → ALU dependency (load-use hazard)
- **Hardware solutions**: Forwarding and hazard detection
- **Software solutions**: Manual NOP insertion (stalling)
- **Performance comparison**: CPI differences between approaches

---

## 🔧 Ripes Setup Instructions

### Step 1: Load the Assembly Code

1. Open Ripes
2. Go to the **Editor** tab (left side)
3. Set **Input type: Assembly** (RISC-V RV32)
4. Paste the contents of either `raw_hazards.asm` or `manual_stalls.asm`

### Step 2: Select the Processor Model

1. Go to the **Processor** tab
2. Click the **chip/CPU icon** in the toolbar (Select Processor)
3. Available models:
   - `RISC-V Single Cycle Processor`
   - `RISC-V 5-Stage Processor w/o Forwarding or Hazard Detection`
   - `RISC-V 5-Stage Processor w/o Hazard Detection`
   - `RISC-V 5-Stage Processor` *(has hazard detection + forwarding)*

#### Recommended Configurations:

| Experiment | Processor Model | Assembly File |
|------------|-----------------|---------------|
| Forwarding demo | `RISC-V 5-Stage Processor` | `raw_hazards.asm` |
| Manual stall demo | `RISC-V 5-Stage Processor w/o Forwarding or Hazard Detection` | `manual_stalls.asm` |
| Show RAW bugs | `RISC-V 5-Stage Processor w/o Forwarding or Hazard Detection` | `raw_hazards.asm` |

### Step 3: Configure Layout

- In the processor selection dialog, choose **Standard** or **Extended** layout
- **Extended** layout shows more control signals (recommended for seeing forwarding/stalls)

### Step 4: Run the Simulation

1. Click **Reset** (circular arrow) to reset PC and registers
2. Open the **Registers** pane to see x1…x31
3. Open the **Statistics** pane to see cycles, instructions, and CPI
4. Set a **breakpoint** at the `end` label (click in the blue bar next to that line)
5. Click **Run** - simulation will stop at `end`

---

## ✅ Expected Final Register Values

When run correctly (with forwarding OR with manual NOPs), you should see:

### Core Computations

| Register | Value | Calculation |
|----------|-------|-------------|
| `x1` | 5 | A (loaded from memory) |
| `x2` | 7 | B (loaded from memory) |
| `x3` | 12 | A + B = 5 + 7 |
| `x4` | 17 | x3 + x1 = 12 + 5 |
| `x5` | 29 | x4 + x3 = 17 + 12 |
| `x6` | 12 | Value reloaded from memory C |
| `x7` | 41 | x6 + x5 = 12 + 29 |

### Loop Accumulators

| Register | Value | Calculation |
|----------|-------|-------------|
| `x8` | 290 | 10 × (x3 + x4) = 10 × 29 |
| `x9` | 0 | Loop counter (decremented to 0) |

> ⚠️ **Note:** If you run `raw_hazards.asm` on a processor **without forwarding or hazard detection**, you will get **incorrect values** in `x3`, `x4`, `x5`, `x7`, and `x8`. This demonstrates the RAW hazard bug!

---

## 📊 Performance Comparison

Use the **Statistics** panel in the Processor tab to compare:

### Metrics to Observe

- **Total cycles**
- **Retired instructions**
- **CPI** (Cycles Per Instruction) = Cycles / Instructions

### Expected Results

| Configuration | Cycles | CPI | Notes |
|--------------|--------|-----|-------|
| 5-stage w/o FWD/HZ + NOPs | Higher | >1.5 | Many software stalls (bubbles) |
| 5-stage with HZ + FWD (no NOPs) | Lower | ~1.0 | Hardware forwarding & minimal stalls |

> The pattern **"NOP version slower, forwarding version faster"** demonstrates the performance benefit of hardware forwarding.

---

## 🧪 Experiment Workflow

### Experiment 1: Show RAW Hazard Bugs

1. Load `raw_hazards.asm`
2. Select `RISC-V 5-Stage Processor w/o Forwarding or Hazard Detection`
3. Run to completion
4. **Observe:** Incorrect register values due to unhandled RAW hazards

### Experiment 2: Software Solution (Manual Stalls)

1. Load `manual_stalls.asm`
2. Select `RISC-V 5-Stage Processor w/o Forwarding or Hazard Detection`
3. Run to completion
4. **Observe:** Correct values but high CPI due to NOP bubbles

### Experiment 3: Hardware Solution (Forwarding)

1. Load `raw_hazards.asm`
2. Select `RISC-V 5-Stage Processor` (with hazard detection + forwarding)
3. Run to completion
4. **Observe:** Correct values with low CPI (efficient execution)

---

## 📝 Program Structure

Both assembly files follow this structure:

1. **Data Section**: Define variables A, B, C in memory
2. **Load Operands**: Load A and B into registers
3. **RAW Hazard Chain**: Back-to-back dependent ADD instructions
4. **Load-Use Hazard**: Store then immediately load and use
5. **Loop with RAW Hazards**: Accumulator loop demonstrating repeated dependencies
6. **End Marker**: NOP instruction for breakpoint

---

## 🔍 Understanding the Hazards

### ALU → ALU RAW Hazard

```asm
add  x3, x1, x2      # x3 written here
add  x4, x3, x1      # x3 needed here (RAW hazard!)
add  x5, x4, x3      # x4 needed here (RAW hazard!)
```

Without forwarding, `x3` isn't written back until WB stage, but `x4` needs it in ID stage.

### Load-Use RAW Hazard

```asm
lw   x6, 0(x12)      # x6 loaded from memory
add  x7, x6, x5      # x6 needed immediately (load-use hazard!)
```

Even with forwarding, a 1-cycle stall is often needed because LW result isn't available until MEM stage.

---

## 📚 References

- [Ripes GitHub Repository](https://github.com/mortbopet/Ripes)
- [RISC-V Specification](https://riscv.org/specifications/)

---

## 📄 License

This educational material is provided for learning purposes. Feel free to use and modify for your coursework and labs.
