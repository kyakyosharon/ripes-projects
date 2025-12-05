# Alignment Impact on Memory Performance — Ripes Demonstration

A complete, step-by-step experiment showing how **aligned vs. misaligned memory accesses** affect performance, the pipeline, and exception behavior in RISC-V. This demonstration includes:

* How aligned loads are fast
* How misaligned loads trigger *extra memory operations*
* How misalignment can even cause **traps** depending on CPU configuration
* Why compilers insert padding and alignment directives

This experiment ties in with your earlier Page-Fault and TLB studies, forming a complete view of memory-access performance.

---

# 📁 Project Files

| File                        | Description                                                        |
| --------------------------- | ------------------------------------------------------------------ |
| `aligned_vs_misaligned.asm` | Demonstrates aligned and misaligned loads, including trap behavior |

Load this file in Ripes and toggle “Support Misaligned Access” to observe two very different outcomes.

---

# 🎯 What This Demonstrates

* **Aligned access (fast path)**

  * Address = multiple of 4
  * L1 cache can fetch entire word in **one bus transaction**

* **Misaligned access (slow path)**
  If CPU *supports* misalignment:

  * Load requires *two* memory accesses → merging → stalls

  If CPU *does NOT* support misalignment:

  * CPU raises a **Load Address Misaligned** exception
  * Pipeline flush → trap handler → software emulation → *extremely slow*

* **Impact on Struct Layout & ABI**
  Alignment is enforced across systems because misalignment hurts performance *and correctness*.

---

# 🔧 Ripes Setup Instructions

### Step 1 — Select Processor With Misalignment Options

1. Open **Ripes**.
2. Click CPU icon → Choose:

   * `RV32I 5-stage`
     or
   * `RV32IM 5-stage`
3. Go to **Processor Configuration** and find:
   ✔️ *Support Misaligned Access* (toggle ON/OFF)

### What These Modes Do:

| Setting      | Behavior                                                              |
| ------------ | --------------------------------------------------------------------- |
| **Enabled**  | Misaligned loads are emulated in hardware → extra cycles in MEM stage |
| **Disabled** | Misaligned loads trigger exceptions → trap handler runs               |

You will test **both modes**.

### Step 2 — Cache Settings

Use default caches (1KB, 16B lines). Misalignment impacts happen *before* the cache hierarchy, so any cache size works.

---

# 📝 The Assembly Code

```asm
.data
    .align 4                 # Force alignment for the base address
data_word:
    .word 0xDEADBEEF         # Stored at an address ending in ...00

.text
.globl main
main:
    la s0, data_word

    # -------------------------
    # 1. Aligned Load (Fast)
    # -------------------------
    lw t0, 0(s0)            # Correctly aligned (address ends in .00)

    # -------------------------
    # 2. Misaligned Load (Slow or Trap)
    # -------------------------
    addi s1, s0, 1          # Now address ends in .01 (misaligned)
    lw t1, 0(s1)            # Misaligned access!
    
    li a7, 10
    ecall
```

---

# 🧠 What the Code Does

### ✔️ **Aligned Load**

* `data_word` is aligned using `.align 4`
* `s0` holds an address like `0x10000000` (ends in 00)
* `lw t0, 0(s0)`:

  * One memory request
  * One cache access
  * Fastest path through MEM stage

---

### ❌ **Misaligned Load**

When we compute:

```
addi s1, s0, 1
```

The new address ends in:

```
...0001
```

This makes **lw t1, 0(s1)** misaligned.

What happens next depends on Ripes settings:

---

# 🧪 Ripes Behavior: Two Modes

## Mode A — “Support Misaligned Access” ENABLED

(Realistic for Linux-capable RISC-V cores)

### Hardware performs:

* 1st memory access: fetch high bytes of word
* 2nd memory access: fetch low bytes of next word
* Internal shift + merge
* Pipeline stalls for an **extra cycle or two**

### In the Ripes Pipeline View:

* `lw t1, 0(s1)` sits in the **MEM** stage longer
* A bubble inserted behind it
* Entire pipeline slows for that instruction

### Expected Statistics:

| Access Type   | Latency                                 |
| ------------- | --------------------------------------- |
| Aligned lw    | 1 × L1 access                           |
| Misaligned lw | 2 × L1 accesses + merging (≈ 2× slower) |

---

## Mode B — “Support Misaligned Access” DISABLED

(Realistic for microcontrollers / embedded cores)

### CPU detects misalignment ⇒ raises **exception**

Behavior is:

1. Pipeline flushes
2. `mcause` = Load Address Misaligned
3. Jump to `mtvec`
4. Trap handler runs (see your Section 6 experiment!)
5. OS or handler must emulate the load byte-by-byte:

   * `lb`
   * `lb`
   * `sll`
   * `or`

### Performance impact:

| Operation                        | Approx Cost                    |
| -------------------------------- | ------------------------------ |
| Normal lw                        | ~3 cycles                      |
| Misaligned lw + software handler | *Hundreds–thousands* of cycles |

Huge penalty.

---

# 📊 Observing Performance Differences

### With Misalignment Enabled:

Look at:

* **Pipeline View:**

  * MEM stage holds the misaligned load longer

* **D-Cache Statistics:**

  * Two read requests for one lw
  * Higher hit/miss activity

### With Misalignment Disabled:

* Execution jumps to “trap handler”
* `mepc` updated
* Software must emulate misaligned load (massive slowdown)

---

# 🧪 Experiment Workflow

### 1️⃣ Run With Aligned Load Only

Comment out misaligned access:

```asm
# addi s1, s0, 1
# lw t1, 0(s1)
```

Record:

* Total cycles
* CPI
* D-cache reads (should be 1)

---

### 2️⃣ Run With Misaligned Access (Hardware Enabled)

Enable misaligned access:

* Toggle ON "Support Misaligned Access"
* Re-run full program

Record:

* D-cache reads → should be **2**
* Extra MEM-stage stall visible

---

### 3️⃣ Run With Misaligned Access (Hardware Disabled)

Toggle OFF “Support Misaligned Access”

* Run program
* Should trap to handler or crash (if handler not implemented)

Observe:

* Control goes to `mtvec`
* `mcause` contains “Load Address Misaligned”
* Execution resumes (or halts depending on handler)

---

# 📈 Summary: Why Alignment Matters

### 🧩 Why aligned loads are fast:

* One address
* One bus request
* One cache access
* No shift/merge required

### 🔥 Why misaligned loads are slow:

* Word spans two lines
* Two memory accesses
* Shift + merge
* Increased latency
* Possible trap
* Possible software emulation
* Massive slowdown

### 🛠 Why compilers enforce alignment:

* ABI rules require structs and arrays to be aligned
* Misaligned fields cause slowdowns
* Padding bytes avoid misalignment

---

# 📚 Key Concepts

| Concept           | Explanation                                     |
| ----------------- | ----------------------------------------------- |
| Aligned access    | Address multiple of word size (4 bytes)         |
| Misaligned access | Address not divisible by 4                      |
| Bus transaction   | L1 cache fetch of 32 bits                       |
| Trap handler      | Privileged-mode routine handling faults         |
| Shift-merge logic | Hardware mechanism to assemble misaligned word  |
| ABI alignment     | Compiler and OS rules ensuring efficient access |

---

# 🚀 Extensions

Try:

* Misaligned **stores** (even worse on some hardware)
* Accessing arrays with stride 1, 2, 3, 4
* Misaligned struct fields
* Emulating multi-byte loads using `lb` / `lbu`
* Changing cache block size to bigger/smaller values

---

# 📄 License

This alignment-performance demonstration is designed for RISC-V architecture and OS courses.
You are free to modify, extend, and integrate it into your Ripes labs or teaching material.
