# RISC-V Single Cycle Microarchitecture

## Introduction

This repository provides an in-depth look at the design and implementation of a RISC-V single-cycle microarchitecture, including detailed explanations of the ALU, control unit, instruction formats, datapath, and state elements. 

---

## 1. Arithmetic Logic Unit (ALU)

### 1.1 Introduction

The ALU is responsible for performing arithmetic and logical operations. It accepts two 32-bit inputs (`A` and `B`) and produces a 32-bit `Result` and a `Zero` flag (set to 1 if the result is zero). The operation is selected by a 3-bit `ALUControl` signal.

Supported operations include:
- **Arithmetic:** ADD, SUB, SLT (set less than)
- **Logical:** AND, OR

### 1.2 Block Diagram and Operation

- **Operation Selection:**  
  - `ALUControl[1] = 1` → Logical operations  
  - `ALUControl[1] = 0` → Arithmetic operations  
  - `ALUControl[0] = 0` → Addition  
  - `ALUControl[0] = 1` → Subtraction  
  - `ALUControl[2]` selects if only the MSB is used (for SLT)
- **Multiplexer:** A 4-input multiplexer selects the output group based on `ALUControl[1:0]`.
- **Zero Flag:** Generated when the result is all zeroes.

> **Note:** Some `ALUControl` values are undefined and can be ignored for circuit simplification.

---

## 2. Control Unit

### 2.1 Instruction Formats

RISC-V uses 32-bit instructions and supports several formats:

| Format | Fields | Description |
|--------|--------|-------------|
| R-Type | op, rs1, rs2, rd, funct3, funct7 | 3 registers (2 sources, 1 destination) |
| I-Type | op, rs1, rd, funct3, imm         | 2 registers, 12-bit immediate         |
| S-Type | op, rs1, rs2, funct3, imm        | 2 registers, 12-bit immediate (split) |
| B-Type | op, rs1, rs2, funct3, imm        | 2 registers, 12-bit immediate (split) |
| U-Type | op, rd, imm                      | 20-bit immediate                      |
| J-Type | op, rd, imm                      | 20-bit immediate (jump)               |

#### Example: R-Type Instruction Format

| Field   | Bits  | Description          |
|---------|-------|----------------------|
| opcode  | 6-0   | Operation code       |
| rd      | 11-7  | Destination register |
| funct3  | 14-12 | Function (3 bits)    |
| rs1     | 19-15 | Source register 1    |
| rs2     | 24-20 | Source register 2    |
| funct7  | 31-25 | Function (7 bits)    |

### 2.2 Block Diagram

The control unit computes control signals from the opcode and function fields (`Instr[31:25]`, `Instr[14:12]`, `Instr[6:0]`). It is divided into two main blocks:
- **MAIN Decoder:** Generates most control signals based on the opcode.
- **ALU Decoder:** Determines the ALU operation using `ALUOp` and function fields.

### 2.3 MAIN Decoder

- Summarizes control signals as a function of the opcode.
- All R-type instructions use the same main decoder values; differences are handled by the ALU decoder.
- For instructions not writing to the register file (e.g., S-type, B-type), certain control signals are "don't care".

### 2.4 ALU Decoder

- The main decoder outputs a 2-bit `ALUOp` signal.
- The ALU decoder uses `ALUOp`, function fields, and opcode bits to compute `ALUControl`.

| ALUOp | Meaning                       |
|-------|-------------------------------|
| 00    | ADD                           |
| 01    | SUBTRACT                      |
| 10    | Examine funct fields/opcode    |
| 11    | N/A                           |

---

## 3. Designing Microarchitecture-I

### 3.1 State Elements

The microarchitecture consists of the following state elements:

- **Program Counter (PC):** 32-bit register pointing to the current instruction.
- **Register File:** 32 registers, each 32-bit wide.
  - Two 5-bit read ports (A1, A2) outputting 32-bit data (RD1, RD2).
  - One 5-bit write port (A3), 32-bit input (WD), write enable (WE3), clocked.
- **Instruction Memory:** Single read port, 32-bit address input, 32-bit output.
- **Data Memory:** Single read/write port, write enable (WE), 32-bit address/data.

> **All state changes occur on the rising edge of the clock. The processor is a synchronous sequential circuit.**

---

## 4. Designing Microarchitecture-II: Load Word (lw)

### 4.1 Introduction

The `lw` instruction (I-type) loads data from memory into a register. It uses two registers and a 12-bit immediate.

### 4.2 Datapath for Load Word

- **Immediate Handling:** The 12-bit immediate is sign-extended to 32 bits to support both positive and negative offsets.
- **ALU Operation:** Adds the base address (from `rs1`) and the offset (from the immediate).
- **Control Signals:** `ALUControl` set to 000 (addition).
- **Data Flow:** Data read from memory is written to the destination register on the clock edge.
- **PC Update:** PC increments by 4 after each instruction.

#### Sign Extension Example

| Original (12 bits) | Sign-Extended (32 bits) |
|--------------------|------------------------|
| 0000 1010 0101     | 0000...0000 1010 0101  |
| 1010 1100 1101     | 1111...1010 1100 1101  |

---

## 5. Designing Microarchitecture-III: Store Word (sw)

### 5.1 Introduction

The `sw` instruction (S-type) stores data from a register to memory.

### 5.2 Datapath for Store Word

- **Immediate Handling:** The 12-bit immediate is split and concatenated from instruction fields, then sign-extended.
- **ALU Operation:** Adds the base address (from `rs1`) and the offset (from the immediate).
- **Data Flow:** Data from `rs2` is written to memory at the computed address.
- **Control Signals:** `MemWrite=1` enables memory write; `ALUControl=000` (addition); `RegWrite=0` (no register write).

---

## 6. Designing Microarchitecture-IV: R-Type Instructions

### 6.1 Introduction

R-Type instructions use three registers (two sources, one destination) and perform operations determined by the opcode, `funct3`, and `funct7`.

### 6.2 Datapath for R-Type

- **ALU Operation:** Performs the specified operation on the two source registers.
- **Multiplexers:**
  - Selects ALU input `SrcB` from either register file or sign-extended immediate (`ALUSrc`).
  - Selects register file write data from `ALUResult` (R-type) or `ReadData` (load) (`ResultSrc`).
- **Store Instructions:** `ResultSrc` is don't care since no register write occurs.


---
