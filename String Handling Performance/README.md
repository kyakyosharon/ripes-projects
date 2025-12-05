# Capstone Project: High-Performance String Manipulation (SWAR-Optimized `strcpy` / `strlen`)

A complete Ripes-based project that synthesizes everything you learned: **alignment**, **spatial locality**, **cache block behavior**, **stall minimization**, and **word-wide SIMD Within A Register (SWAR)**.

This is a real low-level optimization used in **glibc**, **musl**, and **BSD libc**.

---

# 📁 Project Files

| File               | Description                               |
| ------------------ | ----------------------------------------- |
| `strcpy_naive.asm` | Baseline byte-by-byte version             |
| `strcpy_swar.asm`  | Optimized 32-bit SWAR (word-wise) version |

You will load each file separately in Ripes to compare performance and verify correctness.

---

# 🎯 What This Demonstrates

### ✔ SWAR (SIMD Within A Register)

Process **4 bytes at a time** using 32-bit registers and bit-pattern magic.

### ✔ Alignment & Spatial Locality

By aligning strings to 4 bytes, loads become **aligned L1 hits** with no penalties.

### ✔ Cache-Friendly Bulk Copy

Copying entire words improves bandwidth utilization from **25% → 100%** on RV32.

### ✔ Null Detection Without Branching

Detect `'\0'` inside a 32-bit word using bit arithmetic, avoiding per-byte branches.

### ✔ Pipeline Efficiency

SWAR loop has no pointer-chasing dependence chain and no misaligned penalties.

---

# 🔧 Ripes Setup Instructions

### Step 1 — Choose the CPU

1. Open **Ripes**
2. CPU icon → select:

   * `RV32IM 5-stage` (supports multiplication for SWAR math)

### Step 2 — Enable Correct Memory Model

* Keep default cache settings
* Ensure `Support Misaligned Access = ON` (we enforce alignment manually)

### Step 3 — Assembler Mode

* Set editor to **RV32IM**
* We need multiplication instructions inside SWAR logic.

---

# 11.1 Project Overview

Standard `strcpy` works like:

```c
while(*dst++ = *src++);
```

This copies **1 byte per iteration**, even though RV32 can load/store **4 bytes at once**.

On a 32-bit CPU:

| Operation | Bytes Loaded | Bandwidth Used |
| --------- | ------------ | -------------- |
| `lb`      | 1 byte       | 25%            |
| `lw`      | 4 bytes      | 100%           |

SWAR uses 32-bit words and bit-hacks to check for null bytes inside each word.

---

# 11.2 Phase 1 — Naive Baseline (`strcpy_naive`)

This is your baseline for comparison.

```asm
# void strcpy_naive(char *dst, const char *src)
.global strcpy_naive
strcpy_naive:
    lb t0, 0(a1)          # src[i]
    sb t0, 0(a0)          # dst[i]
    beqz t0, end_naive
    addi a0, a0, 1
    addi a1, a1, 1
    j strcpy_naive

end_naive:
    ret
```

**Performance:**

* For a 100-byte string:
  → 100 loads, 100 stores, 100 branches
  → ~600–800 cycles

This is your **baseline**.

---

# 11.3 Phase 2 — SWAR Theory (Magic Null-Detection Trick)

Given a 32-bit word `X`, we check if any of the four bytes is zero:

$$
Y = (X - 0x01010101) \ \& \ (\sim X) \ \& \ 0x80808080
$$

If **Y ≠ 0**, then `X` contains at least one null byte.

### Why This Works

| Step             | Purpose                                           |
| ---------------- | ------------------------------------------------- |
| `X - 0x01010101` | Underflows if any byte = 0x00, making its MSB = 1 |
| `~X`             | Converts zero bytes into 0xFF (MSB = 1)           |
| `& 0x80808080`   | Keeps only MSBs for each byte                     |
| Final `&` chain  | Produces MSB bit = 1 only where X had a zero byte |

This is constant-time null detection used in optimized libc functions.

---

# 11.4 Phase 3 — Ripes Assembly Implementation Guide

---

## **Step 1 — Data Setup**

```asm
.data
    .align 4                 # Crucial for aligned 32-bit loads
src_str:
    .string "RISC-V Architecture is Powerful! This is a long string..."
    .align 4
dst_buf:
    .space 256
```

This ensures the SWAR algorithm never performs misaligned loads → no misalignment traps.

---

## **Step 2 — Main Program**

```asm
.text
.globl main
main:
    la a0, dst_buf
    la a1, src_str

    call strcpy_swar

    li a7, 10
    ecall
```

---

## **Step 3 — Load SWAR Constants**

```asm
strcpy_swar:
    li t1, 0x01010101     # subtractor
    li t2, 0x80808080     # mask
```

---

## **Step 4 — Optimized SWAR Loop**

```asm
loop_swar:
    lw t0, 0(a1)          # Load 4 bytes

    # SWAR null detection
    sub t3, t0, t1        # t3 = X - 0x01010101
    not t4, t0            # t4 = ~X
    and t3, t3, t4
    and t3, t3, t2        # t3 = high bits only

    bnez t3, found_null   # Null exists in this word

    # No null → copy 4 bytes
    sw t0, 0(a0)
    addi a0, a0, 4
    addi a1, a1, 4
    j loop_swar
```

This loop processes **4 bytes per iteration** with **no branches inside**.

---

## **Step 5 — Tail Handling (Byte-Wise)**

If the null is in the current 4-byte word, switch to classic byte-copy:

```asm
found_null:
    lb t5, 0(a1)
    sb t5, 0(a0)
    beqz t5, done
    addi a0, a0, 1
    addi a1, a1, 1
    j found_null

done:
    ret
```

---

# 11.5 Performance Verification in Ripes

### ✔ Step 1 — Run the Simulation

Click **Run**.

### ✔ Step 2 — Check Correctness

Go to **Memory → Data Memory View**, navigate to `dst_buf`.

Verify that it contains the same string as `src_str`.

---

# 📊 Expected Performance Results

### For 100-byte string:

| Version | Iterations | Cycles  | Improvement     |
| ------- | ---------- | ------- | --------------- |
| Naive   | 100        | 600–800 | —               |
| SWAR    | 25         | 200–250 | **3–4× faster** |

Why?

* SWAR reduces loop iterations by 4×
* Fewer branches → fewer pipeline flushes
* Only one load/store per 4 bytes
* Alignment ensures each `lw` is an L1 hit

---

# 📚 Why This Project Combines All Prior Concepts

| Concept                    | Role in SWAR Project                                    |
| -------------------------- | ------------------------------------------------------- |
| **Alignment**              | Required for fast 32-bit loads                          |
| **Spatial Locality**       | Strings are contiguous → perfect for SWAR               |
| **Temporal Locality**      | dst/src buffers remain hot in L1                        |
| **Cache Blocks**           | Each load fetches one full 16-byte block (with 4 words) |
| **Pipeline Hazards**       | SWAR loop avoids dependence stalls                      |
| **Misalignment penalties** | Avoided using `.align 4`                                |
| **Block-based thinking**   | SWAR = treat strings in blocks of 4 bytes               |

This is a true synthesis of memory architecture principles.

---

# 🚀 Extensions & Challenges

To fully match glibc-level performance:

### Level 1

* Add alignment prologue:

  * Copy bytes until `src` & `dst` are both 4-byte aligned

### Level 2

* Add 8-byte SWAR (RV64)

### Level 3

* Write a SWAR-based `strlen`:

  * Same SWAR null-detection logic
  * Count bytes until null in blocks of 4

### Level 4

* Add unrolling:

  * Copy 16 bytes (4 words) per iteration

### Level 5

* Add block prefetching:

  * Tell the CPU which blocks you'll use next

---

# 📄 License

This capstone project is designed for educational use in computer architecture, compiler, and systems programming courses.
You are free to modify, extend, and integrate it into your Ripes lab work, reports, and final-year projects.
