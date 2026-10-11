# RV32I Processor

A small **32-bit RISC-V processor built in Verilog**, developed to make the path from an instruction to its result easy to understand.

The project brings together instruction fetch, decoding, arithmetic, memory access, branching, and register write-back in one compact design.

![Language](https://img.shields.io/badge/Language-Verilog-blue)
![Architecture](https://img.shields.io/badge/Architecture-RISC--V%2032--bit-orange)
![Focus](https://img.shields.io/badge/Focus-Learning%20%26%20Simulation-success)

## Contents

- [What this project does](#what-this-project-does)
- [How the processor works](#how-the-processor-works)
- [Instruction support](#instruction-support)
- [Project layout](#project-layout)
- [Run a simulation](#run-a-simulation)
- [Testbenches](#testbenches)
- [Current scope and limitations](#current-scope-and-limitations)
- [Development workflow](#development-workflow)

## What this project does

This project implements a simple, single-cycle-style processor datapath. The main data operations happen between clock edges, while the program counter and register file update on a rising clock edge.

The processor fetches 32-bit instructions from an instruction-memory file, executes supported instructions, and updates registers or data memory as needed. Its control-flow logic supports conditional branches and jumps.

The goal is clarity: each major task has its own Verilog module, so it is easier to read, test, and improve the design.

## How the processor works

Each instruction follows this path through the processor:

1. **Fetch** — The program counter (PC) holds the address of the current instruction. Instruction memory uses that address to read an instruction from `programs/instructions.mem`.
2. **Decode** — The processor separates the instruction into fields such as the opcode, source registers, destination register, and function bits. The control unit decides what kind of operation to perform.
3. **Read registers and build the immediate** — The register file supplies the source values. The immediate generator extracts and extends a constant encoded in the instruction when one is needed.
4. **Execute** — The ALU performs arithmetic or bit operations. A separate branch comparator checks the conditions used by branch instructions.
5. **Access data memory** — Load instructions read data from memory. Store instructions write register data to memory.
6. **Choose the result and next PC** — The processor selects what should be written back and which instruction address should come next.
7. **Write back** — On the clock edge, an enabled register write saves the result. The PC also updates to the selected next address.

### Choosing the next instruction

The current design selects the next PC in this order:

1. **JALR** — Jump to the address calculated from a source register plus an immediate, with bit 0 cleared.
2. **JAL** — Jump relative to the current PC.
3. **Taken branch** — Jump relative to the current PC if the branch condition is true.
4. **Otherwise** — Continue to the next sequential instruction, at `PC + 4`.

JAL and JALR save `PC + 4` in their destination register as a return address. Load instructions write memory data back to the register file; most other register-writing instructions write the ALU result.

## Processor diagram

> **Diagram coming soon.** This section is reserved for a block diagram showing the PC, instruction memory, control unit, immediate generator, register file, ALU, branch comparator, data memory, and the paths connecting them.

## Instruction support

The current control and datapath logic covers these instruction groups:

| Group | Supported instructions | Purpose |
| --- | --- | --- |
| Integer arithmetic and logic | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND | Operate on register values |
| Immediate arithmetic and logic | ADDI, SLLI, SLTI, SLTIU, XORI, SRLI, SRAI, ORI, ANDI | Operate on a register and an immediate |
| Loads | LB, LH, LW, LBU, LHU | Read byte, halfword, or word data |
| Stores | SB, SH, SW | Write byte, halfword, or word data |
| Conditional branches | BEQ, BNE, BLT, BGE, BLTU, BGEU | Choose a path based on a comparison |
| Upper-immediate | LUI, AUIPC | Build an upper constant or add it to the PC |
| Jumps | JAL, JALR | Change control flow and save a return address |

This is an implementation of a **subset of RV32I**, not a claim of complete compliance with every part of the RISC-V specification.

## Project layout

```text
.
├── programs/
│   └── instructions.mem      # Program loaded into instruction memory
├── rtl/
│   ├── ALU.v                 # Arithmetic and logic operations
│   ├── BranchComp.v          # Conditional branch comparisons
│   ├── ControlUnit.v         # Instruction decoding and control signals
│   ├── DataMemory.v          # Loads and stores
│   ├── ImmediateGenerator.v  # Builds instruction immediates
│   ├── InstructionMemory.v   # Fetches instructions
│   ├── ProgramCounter.v      # Stores the current instruction address
│   ├── RegisterFile.v        # General-purpose registers
│   └── Top.v                 # Connects the processor modules
└── tb/
    ├── ALU_tb.v
    ├── BranchComp_tb.v
    ├── ControlUnit_tb.v
    ├── DataMemory_tb.v
    ├── ImmediateGenerator_tb.v
    ├── InstructionMemory_tb.v
    ├── ProgramCounter_tb.v
    ├── RegisterFile_tb.v
    └── top_tb.v
```

Each `*_tb.v` file is a testbench for a module. The top-level testbench is named `Top_tb` inside `tb/top_tb.v`.

## Run a simulation

The examples below use [Icarus Verilog](https://steveicarus.github.io/iverilog/) to compile and run the testbenches. Run the commands from the **repository root**, because instruction memory loads `programs/instructions.mem` using a relative path.

### 1. Install the tools

Install Icarus Verilog. GTKWave is optional and can be used to inspect waveform files.

### 2. Create a folder for simulation outputs

```sh
mkdir -p sim
```

### 3. Run a unit test

For example, to test the control unit:

```sh
iverilog -g2012 -s ControlUnit_tb -o sim/control_unit_tb.vvp rtl/ControlUnit.v tb/ControlUnit_tb.v
vvp sim/control_unit_tb.vvp
```

The testbench reports failures and stops if a checked output does not match its expected value.

### 4. Run the top-level smoke test

```sh
iverilog -g2012 -s Top_tb -o sim/top_tb.vvp rtl/*.v tb/top_tb.v
vvp sim/top_tb.vvp
```

The current top-level test checks reset, instruction fetch for the first instruction, and the result of an ADD operation. It is a smoke test, not yet a complete test of the whole program.

### 5. Inspect waveforms (optional)

Testbenches generate `.vcd` waveform files. Open a generated waveform in GTKWave to inspect signals over time. Some testbenches write their waveform directly into the repository root, while others write it under `sim/`.

### Available unit testbenches

| Testbench | Module covered |
| --- | --- |
| `tb/ALU_tb.v` | ALU operations |
| `tb/BranchComp_tb.v` | Branch comparisons |
| `tb/ControlUnit_tb.v` | Instruction control signals, including valid and invalid JALR encodings |
| `tb/DataMemory_tb.v` | Load/store data-memory behavior |
| `tb/ImmediateGenerator_tb.v` | Immediate generation |
| `tb/InstructionMemory_tb.v` | Instruction fetch |
| `tb/ProgramCounter_tb.v` | PC reset and updates |
| `tb/RegisterFile_tb.v` | Register-file behavior |
| `tb/top_tb.v` | Basic processor integration smoke test |

These are currently individual testbenches; there is not yet a single command that runs the full test suite.

## Current scope and limitations

- The processor implements a useful subset of RV32I instructions; unsupported instructions are not a complete architectural exception-handling system.
- JALR clears the least-significant bit of the calculated target. This project does not yet implement instruction-address-misaligned exceptions, so example programs should use valid, 4-byte-aligned instruction targets.
- The current top-level testbench does not yet run through the complete program or verify JAL/JALR execution end to end.
- Simulation results should be treated as unverified until the relevant testbenches have been run with a Verilog simulator.

## Development workflow

When adding or changing an instruction, a simple workflow helps keep the project reliable:

1. **Update the RTL** — Make the smallest change needed in the relevant module or modules.
2. **Add or update a unit test** — Check the instruction's decoding, immediate, ALU operation, memory behavior, or comparison as appropriate.
3. **Run the relevant testbench** — Then run the top-level smoke test to catch basic integration problems.
4. **Review waveforms when needed** — Use GTKWave to follow important signals such as the PC, instruction, ALU result, and write-back data.
5. **Commit a focused change** — Use a clear commit message and keep unrelated edits separate.
6. **Update this README** — Keep the supported instruction list, commands, and known limitations accurate as the design evolves.

---

Built as a learning-focused Verilog processor project. The design and documentation will evolve together as more instruction behavior and verification are added.
