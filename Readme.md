# 8-bit Mini CPU (Verilog)

Small 8-bit datapath with a control unit, ALU, register file, top-level wrapper and a testbench. Useful as a learning/demo CPU for arithmetic, logic, shifts and simple comparisons.

## Repository structure
- alu.v — ALU implementing ADD, SUB, AND, OR, XOR, NOT, SHL, SHR, comparisons and flags
- control_unit.v — opcode decoder driving register addresses, ALU op, immediate and flag enable
- reg_file.v — clocked register file with reset and write-enable
- top_module.v — top-level that wires the datapath
- top_tb.v — testbench to exercise the design
- README.md — this file
- LICENSE — project license

## Overview
- top_module.v connects control_unit, reg_file and alu to form a simple datapath.
- control_unit decodes a 4-bit opcode and generates read/write control signals.
- reg_file holds 8-bit registers (currently implemented as 8 or 16 entries depending on code) and provides read/write ports.
- alu performs arithmetic/logic operations and drives flags: Z (zero), C (carry), N (negative), V (overflow).
- top_tb initializes registers and steps through opcodes to verify behavior.

## Simulation (example with Icarus Verilog)
1. Compile:
   iverilog -o top_tb.vvp top_tb.v top_module.v control_unit.v reg_file.v alu.v
2. Run:
   vvp top_tb.vvp

## Notes / Known issues
- Address width mismatch: control_unit uses 3-bit addresses but top_module declares 4-bit rs/rd; reg_file storage may be sized for 16 entries. Make register address widths consistent across modules (prefer 4-bit for 16 registers) or reduce storage to 8 entries.
- flags_en from control_unit is produced but not currently applied to top-level outputs — flags are always driven by the ALU.
- use_imm currently selects a constant immediate (8'd1) in top_module. Adjust if other immediate formats are desired.
- Reset semantics vary between modules (synchronous vs asynchronous). Keep consistent if targeting hardware.

## Contributing
- Ensure signal width consistency when changing register count or address bus width.
- Add opcodes, immediate formats, or pipeline stages as separate commits with tests in top_tb.v.

## License
This project is licensed under the Apache License 2.0. See LICENSE for details.