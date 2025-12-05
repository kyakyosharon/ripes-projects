# Memory Locality Performance Study for Ripes: Sequential vs Random

An experiment in the Ripes RISC-V simulator showing how **access pattern** (sequential vs. random) drastically changes **cache miss behavior**, even with the same cache size and block size.

This project compares:

* A **sequential scan** over an array (good spatial locality)
* A **pseudo-random pointer-chasing** pattern using an LCG (poor spatial locality)

---

## 📁 Project Files

| File                    | Description                                                                     |
| ----------------------- | ------------------------------------------------------------------------------- |
| `sequential_access.asm` | Baseline: linearly traverses an array (sequential locality)                     |
| `random_access_lcg.asm` | Pointer-chasing style random access using a Linear Congruential Generator (LCG) |

You run both programs under the **same cache configuration** and compare miss behavior.

---

## 🎯 What This Demonstrates

* **Sequential Locality**
  Accesses of the form `i, i+1, i+2, …` which make **excellent use of spatial locality** and cache blocks.

* **Random Locality**
  Accesses that jump “all over” memory, defeating spatial locality and relying only on temporal locality.

* **Impact on Miss Rate**
  For the same cache and block size, **sequential traversal** can show **low miss rate**, while **random access** can approach **100% miss rate**.

* **Link to Data Structures**
  Why contiguous arrays tend to be more cache-friendly than pointer-heavy structures like linked lists.

---

## 🔧 Ripes Setup Instructions (Common for Both Modes)

### Step 1: Configure the Processor

1. Open **Ripes**.
2. Click the **Processor Selection** (chip icon).
3. Select a **RISC-V 32-bit 5-stage pipelined processor** with caches, e.g.:

   * `RV32I 5-stage` / `RV32IM 5-stage`
4. Avoid single-cycle variants that don’t model caches.

---

### Step 2: Configure the Data Cache

Use the **same cache configuration** for both sequential and random experiments:

* **Cache Size:** `1024 B` (1 KiB)
* **Block / Line Size:** `16 B` (4 words)
* **Associativity:** `1` (Direct-Mapped)
* Replacement Policy: any (not very important for this experiment)
* D-Cache **enabled** ✅

Steps:

1. Open **Component / Processor Configuration** (gear icon ⚙️).
2. Under **Data Cache (D-Cache)**:

   * Enable cache.
   * Set **Size = 1024 B**.
   * Set **Block size = 16 B**.
   * Set **Ways = 1** (direct-mapped).
3. Apply and close.

You will:

* Run `sequential_access.asm` first (baseline locality).
* Then run `random_access_lcg.asm` with **no cache config changes**.

---

## 📝 The Assembly Code

### Version A: Sequential Access (Baseline)

This is a simple linear traversal over an array, ideal for **spatial locality** and cache block reuse.

```asm
.data
    # 1024 words = 4096 bytes
    # Size chosen so random indexing in [0, 1023] is meaningful in the next experiment
array:
    .zero 4096

.text
.globl main
main:
    la   s0, array        # s0 = base of array
    li   t0, 1024         # Loop over 1024 elements (words)

seq_loop:
    lw   t1, 0(s0)        # Load array[i]
    addi s0, s0, 4        # Move to next word (i++)
    addi t0, t0, -1
    bnez t0, seq_loop

    li   a7, 10
    ecall
```

#### How This Uses Locality

* Each load goes to the **next consecutive word**.
* With a **16-byte block**, each miss fetches **4 words**:

  * First access to a block misses.
  * Next 3 accesses (within the same block) **hit**.
* Idealized miss rate (ignoring conflicts):
  1 miss every 4 accesses → **25% miss rate**.

In a **direct-mapped 1KB cache**, there may be some extra **conflict/capacity misses**, but sequential access still gives a **much lower miss rate** than random.

---

### Version B: Random Access Using LCG (Pseudo-Random Pointer Chasing)

This program uses a **Linear Congruential Generator (LCG)** to generate pseudo-random indices in the range `[0, 1023]`, then accesses `array[index]`.

#### LCG Recap

$$
X_{n+1} = (aX_n + c) \mod m
$$

Typical parameters (like glibc):

* $a = 1103515245$
* $c = 12345$
* $m = 2^{31}$

We then take the **lower 10 bits** of $X_n$ as an index:

* 10 bits ⇒ range 0–1023 (covers all 1024 words in the array).

#### Code

```asm
.data
    # LCG Parameters
seed:
    .word 42                # Initial seed X_0
multiplier:
    .word 1103515245        # a
increment:
    .word 12345             # c
mask:
    .word 0x7FFFFFFF        # m = 2^31 - 1 (approx; mask for lower 31 bits)

    # Data array: 1024 words (4096 bytes)
array_base:
    .zero 4096              # 1024 * 4 bytes

.text
.globl main
main:
    # Load base addresses
    la   s0, array_base     # s0 = base of data array
    la   s1, seed           # s1 = &seed

    # Load LCG state and parameters
    lw   t0, 0(s1)          # t0 = X_n (current seed)
    lw   t1, multiplier     # t1 = a
    lw   t2, increment      # t2 = c
    lw   t3, mask           # t3 = m mask (for modulo)

    li   t4, 100            # Perform 100 random accesses

random_loop:
    # --- LCG Step: X_(n+1) = (aX_n + c) mod m ---
    mul  t0, t0, t1         # t0 = a * X_n
    add  t0, t0, t2         # t0 = a * X_n + c
    and  t0, t0, t3         # t0 = (a * X_n + c) mod 2^31 (mask)

    # --- Scale random number to array index [0, 1023] ---
    andi t5, t0, 1023       # t5 = index (lower 10 bits)
    slli t5, t5, 2          # index * 4 -> byte offset (since word = 4 bytes)

    # --- Effective Address & Random Load ---
    add  t6, s0, t5         # t6 = &array_base[index]
    lw   zero, 0(t6)        # Perform the random load (value ignored)

    addi t4, t4, -1
    bnez t4, random_loop

    # Exit
    li   a7, 10
    ecall
```

#### What This Code Does

* Maintains a pseudo-random sequence in `t0`.
* Maps each pseudo-random value to a valid index 0–1023.
* Performs **100 random loads** from across the 4KB array.
* No two consecutive accesses are guaranteed to be close in memory.

This is a classic **pointer-chasing pattern**, where each access depends on the previous state but jumps around memory.

---

## ✅ Expected Output

### Functional Behavior

* Neither program prints or visibly changes memory.
* The experiment’s “output” is in the **Data Cache statistics**:

  * Number of reads
  * Hits
  * Misses
  * Miss rate / hit rate

You compare:

* **Sequential program:** good spatial locality → **lower miss rate**
* **Random program:** broken spatial locality → **miss rate approaches 100%**

---

## 📊 Simulation Analysis in Ripes

### Common Cache Configuration

* Size: **1KB**
* Block size: **16B** (4 words)
* Associativity: **Direct-Mapped (1 way)**

---

### Sequential Access (Baseline – from previous study)

When accessing `array[0..1023]` sequentially:

* Each 16B block holds **4 consecutive words**.
* Idealized behavior (if conflicts are minimal):

  * **1 miss per 4 accesses**.
  * Miss Rate ≈ **25%**.

Ripes may show something close to this, depending on exact mapping and conflicts.

---

### Random Access (LCG-Based Pointer Chasing)

Key idea: the LCG generates indices that **jump across** the 4KB array, e.g.:

* Index 5 → Index 800 → Index 12 → Index 670 → …

Each access is to (approximately) a **random location** in the array.

**Probability of staying in the same block:**

* Block size = 16 B = 4 words.
* Array size = 1024 words.
* At word granularity:
  $$
  P(\text{next index is in same block}) \approx \frac{\text{BlockWords}}{\text{ArrayWords}} = \frac{4}{1024} \approx 0.39\%
  $$

So **over 99% of the time**, the next access jumps **to a different block**.

**Consequences:**

* Each new random index is unlikely to reuse the block fetched by the previous access.
* Spatial locality is essentially **destroyed**.
* Temporal locality is also minimal because:

  * We perform only **100 random accesses** over **1024** possible positions → many positions may be touched at most once.

**Resulting Miss Rate:**

* Most accesses are **compulsory or conflict misses**, with very few hits.
* Theoretical upper bound:
  $$
  \text{Hit Rate} \approx \frac{\text{BlockSize}}{\text{ArraySize}} \Rightarrow \text{Miss Rate} \approx 1 - \frac{\text{BlockSize}}{\text{ArraySize}}
  $$
  For our example (in word units):
  $$
  1 - \frac{4}{1024} = 1 - 0.0039 \approx 99.6\%
  $$

In practice (with 100 random accesses), Ripes should show a **miss rate very close to 100%**.

---

## 🔍 How to Observe in Ripes

### For Each Program

1. Load the corresponding `.asm` file.
2. Click **Assemble**.
3. Ensure the cache is configured as: 1KB, 16B block, 1-way.
4. **Reset** the processor.
5. Click **Run** to program completion.
6. Open the **Statistics / Cache** panel and look at **Data Cache** numbers:

   * Total reads
   * Read hits
   * Read misses
   * Hit / Miss rate

### What You Should See

| Program                 | Pattern    | Expected Miss Rate (Trend)             |
| ----------------------- | ---------- | -------------------------------------- |
| `sequential_access.asm` | Sequential | Much **lower** miss rate (≈ 25% ideal) |
| `random_access_lcg.asm` | Random     | Miss rate **approaching 100%**         |

The key takeaway: **same cache**, **same size and block**, **different access pattern ⇒ wildly different performance**.

---

## 🧪 Experiment Workflow

### Experiment 1: Sequential Baseline

1. Configure D-Cache: 1KB, 16B block, 1-way.
2. Load `sequential_access.asm`.
3. Reset and run to completion.
4. Record:

   * Reads = ___
   * Misses = ___
   * Hits = ___
   * Miss Rate = ___ (around 25% in ideal case)

---

### Experiment 2: Random Pointer Chasing

1. Keep **the same cache configuration**.
2. Load `random_access_lcg.asm`.
3. Reset and run to completion.
4. Record:

   * Reads = ___ (≈ 100)
   * Misses = ___ (close to Reads)
   * Hits = ___ (close to 0)
   * Miss Rate ≈ **very close to 100%**

---

### Experiment 3: Comparison & Interpretation

Compare the recorded miss rates:

* **Sequential:** lower miss rate (cache reuses nearby data).
* **Random:** miss rate almost 1.0 (little to no reuse of fetched blocks).

You can summarize:

$$
\text{MissRate}_{\text{random}} \approx 1 - \frac{\text{BlockSize}}{\text{ArraySize}}
$$

This directly explains why **linked lists, trees with scattered nodes, and pointer-heavy structures** often perform worse than **flat arrays** in cache terms.

---

## 📈 Why This Works

### Locality Modes

* **Sequential Locality**

  * Access pattern: `i, i+1, i+2, ...`
  * Cache fetches blocks that contain **several future accesses**.
  * Spatial locality is **high** → few misses once warmed up.

* **Random Locality**

  * Access pattern: pseudo-random jumps: `i, j, k, …` across the whole array.
  * Each new access is likely to land in a **different block**.
  * Spatial locality is **almost zero** → block prefetch is wasted.

### Data Structures Perspective

* **Arrays** (contiguous):

  * Great for caches.
  * Prefetchers can guess next addresses.
  * Fewer misses, more hits per block.

* **Pointer-based structures** (linked lists, trees with scattered nodes):

  * Addresses determined at runtime via pointers.
  * Memory nodes often spread across the heap.
  * Behave similarly to random access → **poor cache performance**.

---

## 📚 Key Concepts

| Concept                             | Definition                                                                                    |
| ----------------------------------- | --------------------------------------------------------------------------------------------- |
| Spatial Locality                    | Tendency to access memory addresses that are close together in space                          |
| Temporal Locality                   | Tendency to re-access the same data within a short time window                                |
| Sequential Access                   | Access pattern in which indices increase predictably (e.g. `i+1`)                             |
| Random Access                       | Access pattern where each address is unpredictable and uncorrelated with the previous one     |
| Linear Congruential Generator (LCG) | Simple deterministic formula for generating pseudo-random sequences                           |
| Pointer Chasing                     | Access pattern where each access depends on data from the previous access (e.g. linked lists) |

---

## 🚀 Extensions

To explore further:

* **Increase Number of Random Accesses**

  * Change `li t4, 100` to `li t4, 1000` and see if miss rate stays near 100%.

* **Change Block Size**

  * Try 32B or 64B blocks and see how **random miss rate** stays high, while sequential miss rate improves.

* **Mixed Patterns**

  * Combine sequential and random phases in one program and see hybrid behavior.

* **Compare Different Data Structures**

  * Implement a linked list traversal vs. array traversal and compare cache stats.

---

## 📄 License

This material is designed for **educational use** in architecture labs, assignments, and self-study.
You are free to copy, modify, and integrate it into your coursework and Ripes-based experiments.
