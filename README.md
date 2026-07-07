# Parameterized RAM — RTL Design & Verification

## Project Overview

This project implements and verifies a **32×8 Synchronous Single-Port RAM** using SystemVerilog. The RAM supports synchronous read and write operations with an active-low reset. A class-based, self-checking testbench environment is built to verify functional correctness through constrained-random stimulus, a reference model, and an automated scoreboard.

## Design Summary

| Parameter       | Value                  |
|-----------------|------------------------|
| Memory Depth    | 32 locations           |
| Data Width      | 8 bits                 |
| Address Width   | 5 bits                 |
| Clock           | Single clock, posedge  |
| Reset           | Active-low, synchronous|
| Read Latency    | 1 clock cycle          |
| Write Latency   | 1 clock cycle          |

### Supported Operations

| Operation | write_enb | read_enb | Description                          |
|-----------|-----------|----------|--------------------------------------|
| Write     | 1         | 0        | Writes `data_in` to `memory[address]`|
| Read      | 0         | 1        | Reads `memory[address]` to `data_out`|
| Idle      | 0         | 0        | No operation, `data_out` = high-Z    |
| Invalid   | 1         | 1        | Prevented by testbench constraints   |

## Verification Environment

The testbench follows a **layered, class-based architecture**:

- **Generator** — Produces constrained-random transactions
- **Driver** — Drives stimulus onto the DUT via clocking blocks
- **Input Monitor** — Samples DUT inputs and feeds the reference model
- **Output Monitor** — Captures DUT outputs after 1-cycle read latency
- **Reference Model** — Behavioral model mirroring expected DUT behavior
- **Scoreboard** — Compares actual vs. expected outputs (self-checking)
- **Environment** — Orchestrates all components via mailboxes

### Key Features

- ✅ Self-checking via automated scoreboard
- ✅ Constrained-random stimulus with boundary coverage
- ✅ Functional coverage (covergroups for address, data, operations)
- ✅ Active-low reset handling
- ✅ High-impedance (z) output for unwritten/idle addresses
- ✅ VCD waveform dump for debug

## Tools Used

| Tool           | Purpose                              |
|----------------|--------------------------------------|
| Siemens Questa SIM | RTL Simulation & Coverage Analysis |

## Directory Structure

```
├── README.md
├── docs
│   ├── test_plan.md
│   └── verification_report.md
└── src
    ├── design
    │   └── ram.sv
    └── test_bench
        ├── driver.sv
        ├── environment.sv
        ├── generator.sv
        ├── input_monitor.sv
        ├── output_monitor.sv
        ├── ram_if.sv
        ├── reference.sv
        ├── scoreboard.sv
        ├── testbench.sv   
        └── transaction.sv
 
```

## How to Run

### With Questa SIM
```bash
vlog -sv src/test_bench/testbench.sv src/design/ram.sv
vsim -c top -do "run -all; quit"
```

### With Coverage Enabled
```bash
vlog -sv +cover src/test_bench/testbench.sv src/design/ram.sv
vsim -c top -coverage -do "coverage save -onexit covReport; run -all; quit"
```

## Simulation Results

All read transactions are verified against the reference model. The scoreboard reports:

```
==============================
       TEST SUMMARY
==============================
  Pass : N (all read transactions)
  Fail : 0
  Total: N
==============================
```

All test cases **PASSED** with zero mismatches.

## Documentation

- [Test Plan](docs/test_plan.md)
- [Verification Report](docs/verification_report.md)





## License

Copyright 2013-2014 - RV-VLSI. All Rights Reserved.
