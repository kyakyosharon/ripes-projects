# Cache Mapping Topology Demonstration for Ripes

A classic computer architecture experiment showing how **cache mapping topology** (Direct-Mapped vs. 4-Way Set-Associative) affects **hit rate, conflict misses, and overall performance**, using the Ripes RISC-V simulator.

This project uses a **pathological memory access pattern** (same index, different tags) to trigger **thrashing** in a direct-mapped cache and then shows how a **4-way set-associative cache** fixes it without changing the code.

---

## 📁 Project Files

| File                  | Description                                                                 |
| --------------------- | --------------------------------------------------------------------------- |
| `conflict_access.asm` | RISC-V assembly that generates conflict-prone accesses A, B, C, D in a loop |

*(You run the same program twice — once with a direct-mapped cache, once with a 4-way set-associative cache.)*

---

## 🎯 What This Demonstrates

* **Direct-Mapped Cache Conflicts**
  How rigid mapping (1 block per line) can cause **thrashing** when multiple active addresses share the same index.

* **Set-Associative Cache Flexibility**
  How allowing multiple “ways” per set drastically **reduces conflict misses** for the same access pattern.

* **Index vs Tag Bits**
  How addresses that differ by **cache size** (e.g., X, X+1024, X+2048, X+3072) can share the **same index** but different **tags**.

* **Hit Rate vs. Hardware Complexity**
  Trade-off between simple hardware (direct-mapped) and better performance (set-associative).

* **Performance Comparison**
  Same working set, same cache size, same code — but radically different **hit rates** and **miss patterns**.

---

## 🔧 Ripes Setup Instructions (Crucial)

### Step 1: Configure the Processor

1. Open **Ripes**.
2. Click the **Processor Selection** icon (chip icon at the top).
3. Select a **RISC-V 32-bit pipelined core** with cache support, for example:

   * `RV32I 5-stage` or `RV32IM 5-stage`
4. **Do NOT** choose a purely single-cycle core with no cache options.

---

### Step 2: Configure the Data Cache

You’ll run **two configurations** with the **same program**.

#### Config A: Direct-Mapped Cache (1-Way)

1. In the left-hand panel, click the **Memory** tab.
2. Scroll down to the **Data Cache** section:

   * Enable D-Cache: ✅
   * **Cache size:** `1024 B` (1 KiB)
   * **Block / line size:** `32 B`
   * **Associativity / Ways:** `1`  → **Direct-mapped**
   * Replacement policy: any (irrelevant for 1-way)
3. (Optional) You can disable I-Cache or leave default.

#### Config B: 4-Way Set-Associative Cache

After testing Config A, **change only associativity**:

1. Go back to the **Memory** tab.
2. In **Data Cache**:

   * **Cache size:** `1024 B`
   * **Block / line size:** `32 B`
   * **Associativity / Ways:** `4`  → **4-way set-associative**
   * **Replacement policy:** `LRU`
3. All other parameters remain identical.

---

### Step 3: General Run Instructions

For **both configurations**:

1. Load `conflict_access.asm` into the **Editor**.
2. Click **Assemble**.
3. Use **Reset** before each new run/config change.
4. Use **Run** to execute the program to completion.
5. Open the **Statistics / Cache** view to inspect:

   * Data cache **read accesses**, **hits**, **misses**, **hit rate**.
6. (Optional) Use the **Cache visualization** to see line/set contents during execution.

---

## 📝 The Assembly Code

### Conflict Generator Loop

This code repeatedly accesses four addresses:
`base + 0`, `base + 1024`, `base + 2048`, `base + 3072`.

With a **1KB cache** and **32B blocks**, these addresses share the same **index bits**, but have different **tags**, making them perfect to demonstrate conflict vs. coexistence.

```asm
.data
    # Offsets spaced by the cache size (1024 B) to force index collisions
    .equ OFFSET_A, 0
    .equ OFFSET_B, 1024
    .equ OFFSET_C, 2048
    .equ OFFSET_D, 3072

    # Reserve 4 KB so all offsets are valid
base_addr:
    .space 4096

.text
.globl main
main:
    la  s0, base_addr        # s0 = base address of allocated space
    li  t0, 10               # loop counter: perform the access sequence 10 times

conflict_loop:
    lw  t1, OFFSET_A(s0)     # Access A: base + 0
    lw  t2, OFFSET_B(s0)     # Access B: base + 1024
    lw  t3, OFFSET_C(s0)     # Access C: base + 2048
    lw  t4, OFFSET_D(s0)     # Access D: base + 3072

    addi t0, t0, -1          # t0--
    bnez t0, conflict_loop   # repeat until t0 == 0

    # Terminate program (ecall semantics may vary in Ripes)
    li  a7, 10
    ecall
```

### What the Code Does

* **Total loads per iteration:** 4 (A, B, C, D)
* **Total iterations:** 10
* **Total memory accesses:** 4 × 10 = **40 loads**
* No printing, no visible computation — the goal is **purely to stress the cache**.

---

## ⚙️ Theoretical Framework (Why This Access Pattern?)

### Cache Geometry (Same in Both Configs)

* Total cache size: **1024 B**
* Block size: **32 B**
* Number of lines: 1024 / 32 = **32 lines**

**Direct-Mapped (Config A)**

* 32 lines ⇒ **5 index bits**
* 32B block ⇒ **5 offset bits**
* Address format:
  `Tag | Index (5) | Offset (5)`

Now look at the offsets:

* OFFSET_A = 0
* OFFSET_B = 1024
* OFFSET_C = 2048
* OFFSET_D = 3072

1024 B / 32 B per block = **32 blocks**.
So these addresses are separated by **32 blocks**, i.e. by a multiple of the number of lines.

Result:
All four addresses **map to the same index**, but have different **tag** values → they **fight** for the same line in a direct-mapped cache.

**4-Way Set-Associative (Config B)**

* Same total size, same block size ⇒ still 32 total lines.
* With **4 ways**, number of sets = 32 / 4 = **8 sets**.
* Index bits = log₂(8) = **3 bits**.

All four blocks now map to the **same set**, but that set has **4 ways**, so A, B, C, D can **coexist** without eviction.

---

## ✅ Expected Output

### Functional Behavior

* There is no user-facing output (no prints, no memory writes we care about).
* Correctness here is **not about values**, but about **cache behavior**.

---

### Cache Behavior – Direct-Mapped (Config A)

Per iteration:

1. `lw t1, OFFSET_A(s0)`
2. `lw t2, OFFSET_B(s0)`
3. `lw t3, OFFSET_C(s0)`
4. `lw t4, OFFSET_D(s0)`

Because A, B, C, D **all map to the same index**:

* Every new load **evicts** the previous line.
* On the **next iteration**, A is **no longer in the cache** – it was evicted by B, C, or D.

**Total loads:** 40
**Expected pattern:**

* 1st time A/B/C/D: compulsory miss
* All later references: **conflict misses**

> **Result:** Almost **every access is a miss**
> **Approximate stats:**
>
> * Hits: 0
> * Misses: 40
> * Hit rate ≈ **0%**
> * Misses dominated by **conflict misses**

---

### Cache Behavior – 4-Way Set-Associative (Config B)

First iteration:

* A: miss → placed in Way 0 of its set
* B: miss → placed in Way 1
* C: miss → placed in Way 2
* D: miss → placed in Way 3

All four now **live together** in the same set, one per way.

Subsequent iterations:

* A, B, C, D are all **hits** (no eviction, LRU just updates recency).

**Total loads:** 40

> **Result:** Only the first A/B/C/D loads miss
> **Approximate stats:**
>
> * Misses: 4 (only the first time for A, B, C, D)
> * Hits: 36
> * Overall hit rate ≈ **90%**
> * Second–tenth iterations: **near 100% hit rate**

---

## 📊 Performance Comparison

*(Exact numbers may vary slightly by Ripes version, but these are the expected patterns.)*

### Hit/Miss Summary

| Metric           | Config A: Direct-Mapped | Config B: 4-Way Set-Assoc | Reason                                              |
| ---------------- | ----------------------- | ------------------------- | --------------------------------------------------- |
| Total data loads | 40                      | 40                        | Same program                                        |
| Hits             | ~0                      | ~36                       | A/B/C/D keep evicting vs. all coexisting in one set |
| Misses           | ~40                     | ~4                        | Pure conflict misses vs. only compulsory misses     |
| Hit Rate         | ~0%                     | ~90%                      | Associativity eliminates conflict thrashing         |

### Optional: Cycles & CPI

If you look at **Statistics → Cycles / CPI**:

* **Config A (Direct-Mapped):**

  * More misses → more stall cycles
  * Higher total cycles & CPI

* **Config B (4-Way Set-Assoc):**

  * Far fewer misses → fewer memory stalls
  * Lower total cycles & CPI

You can define:

$$
\text{Speedup} = \frac{\text{Cycles}_{\text{direct}}}{\text{Cycles}_{\text{4-way}}}
$$

and

$$
\Delta \text{CPI} = \text{CPI}_{\text{direct}} - \text{CPI}_{\text{4-way}}
$$

---

## 🔍 How to Observe the Conflict/Coexistence in Ripes

### Direct-Mapped (Thrashing)

1. Select **Config A (1-way)**.
2. Open the **Cache view** / **D-Cache visualization**.
3. Single-step or run slowly through one iteration of the loop.
4. Watch the **same cache line** being repeatedly:

   * Filled with A
   * Overwritten by B
   * Overwritten by C
   * Overwritten by D

You effectively see **one line flipping tags** every access.

### 4-Way Set-Associative (Stable Set)

1. Switch to **Config B (4-way)**.
2. Open the **Cache view** again.
3. Run through the first iteration:

   * A goes to Way 0
   * B to Way 1
   * C to Way 2
   * D to Way 3
4. Run more iterations:

   * All four ways in that set stay **occupied by A/B/C/D**
   * Only **hit counters** increase; no evictions occur.

---

## 🧪 Experiment Workflow

### Experiment 1: Direct-Mapped Thrashing

1. Configure **D-Cache** as:

   * Size: 1KB, Block: 32B, Ways: **1 (direct-mapped)**.
2. Load `conflict_access.asm`.
3. **Reset** the processor.
4. Run to completion.
5. Record from **Statistics**:

   * D-Cache reads: ____
   * D-Cache read hits: ____
   * D-Cache read misses: ____
   * Hit rate: ____
   * (Optional) Cycles, CPI.

---

### Experiment 2: 4-Way Set-Associative Behavior

1. Change only **associativity** to **4 ways**, with **LRU** replacement.
2. Keep size and block size the same (1KB, 32B).
3. **Reset** the processor.
4. Run to completion.
5. Record:

   * D-Cache reads: ____
   * D-Cache read hits: ____
   * D-Cache read misses: ____
   * Hit rate: ____
   * (Optional) Cycles, CPI.

---

### Experiment 3: Quantitative Comparison

Compute:

* **Hit Rate Difference**

  $$
  \text{HitRate}_{\text{4-way}} - \text{HitRate}_{\text{direct}}
  $$

* **Miss Reduction Factor**

  $$
  \text{Miss Reduction} = \frac{\text{Misses}_{\text{direct}}}{\text{Misses}_{\text{4-way}}}
  $$

* **Speedup (if you recorded cycles)**

  $$
  \text{Speedup} = \frac{\text{Cycles}_{\text{direct}}}{\text{Cycles}_{\text{4-way}}}
  $$

Summarize how **only changing associativity**, not capacity or code, dramatically changes performance.

---

## 📈 Why This Works

### Conflict Miss Problem

In the direct-mapped cache:

* Each index can only hold **exactly one block**.
* A, B, C, D share the **same index**, so:

  * A evicts B, B evicts C, C evicts D, D evicts A, etc.
* The working set easily **fits in capacity** (only 4 blocks, cache has 32 lines)
  but **mapping rigidity** forces them into **one line** → pure **conflict misses**.

### Associativity as the Solution

In a **4-way set-associative** cache:

* The same index (now “set”) has **4 ways**.
* A, B, C, D map to the **same set**, but can occupy different ways.
* Once they are all loaded, **no more evictions** occur (for this workload).
* Thus, associativity **converts conflict misses into hits** without changing:

  * Total cache size
  * Block size
  * Program code

---

## 📚 Key Concepts

| Concept                 | Definition                                                                                     |
| ----------------------- | ---------------------------------------------------------------------------------------------- |
| Direct-Mapped Cache     | Each block maps to exactly one cache line (1 way per set)                                      |
| Set-Associative Cache   | Cache divided into sets; each set has multiple ways (lines) a block can occupy                 |
| Fully Associative Cache | Single set; any block can go into any line (max flexibility, many comparators)                 |
| Compulsory Miss         | First time a block is accessed; must miss because it wasn’t in the cache before                |
| Conflict Miss           | Miss that occurs because multiple blocks compete for the same set/line despite enough capacity |
| Thrashing               | Extreme form of conflict where blocks repeatedly evict each other and rarely hit               |

---

## 🚀 Extensions

To explore further:

* **Change Associativity**

  * Try 2-way associative with the same pattern.
  * Predict whether A–D will still conflict or partly coexist.

* **Change Stride**

  * Adjust offsets to see which patterns **do** and **don’t** cause thrashing.

* **Vary Cache Size**

  * Double cache size and see how many addresses you can add before thrashing returns.

* **Introduce Stores**

  * Mix in `sw` instructions and explore write-through vs write-back (if supported).

---

## 📚 References

* Ripes GitHub Repository
* RISC-V User-Level ISA Specification
* Patterson & Hennessy, *Computer Organization and Design* (Cache design & mapping strategies)

---

## 📄 License

This educational material is intended for **learning and lab work**.
You’re free to copy, adapt, and include it in your coursework, reports, and experiments.
