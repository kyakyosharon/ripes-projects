# Cache Block Size Demonstration for Ripes

An experiment in the Ripes RISC-V simulator showing how **cache block size** affects **miss rate** for a **sequential array traversal**, with total cache size held constant.

This project uses a simple **linear scan of an array** to illustrate how **spatial locality** is (or isn’t) exploited when you change the **cache line size** (4B, 16B, 64B) while keeping cache capacity fixed at 512 bytes.

---

## 📁 Project Files

| File                       | Description                                                            |
| -------------------------- | ---------------------------------------------------------------------- |
| `sequential_traversal.asm` | RISC-V assembly that linearly reads 128 contiguous words from an array |

You will run **the same program** three times in Ripes, only changing the **data cache block size**.

---

## 🎯 What This Demonstrates

* **Spatial Locality**
  How sequential memory access patterns can benefit from fetching **neighboring words** in one cache block.

* **Block Size vs Miss Rate**
  How increasing block size (4B → 16B → 64B) reduces **compulsory miss rate** for sequential access.

* **Cache Pollution** (conceptual)
  Why very large blocks can be wasteful for **sparse** access patterns, even though they are great for sequential ones.

* **Miss Rate vs Miss Penalty**
  Even if miss rate drops, **miss penalty per miss** increases for larger blocks, affecting overall **Average Memory Access Time (AMAT)**.

---

## 🔧 Ripes Setup Instructions (Crucial)

We keep **total cache size = 512 B** constant and only vary the **block size**.

### Step 1: Configure the Processor

1. Open **Ripes**.
2. Click the **Processor Selection** (chip icon).
3. Choose a **RISC-V 32-bit pipelined core with caches**, e.g.:

   * `RV32I 5-stage` / `RV32IM 5-stage`
4. Avoid single-cycle cores without cache options.

---

### Step 2: Configure the Data Cache (Common Settings)

For **all three experiments**:

1. Open **Component / Processor Configuration** (gear icon ⚙️).
2. In **Data Cache (D-Cache)**:

   * Enable D-Cache: ✅
   * **Cache size:** `512 B`
   * **Associativity:** `1` (direct-mapped, for simplicity)
   * Replacement policy: doesn’t matter much here (only compulsory misses).
3. I-Cache settings can be left default or disabled; we only care about **data cache**.

---

### Step 3: Vary the Block Size

You will repeat the run with three different **block sizes**:

1. **Scenario 1 – Small Block:**

   * Block / line size: **4 B** (1 word)

2. **Scenario 2 – Medium Block:**

   * Block / line size: **16 B** (4 words)

3. **Scenario 3 – Large Block:**

   * Block / line size: **64 B** (16 words)

All other D-cache settings remain constant.

---

## 📝 The Assembly Code

### Sequential Traversal Kernel

This code walks through a **contiguous array of 128 words** (512 bytes), reading each element exactly **once**, in order.

```asm
.data
    # Allocate a contiguous array of 128 words (512 bytes)
    # .zero 512 reserves 512 bytes initialized to 0
array:
    .zero 512    

.text
.globl main
main:
    la   s0, array        # s0 = base address of array
    li   t0, 128          # t0 = loop counter: 128 elements

traverse_loop:
    lw   t1, 0(s0)        # Load word at current address (sequential access)
    addi s0, s0, 4        # Move to next word (4 bytes)
    addi t0, t0, -1       # Decrement counter
    bnez t0, traverse_loop

    li   a7, 10
    ecall                 # Exit (semantics may vary in Ripes)
```

### What the Code Does

* Access pattern: `array[0], array[1], array[2], ..., array[127]`
* Each step:

  * **Load** one 32-bit word (4 bytes).
  * **Advance pointer** by 4 bytes.
* Total memory accesses: **128 loads**, strictly **sequential**.

Perfect scenario to demonstrate **spatial locality**.

---

## ✅ Expected Output

### Functional Behavior

* There is **no visible output** or modified memory we care about.
* The array starts as all zeros and is only **read**, not written.
* The experiment’s “output” is entirely in the **cache statistics** (hits/misses).

You will compare **miss rate** for the same program under three different **block sizes**.

---

## 📊 Quantitative Analysis per Scenario

We assume **total cache size = 512 B**, and the program accesses **exactly 512 B** of contiguous data (128 words).

### Scenario 1: 4-Byte Block (1 Word)

**Cache Settings:**

* Cache size: 512 B
* Block size: **4 B (1 word)**
* Number of blocks: 512 / 4 = **128 blocks**

**Behavior:**

* Each `lw` fetches a unique word.
* Block size is exactly one word, so:

  * `lw` at `array[0]` → miss, fetches only `array[0]`
  * `lw` at `array[1]` → miss, fetches only `array[1]`
  * ...
* Since each word is accessed **only once**, and no block contains multiple useful words, every access is a **compulsory miss**.

**Miss Rate:**

* Total accesses: 128
* Misses: 128
* Hits: 0

$$
\text{Miss Rate} = \frac{128}{128} = 1.0 = \mathbf{100%}
$$

The cache completely **fails to exploit spatial locality**, even though the pattern is perfectly sequential.

---

### Scenario 2: 16-Byte Block (4 Words)

**Cache Settings:**

* Cache size: 512 B
* Block size: **16 B (4 words)**
* Number of blocks: 512 / 16 = **32 blocks**

**Behavior:**

Each miss loads **4 consecutive words**:

* `array[0]` → miss, fetches words `[0,1,2,3]`

  * Next 3 accesses (`array[1]`, `array[2]`, `array[3]`) → **hits** (same block).
* `array[4]` → miss, fetches `[4,5,6,7]`

  * Next 3 accesses → hits.
* …

Pattern: **1 miss followed by 3 hits**, repeating.

**Miss Rate:**

* Group size: 4 accesses per block.
* Misses: 1 per 4 accesses.

$$
\text{Miss Rate} = \frac{1}{4} = 0.25 = \mathbf{25%}
$$

The cache now effectively **prefetches** the next 3 words automatically.

---

### Scenario 3: 64-Byte Block (16 Words)

**Cache Settings:**

* Cache size: 512 B
* Block size: **64 B (16 words)**
* Number of blocks: 512 / 64 = **8 blocks**

**Behavior:**

Each miss loads **16 consecutive words**:

* `array[0]` → miss, fetches `[0..15]`

  * Next 15 accesses (`array[1]` to `array[15]`) → hits.
* `array[16]` → miss, fetches `[16..31]`

  * Next 15 accesses → hits.
* …

Pattern: **1 miss followed by 15 hits**.

**Miss Rate:**

* Group size: 16 accesses per block.
* Misses: 1 per 16 accesses.

$$
\text{Miss Rate} = \frac{1}{16} = 0.0625 = \mathbf{6.25%}
$$

Now the cache is **aggressively exploiting spatial locality** for sequential code.

---

### Latency & AMAT Considerations

While larger blocks **reduce miss rate**, they also **increase miss penalty**:

* If the memory bus width is, say, **32 bits (4 bytes)**:

  * 4B block → 1 bus cycle per miss
  * 16B block → 4 bus cycles per miss
  * 64B block → 16 bus cycles per miss

Average Memory Access Time (AMAT):

$$
\text{AMAT} = \text{Hit Time} + \text{Miss Rate} \times \text{Miss Penalty}
$$

* Small block: high miss rate, low miss penalty.
* Large block: low miss rate, high miss penalty.

In real systems, there is a **sweet spot** for block size where **overall AMAT is minimized**.
Our experiment isolates the **miss rate part**, but you should mention in your report that **miss penalty grows with block size**.

---

## 🔍 How to Observe in Ripes

For each block size (4B, 16B, 64B):

1. Set D-Cache **block size** in configuration.
2. **Reset** the processor.
3. Load and assemble `sequential_traversal.asm`.
4. **Run** to completion.
5. Open **Statistics / Cache**:

   * Record:

     * D-Cache reads
     * D-Cache read hits
     * D-Cache read misses
     * Hit/Miss rate

**What you should see trend-wise:**

| Block Size | Expected Miss Rate | Explanation                             |
| ---------- | ------------------ | --------------------------------------- |
| 4 B        | ~100%              | 1 word per block, no spatial reuse      |
| 16 B       | ~25%               | 4 words per block, 1 miss per 4 loads   |
| 64 B       | ~6.25%             | 16 words per block, 1 miss per 16 loads |

---

## 🧪 Experiment Workflow

### Experiment 1: Small Block (4B)

* D-Cache: 512B, **4B block**, 1-way.
* Run program.
* Record:

  * Reads = ___
  * Misses = ___ (≈ 128)
  * Hits = ___ (≈ 0)
  * Miss Rate ≈ 100%

---

### Experiment 2: Medium Block (16B)

* D-Cache: 512B, **16B block**, 1-way.
* Run program.
* Record:

  * Reads = ___ (128)
  * Misses ≈ 128 / 4 = 32
  * Hits ≈ 96
  * Miss Rate ≈ 25%

---

### Experiment 3: Large Block (64B)

* D-Cache: 512B, **64B block**, 1-way.
* Run program.
* Record:

  * Reads = 128
  * Misses ≈ 128 / 16 = 8
  * Hits ≈ 120
  * Miss Rate ≈ 6.25%

---

### Optional: AMAT Discussion

If Ripes gives you cycle counts or if you assume different miss penalties, you can:

* Assign hypothetical miss penalties:

  * 4B block → 10 cycles
  * 16B block → 20 cycles
  * 64B block → 40 cycles
* Compute **AMAT** and show that the **best block size** depends on the balance between:

  * Miss rate
  * Miss penalty

---

## 📈 Why This Works

### Spatial Locality

Programs often access data that is **nearby** in memory:

* Iterating over arrays.
* Scanning buffers or strings.
* Walking structs with contiguous fields.

By increasing **block size**, the cache **automatically prefetches** nearby data:

* When you fetch `array[i]`, you also get `array[i+1]`, `array[i+2]`, etc.
* If the program actually accesses those neighbors, they become **cache hits**.

### The Trade-Off

* **Too small blocks:**

  * High miss rate, even for sequential accesses.
  * Low miss penalty per miss.

* **Too large blocks:**

  * Great for sequential accesses (like this experiment).
  * Bad for **sparse** or **random** patterns (lots of useless data fetched).
  * Larger miss penalty and potential **cache pollution**.

Real designs pick a **block size** that balances these factors for the **typical workloads**.

---

## 📚 Key Concepts

| Concept            | Definition                                                               |
| ------------------ | ------------------------------------------------------------------------ |
| Cache Block / Line | The smallest unit of data transferred between cache and main memory      |
| Spatial Locality   | Tendency of memory references to cluster in nearby addresses             |
| Compulsory Miss    | First access to a block; must miss because it wasn’t in cache yet        |
| Cache Pollution    | Filling the cache with data that won’t be used, pushing out useful data  |
| Miss Penalty       | Extra time required to service a cache miss (fetching block from memory) |
| AMAT               | Average Memory Access Time = Hit Time + Miss Rate × Miss Penalty         |

---

## 🚀 Extensions

To deepen the experiment:

* **Non-Sequential Access:**

  * Change the loop to access every **k-th** element (`addi s0, s0, 4*k`) and see when large blocks stop helping.

* **Different Cache Sizes:**

  * Use 1KB or 2KB caches and compare how block size interacts with **capacity**.

* **Add Writes:**

  * Change `lw` to a mix of `lw` and `sw`, then study how block size interacts with **write policies** (write-through / write-back).

* **Random Access Pattern:**

  * Use a pseudo-random index array to demonstrate **cache pollution** with very large blocks.

---

## 📄 License

This material is intended for **educational use** in labs, assignments, and self-study.
Feel free to adapt, reuse, and integrate it into your reports and Ripes experiments.
