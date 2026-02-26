# raiden

A fully pipelined, 64-bit RISC-V soft-core processor written from scratch in SystemVerilog. 

This project implements the foundational **RV64I** base integer instruction set, alongside the **Zba** bit-manipulation extension, optimized across a classic 5-stage pipeline

## Key Hardware Features
* **Architecture:** 64-bit RISC-V (RV64I)
* **Pipeline:** 5-Stage (Fetch, Decode, Execute, Memory, Writeback)
* **Extensions:** Zba (Address Generation / Shift-and-Add operations)
* **Hazard Mitigation:** Fully associative Data Forwarding Unit (resolves RAW hazards)
  * Load-Use Hazard Detection Unit
  * Control Hazard flushing for branch/jump resolution
* **Branching:** Evaluates standard conditional branches (`BEQ`, `BNE` etc.) and unconditional jumps (`JAL`, `JALR`).

## Directory Structure
* `design/` - Contains all SystemVerilog RTL modules (ALU, Register File, Pipeline Registers, Hazard/Forwarding Units).
* `testbench/` - Contains the simulation environment, including memory initialization and the top-level `tb_processor.sv` test suite.

---

## Prerequisites

To compile, simulate, and view the waveforms for this processor, you will need **Icarus Verilog** and **GTKWave**

## Running the Simulation 
This project includes a `Makefile` to automate the build and simulation process

### 1. Build and Run 
Compiles the SystemVerilog source files and runs the testbench simulation in the terminal
```
make 
```
### 2. View Waveforms 
Compiles the design, runs the simulation to generate a `waveform.vcd` file, and automatically opens it in GTKWave
```
make wave
```
### 3. Clean directory  
Removes the compiled `raiden_sim` executable and generated waveform files
```
make clean
```

