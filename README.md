# 🖥️ RISC-V Computer Architecture Labs for Ripes

A comprehensive collection of **20 hands-on experiments** demonstrating fundamental computer architecture concepts using the [Ripes](https://github.com/mortbopet/Ripes) RISC-V simulator.

This repository serves as a complete laboratory curriculum for understanding **pipelining**, **cache memory**, **hazards**, **branch prediction**, **memory management**, and **performance optimization** in modern processors.

---

## 📚 Table of Contents

- [Overview](#overview)
- [Getting Started](#getting-started)
- [Experiments by Category](#experiments-by-category)
  - [Pipeline Architecture](#-pipeline-architecture)
  - [Pipeline Hazards](#-pipeline-hazards)
  - [Cache Memory](#-cache-memory)
  - [Memory Management](#-memory-management)
  - [Branch Prediction](#-branch-prediction)
  - [Performance Optimization](#-performance-optimization)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [How to Use](#how-to-use)
- [Learning Outcomes](#learning-outcomes)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

This repository contains RISC-V assembly programs designed to run in the **Ripes simulator**, providing visual and quantitative insights into how modern CPUs work. Each experiment includes:

- 📝 Detailed README with theory and setup instructions
- 🔧 Assembly code files (`.asm`) ready to load in Ripes
- 📊 Expected results and metrics to observe
- 🎯 Clear learning objectives

---

## Getting Started

### 1. Install Ripes

Download Ripes from the official repository:
- **GitHub**: [https://github.com/mortbopet/Ripes](https://github.com/mortbopet/Ripes)
- **Online Version**: [https://ripes.me](https://ripes.me)

### 2. Clone This Repository

```bash
git clone https://github.com/JustineBijuPaul/ripes-projects.git
cd ripes-projects
```

### 3. Load an Experiment

1. Open Ripes
2. Navigate to the **Editor** tab
3. Load any `.asm` file from the experiments
4. Follow the README in each folder for specific setup instructions

---

## Experiments by Category

### 🔄 Pipeline Architecture

| Experiment | Description | Key Concepts |
|------------|-------------|--------------|
| [Single-Cycle vs 5-Stage Pipeline Performance](./Single-Cycle%20vs%205-Stage%20Pipeline%20Performance/) | Compare single-cycle and pipelined processors | CPI, Speedup, Pipeline stages |
| [Pipeline Scheduling & Loop Unrolling](./Pipeline%20Scheduling%20%26%20Loop%20Unrolling/) | Optimize code to eliminate pipeline stalls | Loop unrolling, Instruction scheduling |
| [Multi-Loop Pipeline Performance Study](./Multi-Loop%20Pipeline%20Performance%20Study/) | Study nested vs flat loop performance | Control flow efficiency, Branch prediction pollution |

### ⚠️ Pipeline Hazards

| Experiment | Description | Key Concepts |
|------------|-------------|--------------|
| [Pipeline Hazard Demonstration](./Pipeline%20Hazard%20Demonstration/) | Visualize RAW hazards and solutions | RAW hazards, Forwarding, Stalling |
| [Load-Use Hazard Detection & Fixing](./Load-Use%20Hazard%20Detection%20%26%20Fixing/) | The critical load-use hazard problem | Load-use hazard, Hardware vs software solutions |
| [Arithmetic Program Optimization](./Arithmetic%20Program%20Optimization/) | ALU-to-ALU forwarding demonstration | Data forwarding, Dependency chains |
| [Control vs Data Hazard Impact Study](./Control%20vs%20Data%20Hazard%20Impact%20Study/) | Quantify hazard contributions separately | Hazard isolation, Performance analysis |
| [Branch Delay Penalty Study](./Branch%20Delay%20Penalty%20Study/) | Control hazards and branch penalties | Pipeline flush, Branch prediction |
| [Function Call Overhead Analysis](./Function%20Call%20Overhead%20Analysis/) | Cost of function calls in pipelines | JAL/JALR, Stack frames, Control hazards |

### 💾 Cache Memory

| Experiment | Description | Key Concepts |
|------------|-------------|--------------|
| [Cache Block Size Impact on Miss Rate](./Cache%20Block%20Size%20Impact%20on%20Miss%20Rate/) | Effect of block size on cache performance | Spatial locality, Block size trade-offs |
| [Cache Mapping Technique](./Cache%20Mapping%20Technique/) | Direct-mapped vs set-associative caches | Conflict misses, Associativity |
| [Array Size Vs Cache Miss Analysis](./Array%20Size%20Vs%20Cache%20Miss%20Analysis/) | Cache thrashing with matrix multiplication | Working set, Thrashing, Loop tiling |
| [Instruction Vs Data Cache Performance](./Instruction%20Vs%20Data%20Cache%20Performance/) | I-Cache vs D-Cache behavior | Harvard architecture, Cache pressure |

### 🧠 Memory Management

| Experiment | Description | Key Concepts |
|------------|-------------|--------------|
| [Memory Locality Performance Study](./Memory%20Locality%20Performance%20Study/) | Sequential vs random access patterns | Spatial locality, Temporal locality |
| [Alignment Impact on Memory Performance](./Alignment%20Impact%20on%20Memory%20Performance/) | Aligned vs misaligned memory access | Memory alignment, Exception handling |
| [Stack Vs Heap Memory Access Speed Test](./Stack%20Vs%20Heap%20Memory%20Access%20Speed%20Test/) | Stack locality vs heap fragmentation | Stack frames, Pointer chasing |
| [TLB Impact on Memory Access Time](./TLB%20Impact%20on%20Memory%20Access%20Time/) | TLB thrashing and page table walks | Virtual memory, TLB, Page faults |
| [Page Fault Experimentation Using Virtual Memory](./Page%20Fault%20Experimentation%20Using%20Virtual%20Memory/) | Trap handling and page fault recovery | Exceptions, CSRs, Trap handlers |

### 🎯 Branch Prediction

| Experiment | Description | Key Concepts |
|------------|-------------|--------------|
| [Static Branch Prediction Analysis](./Static%20Branch%20Prediction%20Analysis/) | Compare static prediction strategies | Always-taken, BTFNT, Misprediction rate |

### ⚡ Performance Optimization

| Experiment | Description | Key Concepts |
|------------|-------------|--------------|
| [String Handling Performance](./String%20Handling%20Performance/) | SWAR-optimized string operations | SIMD, Word-wise processing, Alignment |

---

## Repository Structure

```
ripes-projects/
├── README.md                                    # This file
├── Alignment Impact on Memory Performance/
│   ├── README.md
│   └── aligned_vs_misaligned.asm
├── Arithmetic Program Optimization/
│   ├── readme.md
│   └── dependency_chain.asm
├── Array Size Vs Cache Miss Analysis/
│   ├── README.md
│   ├── matmul_naive.asm
│   └── matmul_tiled.asm
├── Branch Delay Penalty Study/
│   ├── readme.md
│   └── count_evens.asm
├── Cache Block Size Impact on Miss Rate/
│   ├── README.md
│   └── sequential_traversal.asm
├── Cache Mapping Technique/
│   ├── README.md
│   └── conflict_access.asm
├── Control vs Data Hazard Impact Study/
│   ├── readme.md
│   ├── hazards_combined.asm
│   └── hazards_control_only.asm
├── Function Call Overhead Analysis/
│   ├── readme.md
│   ├── func_call.asm
│   └── func_inline.asm
├── Instruction Vs Data Cache Performance/
│   ├── README.md
│   ├── icache_pressure.asm
│   └── dcache_pressure.asm
├── Load-Use Hazard Detection & Fixing/
│   ├── readme.md
│   ├── hazard_demo.asm
│   └── hazard_fixed.asm
├── Memory Locality Performance Study/
│   ├── README.md
│   ├── sequential_access.asm
│   └── random_access_lcg.asm
├── Multi-Loop Pipeline Performance Study/
│   ├── readme.md
│   ├── nested_loop.asm
│   └── flat_loop.asm
├── Page Fault Experimentation Using Virtual Memory/
│   ├── README.md
│   └── page_fault_demo.asm
├── Pipeline Hazard Demonstration/
│   ├── README.md
│   ├── raw_hazards.asm
│   └── manual_stalls.asm
├── Pipeline Scheduling & Loop Unrolling/
│   ├── readme.md
│   ├── Naive_Loop.asm
│   └── optimized_loop.asm
├── Single-Cycle vs 5-Stage Pipeline Performance/
│   ├── readme.md
│   └── sum_loop.asm
├── Stack Vs Heap Memory Access Speed Test/
│   ├── README.md
│   ├── stack_access.asm
│   └── heap_access.asm
├── Static Branch Prediction Analysis/
│   ├── readme.md
│   └── branch_analysis.asm
├── String Handling Performance/
│   ├── README.md
│   ├── strcpy_naive.asm
│   └── strcpy_swar.asm
└── TLB Impact on Memory Access Time/
    ├── README.md
    └── tlb_thrash.asm
```

---

## Prerequisites

### Software Requirements
- **Ripes Simulator** (v2.0 or later recommended)
- Basic understanding of assembly language
- Familiarity with computer architecture concepts

### Recommended Background Knowledge
- CPU pipeline stages (IF, ID, EX, MEM, WB)
- Cache memory hierarchy
- RISC-V instruction set basics
- Basic understanding of hazards and stalls

---

## How to Use

### For Students

1. **Start with Pipeline Basics**: Begin with "Single-Cycle vs 5-Stage Pipeline Performance" to understand the fundamental differences
2. **Progress to Hazards**: Move through the hazard experiments to understand why pipelines stall
3. **Explore Cache Memory**: Learn how memory hierarchy affects performance
4. **Advanced Topics**: Tackle branch prediction and optimization experiments

### For Instructors

Each experiment is designed as a standalone lab that can be:
- Assigned as homework with the README as a guide
- Used for in-class demonstrations
- Extended with custom parameters and analysis questions

### Typical Workflow

```
1. Read the experiment's README.md
2. Configure Ripes as specified
3. Load the .asm file(s)
4. Run the simulation
5. Collect metrics (Cycles, CPI, Cache hits/misses)
6. Analyze and compare results
7. Document findings
```

---

## Learning Outcomes

After completing these experiments, you will be able to:

### Pipeline Understanding
- ✅ Explain the 5-stage RISC-V pipeline operation
- ✅ Identify and resolve data hazards (RAW, WAR, WAW)
- ✅ Understand forwarding and stalling mechanisms
- ✅ Calculate CPI and speedup metrics

### Cache Memory
- ✅ Configure and analyze cache behavior
- ✅ Understand spatial and temporal locality
- ✅ Compare different cache mapping techniques
- ✅ Optimize code for cache performance

### Memory Management
- ✅ Understand virtual memory concepts
- ✅ Analyze TLB behavior and page faults
- ✅ Recognize memory alignment importance

### Optimization
- ✅ Apply loop unrolling and scheduling techniques
- ✅ Minimize branch mispredictions
- ✅ Write cache-friendly code
- ✅ Understand function call overhead

---

## Key Metrics to Observe in Ripes

| Metric | Description | Where to Find |
|--------|-------------|---------------|
| **Cycles** | Total clock cycles executed | Statistics panel |
| **Instructions** | Total instructions retired | Statistics panel |
| **CPI** | Cycles Per Instruction | Statistics panel |
| **Cache Hits** | Successful cache accesses | Cache statistics |
| **Cache Misses** | Cache access failures | Cache statistics |
| **Hit Rate** | Hits / Total accesses | Cache statistics |
| **Pipeline Bubbles** | Stall cycles inserted | Pipeline visualization |

---

## Contributing

Contributions are welcome! Please feel free to:

1. **Report Issues**: Found a bug or have a suggestion? Open an issue
2. **Add Experiments**: Create new experiments following the existing format
3. **Improve Documentation**: Help clarify explanations or add examples
4. **Fix Bugs**: Submit pull requests for any corrections

### Contribution Guidelines

- Follow the existing folder structure
- Include a comprehensive README with each experiment
- Test all assembly code in Ripes before submitting
- Document expected results and metrics

---

## References

- [Ripes Simulator](https://github.com/mortbopet/Ripes)
- [RISC-V Specification](https://riscv.org/specifications/)
- Patterson & Hennessy - *Computer Organization and Design: RISC-V Edition*
- Hennessy & Patterson - *Computer Architecture: A Quantitative Approach*

---

## License

This project is open source and available for educational purposes.

---

## Acknowledgments

- **Ripes Development Team** for creating an excellent educational simulator
- **RISC-V Foundation** for the open instruction set architecture
- All contributors and students who have helped improve these experiments

---

<p align="center">
  <b>Happy Learning! 🎓</b><br>
  <i>Understanding computer architecture one pipeline stage at a time.</i>
</p>
