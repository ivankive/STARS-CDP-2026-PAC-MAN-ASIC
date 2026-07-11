# Pac-Man ASIC

> Hardware implementation of Pac-Man for STARS 2025.

---

## Team

<!-- Names, roles, and contact info -->

---

## Overview

This project implements the classic Pac-Man arcade game entirely in hardware using SystemVerilog. The design targets an **iCE40 HX8K FPGA** for development and prototyping, with a final goal of **ASIC tapeout** on the **sky130** open-source PDK.

The game runs on a tile-based maze (28 × 36 tiles, 8 × 8 pixels per tile) rendered over VGA. Pac-Man and ghost movement, collision detection, pellet collection, and ghost AI are handled by dedicated hardware modules rather than a software CPU.

---

## Features

- [x] VGA timing generator (640 × 480 @ 60 Hz)
- [x] Tile-based pixel rendering (walls, pellets, power pellets)
- [x] Pac-Man movement with pushbutton input and wall collision
- [x] Maze ROM for static wall layout
- [ ] Maze RAM integration (runtime pellet state)
- [ ] Ghost AI (Blinky & Pinky — chase, scatter, frightened)
- [ ] Score display (7-segment)
- [ ] Power pellet / frightened mode
- [ ] Game over & restart logic
- [ ] Full top-level integration
- [ ] ASIC synthesis & tapeout

---

## Architecture

The design is split into display, game-state, and movement subsystems. The VGA pipeline generates pixel coordinates; `draw_tile` maps those to maze tiles and outputs RGB. Movement modules operate on a tile grid and consult the maze ROM/RAM for collision and pellet data.

### Block Diagram

```
                    ┌─────────────┐
  hz100 ──────────► │ vga_counter │──► hsync, vsync
                    │             │──► hcount, vcount
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐      ┌──────────────┐
                    │  draw_tile  │◄──── │   Maze_RAM   │
                    │             │      │  (pellets)   │
                    └──────┬──────┘      └──────┬───────┘
                           │ rgb                 │
                           ▼                     │
                      VGA output          ┌──────┴───────┐
                                          │              │
                                   ┌──────▼──────┐ ┌─────▼──────────┐
                                   │pacman_movement│ │ghost_controller│
                                   └──────┬──────┘ └────────────────┘
                                          │
                                   ┌──────▼──────┐
                                   │initial_maze │
                                   │    _rom     │
                                   └─────────────┘
```

### Module Hierarchy

```
top                          (current — partial)
├── vga_counter              (instantiated as vga_controller in top.sv)
└── draw_tile

top                          (planned — full integration)
├── vga_counter
├── draw_tile
├── Maze_RAM
├── initial_maze_rom
├── pacman_movement
└── ghost_controller
    ├── ghost_fsm        (×2)
    ├── ghost_target     (×2)
    └── ghost_movement_brain (×2)
```

---

## Modules

### `top.sv`

Top-level module. Connects to the STARS board I/O: 100 MHz clock (`hz100`), active-high reset, 21 pushbuttons, 7-segment displays, VGA RGB, and UART.

**Current status:** Instantiates the VGA controller and `draw_tile` only. Pac-Man, maze RAM, and ghost logic are not yet wired in.

### `vga_counter.sv`

Generates standard VGA timing for **640 × 480 @ 60 Hz**. Outputs horizontal/vertical sync signals, pixel counters (`hcount`, `vcount`), and a `video_on` flag for the active display region.

### `draw_tile.sv`

Maps VGA pixel coordinates to an 8 × 8 tile grid and renders tile types:

| `tile_data` | Type          | Color                          |
|-------------|---------------|--------------------------------|
| `2'b00`     | Empty         | Black                          |
| `2'b01`     | Wall          | Blue                           |
| `2'b10`     | Pellet        | 2 × 2 white square (center)    |
| `2'b11`     | Power pellet  | 6 × 6 white square, black corners |

The playable maze area is **416 × 192 px** (tiles 0–27 wide, 0–23 tall); regions outside this are drawn black.

**Current status:** `tile_data` is hardcoded to `2'b11` for testing. Maze RAM hookup is pending.

### `pacman_movement.sv`

Handles Pac-Man grid position (`xpos`, `ypos`), direction, and movement timing. Reads pushbuttons `pb[0:3]` for UP / RIGHT / DOWN / LEFT. Loads wall layout from `maze.mem` and blocks movement into walls. Uses a clock divider (moves every 20 cycles).

**Current status:** Standalone module; not yet connected to `top.sv`.

### `initial_maze_rom.sv`

Read-only maze initialized from `maze.mem`. Dual-port: one read port for Pac-Man collision checks, one for ghost collision checks. Parameterized grid size (28 × 36).

### `maze_ram.sv`

Dual-read, single-write RAM holding runtime tile state (1008 tiles × 2 bits). Supports pellet clearing on write and a reset sequence to reload from ROM. Serves Pac-Man, ghost, and VGA read ports.

**Current status:** Work in progress — placeholder filename, not integrated into `top.sv`.

### `ghost_controller.sv`

Top-level ghost coordinator for **2 ghosts** (Blinky and Pinky). Manages positions, directions, collision flags, and interfaces with the maze ROM for wall checks.

### `ghost_fsm.sv`

Per-ghost state machine with four states: **Caged**, **Scatter**, **Chase**, and **Frightened**. Responds to game state, power pellet activation, and global scatter/chase mode.

### `ghost_target.sv`

Computes each ghost's target tile based on its state and personality (e.g., Blinky chases Pac-Man directly; Pinky targets 4 tiles ahead of Pac-Man).

### `ghost_movement.sv`

(`ghost_movement_brain`) Selects the next direction by ranking legal moves toward the target tile. Handles reverse-direction rules and caged-mode exit behavior.

---

## Hardware

### Target Platform

| Stage       | Target                          |
|-------------|---------------------------------|
| Prototype   | Lattice iCE40 HX8K (CT256)      |
| Tapeout     | sky130A (via Volare PDK)        |

### Pin Map

<!-- Pin assignments defined in `support/pinmap.pcf` (not in repo root) -->

| Signal   | Direction | Description              |
|----------|-----------|--------------------------|
| `hz100`  | Input     | 100 MHz system clock     |
| `reset`  | Input     | Active-high reset        |
| `pb`     | Input     | Pushbuttons [20:0]       |
| `left`   | Output    | Left header (VGA hsync/vsync on bits 3–4) |
| `right`  | Output    | Right header (RGB on bits 1–3) |
| `red/green/blue` | Output | VGA color outputs |
| `ss0–ss7`| Output    | 7-segment displays       |
| UART     | I/O       | Serial debug interface   |

### Clock & Reset

- **System clock:** 100 MHz (`hz100`)
- **VGA pixel clock:** Derived from `hz100` (divider TBD in `top.sv`)
- **Reset:** Active-high, synchronous within each module

---

## Build & Run

Uses the STARS 2025 Makefile. Source files are expected under `source/` and testbenches under `testbench/` per the Makefile layout.

### Prerequisites

- Yosys, nextpnr-ice40, IcePack, iceprog
- Icarus Verilog (`iverilog`, `vvp`)
- Verilator, GTKWave
- For ASIC: `make setup_pdk` (installs Volare + sky130 PDK)

### FPGA Synthesis

```bash
make flash      # Build bitstream and program FPGA flash
make cram       # Build bitstream and load into CRAM (volatile)
make time       # Run timing analysis
make fpga-cells # View synthesized FPGA netlist
```

### ASIC Flow

```bash
make setup_pdk  # One-time sky130 PDK setup
make syn_top    # Synthesize design
make sim_top_syn  # Simulate post-synthesis netlist
make cells      # View synthesized ASIC netlist
```

### Simulation

```bash
make sim_<module>_src   # Simulate RTL from source/
make sim_<module>_syn   # Simulate post-synthesis netlist
make vlint_<module>     # Verilator lint check
make clean              # Remove build artifacts
```

---

## Testing

### Testbench

<!-- Test strategy and testbench files (expected in `testbench/`) -->

### Verification Status

| Module              | Simulated | Synthesized | On Hardware |
|---------------------|-----------|-------------|-------------|
| `vga_counter`       |           |             |             |
| `draw_tile`         |           |             |             |
| `pacman_movement`   |           |             |             |
| `initial_maze_rom`  |           |             |             |
| `maze_ram`          |           |             |             |
| `ghost_controller`  |           |             |             |
| `top` (integrated)  |           |             |             |

---

## Progress / Milestones

| Milestone              | Status         | Notes |
|------------------------|----------------|-------|
| VGA display            | In progress    | `vga_counter` complete; `top.sv` references `vga_controller` (name mismatch) |
| Maze rendering         | In progress    | `draw_tile` renders tiles; maze RAM not connected |
| Pac-Man movement       | In progress    | Module written; not integrated into `top.sv` |
| Pellet / scoring       | Not started    | `maze_ram` WIP |
| Ghost AI               | In progress    | FSM, target, and movement modules written; not integrated |
| Full game integration  | Not started    | Subsystems exist independently |
| ASIC tapeout           | Not started    | PDK setup available via Makefile |

---

## Known Issues

- `top.sv` instantiates `vga_controller`, but the module is named `vga_counter` in `vga_counter.sv`.
- `draw_tile` hardcodes `tile_data = 2'b11` instead of reading from maze RAM.
- `maze_ram.sv` uses placeholder `"filename"` for `$readmemb` and has an `indexcounter` typo (should be `index_counter`).
- `pacman_movement.sv` collision logic checks `== 1` for open paths (inverted vs. `maze.mem` where `1` = wall).
- Source files live in the repo root; the Makefile expects them in `source/`.
- `support/` directory (pinmap, ice40 wrapper, UART) is not present in the repo yet.

---

## References

- STARS 2025 Makefile and course materials
- [sky130 PDK](https://github.com/google/skywater-pdk)
- [Yosys](https://yosyshq.net/yosys/) / [nextpnr](https://github.com/YosysHQ/nextpnr)
- Pac-Man hardware behavior (tile grid, ghost personalities, scatter/chase timing)

---

## License

<!-- If applicable -->
