#  8-Bit Microprocessor (Verilog)

A fully functional **8-bit microprocessor** designed and implemented in Verilog HDL. The processor integrates a custom ALU, a synchronous Register File, and a Control Unit — all wired together through a top-level module with a complete testbench for simulation and verification.

---

##  Table of Contents

- [Overview](#overview)
- [Top-Level Architecture](#top-level-architecture)
- [Module Breakdown](#module-breakdown)
  - [ALU — Arithmetic Logic Unit](#alu--arithmetic-logic-unit)
  - [Control Unit](#control-unit)
  - [Register File](#register-file)
  - [Top Module](#top-module)
- [Datapath Diagram](#datapath-diagram)
- [ALU Operation Flow](#alu-operation-flow)
- [Instruction Set Architecture (ISA)](#instruction-set-architecture-isa)
- [Flag Register](#flag-register)
- [Simulation Waveform Flow](#simulation-waveform-flow)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Testbench](#testbench)
- [Example Simulation Output](#example-simulation-output)
- [Future Improvements](#future-improvements)
- [License](#license)

---

##  Overview

| Feature                  | Specification                                                    |
|--------------------------|------------------------------------------------------------------|
| Data Bus Width           | 8 bits                                                           |
| Register File            | 16 × 8-bit general-purpose registers                             |
| ALU Operations           | 10 (ADD, SUB, AND, OR, XOR, NOT, SHL, SHR, GT, EQ)               |
| Opcode Width             | 4 bits                                                           |
| Source / Dest Addr Width | 3 bits each                                                      |
| Flags                    | Z (Zero), C (Carry), N (Negative), V (Overflow)                  |
| Clock                    | Synchronous (posedge clk)                                        |
| Reset                    | Active-high synchronous reset                                    |
| HDL Language             | Verilog                                                          |

---

##  Top-Level Architecture

```
                     ┌────────────────────────────────────────────────────────┐
                     │                     TOP MODULE                         │
                     │                                                        │
 clk ───────────────►│                                                        │
 rst ───────────────►│  ┌─────────────────┐      ┌─────────────────────────┐  │
 opcode[3:0] ───────►│  │                 │      │                         │  │
 source1[2:0] ──────►│  │  CONTROL UNIT   ├─────►│     REGISTER FILE       │  │
 source2[2:0] ──────►│  │                 │ rs1  │      (16 × 8-bit)       │  │
 destination[2:0] ──►│  │  → alu_op[3:0] │ rs2  │  r_addr1 ──► r_data1     │  │
                     │  │  → reg_write   │ rd   │  r_addr2 ──► r_data2     │  │
                     │  │  → use_imm     │──────►│  w_addr  ◄── rd         │  │
                     │  │  → flags_en    │      │  w_data  ◄── result       │  │
                     │  └────────┬────────┘      └───────────┬─────────────┘  │ 
                     │           │ alu_op                     │ r_data1       │
                     │           │                            │ r_data2       │
                     │           │                  ┌─────────▼─────────┐     │
                     │           │      use_imm ───►│  MUX (B select)   │     │
                     │           │                  │  0 → r_data2      │     │
                     │           │                  │  1 → 8'd1 (imm)   │     │
                     │           │                  └─────────┬─────────┘     │
                     │           │                            │               │
                     │           │                  ┌─────────▼─────────┐     │
                     │           └─────────────────►│       ALU         ├───► │ result[7:0]
                     │                              │   A = r_data1     ├───► │ Z, C, N, V
                     │                              │   B = mux_out     │     │
                     │                              └───────────────────┘     │
                     └────────────────────────────────────────────────────────┘
```

---

##  Module Breakdown

### ALU — Arithmetic Logic Unit

**File:** `alu.v`

The ALU is a purely **combinational** module. It takes two 8-bit operands and a 4-bit operation selector, and produces an 8-bit result along with 4 status flags.

```
        ┌──────────────────────────────────────────────────┐
A[7:0]─►│                                                  ├──► result[7:0]
B[7:0]─►│                   A L U                          ├──► Z  (Zero)
        │                                                  ├──► C  (Carry)
        │  ┌──────────────────────────────────────────┐    ├──► N  (Negative)
        │  │  0000 → ADD    │  0101 → NOT             │    └──► V  (Overflow)
        │  │  0001 → SUB    │  0110 → SHL (shift left) │
alu_op─►│  │  0010 → AND    │  0111 → SHR (shift right)│
 [3:0]  │  │  0011 → OR     │  1000 → GT  (A > B)      │
        │  │  0100 → XOR    │  1001 → EQ  (A == B)     │
        │  └──────────────────────────────────────────┘
        └──────────────────────────────────────────────────┘
```

**Flag Logic:**

| Flag | Name     | Set When                                            |
|------|----------|-----------------------------------------------------|
| `Z`  | Zero     | `result == 8'b0`                                    |
| `C`  | Carry    | ADD: carry-out of bit 7 / SUB: borrow / SHL: A[7] / SHR: A[0] |
| `N`  | Negative | `result[7] == 1` (MSB, two's complement sign bit)   |
| `V`  | Overflow | Signed overflow on ADD/SUB only                     |

---

### Control Unit

**File:** `control_unit.v`

A **synchronous** (clocked) opcode decoder. On every rising clock edge it reads the 4-bit `opcode` and drives all downstream control signals.

```
           ┌──────────────────────────────────────────────────┐
clk ──────►│                                                  ├──► reg_write
rst ──────►│           C O N T R O L   U N I T               ├──► rs1 [2:0]
opcode ───►│                                                  ├──► rs2 [2:0]
source1 ──►│  Decodes opcode and routes:                      ├──► rd  [2:0]
source2 ──►│    • ALU operation code                          ├──► alu_op [3:0]
dest ─────►│    • Register read/write addresses               ├──► use_imm
           │    • Immediate mode flag                         └──► flags_en
           │    • Flag enable                                 
           └──────────────────────────────────────────────────┘
```

**Opcode → Control Signal Mapping:**

| Opcode | Mnemonic | `alu_op` | `use_imm` | `flags_en` | `reg_write` |
|--------|----------|----------|-----------|------------|-------------|
| `0000` | ADD      | `0000`   | 0         | 1          | 1           |
| `0001` | SUB      | `0001`   | 0         | 1          | 1           |
| `0010` | AND      | `0010`   | 0         | **0**      | 1           |
| `0011` | OR       | `0011`   | 0         | **0**      | 1           |
| `0100` | XOR      | `0100`   | 0         | **0**      | 1           |
| `0101` | NOT      | `0101`   | **1**     | 1          | 1           |
| `0110` | SHL      | `0110`   | **1**     | 1          | 1           |
| `0111` | SHR      | `0111`   | **1**     | 1          | 1           |
| `1000` | GT       | `1000`   | 0         | **0**      | 1           |
| `1001` | EQ       | `1001`   | 0         | **0**      | 1           |
| `default` | NOP   | `0000`   | 0         | 0          | **0**       |

>  `use_imm = 1` forces the ALU's B operand to the constant `8'd1`. This is used for NOT, SHL, and SHR where operand B is irrelevant.

---

### Register File

**File:** `reg_file.v`

A **synchronous** register bank — 16 registers × 8 bits wide. Supports two simultaneous combinational reads and one clocked write.

```
             ┌────────────────────────────────────────────────┐
clk ────────►│                                                │
rst ────────►│            REGISTER FILE (16 × 8-bit)         │
we  ────────►│                                                │
             │   ┌──────┬──────┬──────┬──────┬───┬──────┐    │
r_addr1[2:0]►│   │ R[0] │ R[1] │ R[2] │ R[3] │...│R[15] │    ├──► r_data1[7:0]
r_addr2[2:0]►│   └──────┴──────┴──────┴──────┴───┴──────┘    ├──► r_data2[7:0]
             │        ▲          (async read via assign)       │
w_addr[2:0] ►│        │                                        │
w_data[7:0] ►│        └────── sync write on posedge clk       │
             └────────────────────────────────────────────────┘
```

**Behaviour:**
- `rst = 1` → all 16 registers cleared to `8'd0`
- `posedge clk` + `we = 1` → `regs[w_addr] <= w_data`
- Reads are purely combinational: `assign r_data1 = regs[r_addr1]`

---

### Top Module

**File:** `top_module.v`

Instantiates and interconnects all three sub-modules. The critical internal signal is the **B-operand MUX**:

```verilog
wire [7:0] alu_B = use_imm ? 8'd1 : r_data2;
```

This ensures that for unary operations (NOT, SHL, SHR) the ALU receives a valid B input without requiring source2 to be set.

---

##  Datapath Diagram

```
  ┌─────────────────────────────────────────────────────────────────────────┐
  │  INPUTS: clk, rst, opcode[3:0], source1[2:0], source2[2:0], dest[2:0] │
  └──────────────────────────────────┬──────────────────────────────────────┘
                                     │
                          ┌──────────▼──────────┐
                          │    CONTROL UNIT      │
                          │                      │
                          │  opcode → alu_op     │
                          │  source1 → rs1       │
                          │  source2 → rs2       │
                          │  dest    → rd        │
                          └──┬──────┬─────┬──────┘
                             │      │     │
                  reg_write  │ rs1  │ rs2 │ rd / alu_op / use_imm
                             │      │     │
                    ┌────────▼──────▼─────▼────────────────────┐
                    │              REGISTER FILE                │
                    │                                           │
                    │   regs[rs1] ──────────────────► r_data1  │
                    │   regs[rs2] ──────────────────► r_data2  │
                    │   regs[rd]  ◄── result (on clk)          │
                    └────────────────────┬──────────────────────┘
                                         │
                         r_data1         │        r_data2
                            │            │           │
                            │       ┌────▼───────────▼───┐
                            │       │   MUX (B select)    │
                            │       │   use_imm=0 → B     │
                            │       │   use_imm=1 → 8'd1  │
                            │       └────────────┬────────┘
                            │   A               │   B
                            └────────┐  ┌───────┘
                                     ▼  ▼
                              ┌──────────────┐
                              │     ALU      │
                              │              ├──► result[7:0]  ──► output + writeback
                              │  alu_op ────►│
                              │              ├──► Z (Zero flag)
                              │              ├──► C (Carry flag)
                              │              ├──► N (Negative flag)
                              │              └──► V (Overflow flag)
                              └──────────────┘
```

---

##  ALU Operation Flow

```
                   ┌─────────────────────┐
                   │   alu_op received    │
                   └──────────┬──────────┘
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
   ┌─────────────┐    ┌─────────────┐    ┌──────────────────┐
   │ ARITHMETIC  │    │   LOGICAL   │    │  SHIFT / COMPARE │
   ├─────────────┤    ├─────────────┤    ├──────────────────┤
   │ ADD (0000)  │    │ AND (0010)  │    │ SHL (0110)       │
   │  temp=A+B   │    │  A & B      │    │  result = A<<1   │
   │  C=temp[8]  │    ├─────────────┤    │  C = A[7]        │
   │  V=sign ovf │    │ OR  (0011)  │    ├──────────────────┤
   ├─────────────┤    │  A | B      │    │ SHR (0111)       │
   │ SUB (0001)  │    ├─────────────┤    │  result = A>>1   │
   │  temp=A-B   │    │ XOR (0100)  │    │  C = A[0]        │
   │  C=~temp[8] │    │  A ^ B      │    ├──────────────────┤
   │  V=sign ovf │    ├─────────────┤    │ GT  (1000)       │
   └─────────────┘    │ NOT (0101)  │    │  (A>B) ? 1 : 0   │
                      │  ~A         │    ├──────────────────┤
                      └─────────────┘    │ EQ  (1001)       │
                                         │  (A==B) ? 1 : 0  │
                                         └──────────────────┘
                                  │
                                  ▼
                      ┌─────────────────────┐
                      │    FLAG UPDATE       │
                      │  Z = (result == 0)   │
                      │  N =  result[7]      │
                      │  C = (per operation) │
                      │  V = (ADD/SUB only)  │
                      └─────────────────────┘
```

---

##  Instruction Set Architecture (ISA)

Each instruction word is implicitly formed from the top-level inputs:

```
  ┌──────────────┬─────────────┬─────────────┬─────────────┐
  │  opcode[3:0] │ source1[2:0]│ source2[2:0]│  dest[2:0]  │
  │   bits 15-12 │  bits 11-9  │   bits 8-6  │   bits 5-3  │
  └──────────────┴─────────────┴─────────────┴─────────────┘
```

| Mnemonic | Opcode | Operation               | Uses B? | Flags Updated |
|----------|--------|-------------------------|---------|---------------|
| `ADD`    | `0000` | `RD = RS1 + RS2`        | ✅      | Z, C, N, V   |
| `SUB`    | `0001` | `RD = RS1 - RS2`        | ✅      | Z, C, N, V   |
| `AND`    | `0010` | `RD = RS1 & RS2`        | ✅      | Z, N          |
| `OR`     | `0011` | `RD = RS1 \| RS2`       | ✅      | Z, N          |
| `XOR`    | `0100` | `RD = RS1 ^ RS2`        | ✅      | Z, N          |
| `NOT`    | `0101` | `RD = ~RS1`             | ❌ (imm)| Z, C, N, V   |
| `SHL`    | `0110` | `RD = RS1 << 1`         | ❌ (imm)| Z, C, N, V   |
| `SHR`    | `0111` | `RD = RS1 >> 1`         | ❌ (imm)| Z, C, N, V   |
| `GT`     | `1000` | `RD = (RS1 > RS2)?1:0`  | ✅      | Z, N          |
| `EQ`     | `1001` | `RD = (RS1==RS2)?1:0`   | ✅      | Z, N          |

---

##  Flag Register

```
         ┌─────┬─────┬─────┬─────┐
         │  V  │  N  │  C  │  Z  │
         └──┬──┴──┬──┴──┬──┴──┬──┘
            │     │     │     └─── Zero:     result == 8'b0
            │     │     └───────── Carry:    carry/borrow/shift-out bit
            │     └─────────────── Negative: result[7] == 1
            └───────────────────── Overflow: signed overflow (ADD/SUB)
```

---

##  Simulation Waveform Flow

```
 Time(ns)  0    10   20   30   40   50   60   70   80   90  100  110  120 ...
           │    │    │    │    │    │    │    │    │    │    │    │    │
    clk   _┘‾└_┘‾└_┘‾└_┘‾└_┘‾└_┘‾└_┘‾└_┘‾└_┘‾└_┘‾└_┘‾└_┘‾└_┘‾

    rst   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾_________
          (reset held HIGH for 50ns)                       (rst=0)

 opcode   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX[ADD][SUB][AND]...

 result   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX[16] [04] [02] ...

      Z   ____________________________________________________________
      N   ____________________________________________________________
      C   ____________________________________________________________
      V   ____________________________________________________________
```

---

##  Project Structure

```
8bitmicroprocessor-/
│
├── alu.v              # Combinational ALU — 10 operations, 4 flags
├── control_unit.v     # Synchronous control unit — opcode decoder
├── reg_file.v         # Synchronous register file — 16 × 8-bit
├── top_module.v       # Top-level: wires all modules together
├── top_tb.v           # Testbench — full simulation with $monitor
└── README.md          # This file
```

---

##  Getting Started

### Prerequisites

Install one of the following simulators:

- **[Icarus Verilog](http://iverilog.icarus.com/)** — free & open-source (recommended)
- **[ModelSim](https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/model-sim.html)**
- **[Vivado Simulator](https://www.xilinx.com/products/design-tools/vivado.html)**

### Simulate with Icarus Verilog

```bash
# 1. Clone the repository
git clone https://github.com/Barfi07/8bitmicroprocessor-.git
cd 8bitmicroprocessor-

# 2. Compile all source files + testbench
iverilog -o sim.out alu.v control_unit.v reg_file.v top_module.v top_tb.v

# 3. Run the simulation
vvp sim.out

# 4. (Optional) View waveforms — add $dumpfile/$dumpvars to top_tb.v first
gtkwave dump.vcd
```

---

##  Testbench

**File:** `top_tb.v`

The testbench verifies all 10 ALU operations in sequence:

**Initialization:**
```
R[0] = 10,  R[1] = 5,  R[2] = 6,  R[3] = 4
```

**Test Sequence** (source1 = R[0] = 10, source2 = R[2] = 6, dest = R[4]):

| # | Opcode | Mnemonic | A  | B   | Expected `result` | Expected Flags     |
|---|--------|----------|----|-----|-------------------|--------------------|
| 1 | `0000` | ADD      | 10 | 6   | **16**            | Z=0, C=0, N=0, V=0 |
| 2 | `0001` | SUB      | 10 | 6   | **4**             | Z=0, C=0, N=0, V=0 |
| 3 | `0010` | AND      | 10 | 6   | **2**             | Z=0, N=0           |
| 4 | `0011` | OR       | 10 | 6   | **14**            | Z=0, N=0           |
| 5 | `0100` | XOR      | 10 | 6   | **12**            | Z=0, N=0           |
| 6 | `0101` | NOT      | 10 | —   | **245** (`~10`)   | Z=0, N=1           |
| 7 | `0110` | SHL      | 10 | —   | **20** (`10<<1`)  | Z=0, C=0, N=0, V=0 |
| 8 | `0111` | SHR      | 10 | —   | **5**  (`10>>1`)  | Z=0, C=0, N=0, V=0 |
| 9 | `1000` | GT       | 10 | 6   | **1** (10 > 6)    | Z=0, N=0           |
|10 | `1001` | EQ       | 10 | 6   | **0** (10 ≠ 6)    | Z=1, N=0           |

---

##  Example Simulation Output

```
T=70ns   OPCODE=0000  A=5  B=6  RESULT=16  | Z=0 C=0 N=0 V=0
T=90ns   OPCODE=0001  A=5  B=6  RESULT=4   | Z=0 C=0 N=0 V=0
T=110ns  OPCODE=0010  A=5  B=6  RESULT=2   | Z=0 C=0 N=0 V=0
T=130ns  OPCODE=0011  A=5  B=6  RESULT=14  | Z=0 C=0 N=0 V=0
T=150ns  OPCODE=0100  A=5  B=6  RESULT=12  | Z=0 C=0 N=0 V=0
T=170ns  OPCODE=0101  A=5  B=6  RESULT=245 | Z=0 C=0 N=1 V=0
T=190ns  OPCODE=0110  A=5  B=6  RESULT=20  | Z=0 C=0 N=0 V=0
T=210ns  OPCODE=0111  A=5  B=6  RESULT=5   | Z=0 C=0 N=0 V=0
T=230ns  OPCODE=1000  A=5  B=6  RESULT=1   | Z=0 C=0 N=0 V=0
T=250ns  OPCODE=1001  A=5  B=6  RESULT=0   | Z=1 C=0 N=0 V=0
```

---

##  Future Improvements

- [ ] Add a **Program Counter (PC)** and instruction memory (ROM) for sequential execution
- [ ] Implement a proper **fetch → decode → execute** pipeline
- [ ] Add **branch / jump instructions** using Z, N, C, V flags
- [ ] Expand to a **load/store architecture** with a dedicated data memory
- [ ] Support a full **8-bit immediate** in the instruction word (not just `8'd1`)
- [ ] FPGA synthesis and deployment (Xilinx Basys3 / Intel DE10)
- [ ] Add **interrupt / exception handling** support

---

##  Author

**Barfi07**
GitHub: [@Barfi07](https://github.com/Barfi07)

---

##  License

This project is open-source and available under the [MIT License](LICENSE).

---

> *Built from first principles — one gate at a time.*
