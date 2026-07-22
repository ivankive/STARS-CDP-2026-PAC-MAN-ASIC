# Pac-Man ASIC

> Hardware implementation of Pac-Man for STARS 2026.

---

## Overview

This project implements the classic Pac-Man arcade game entirely in hardware using SystemVerilog. The design targets an **iCE40 HX8K FPGA** for development and prototyping, with a final goal of **ASIC tapeout** on the **sky130** open-source PDK.

The game runs on a tile-based maze rendered over VGA. Pac-Man and ghost movement, collision detection, pellet collection, scoring, and ghost AI are handled by dedicated hardware modules rather than a software CPU.

The working FPGA design lives under [`Pacman_FPGA/`](Pacman_FPGA/).

---

## Features

- [x] VGA timing generator (640 × 480)
- [x] Tile-based maze rendering (walls, pellets, power pellets)
- [x] Sprite rendering (Pac-Man, Blinky, Pinky)
- [x] Maze ROM + BRAM (runtime pellet state, map reload)
- [x] Pac-Man movement with pushbutton input and wall collision
- [x] Pellet / power-pellet collection and scoring
- [x] Ghost AI (Blinky & Pinky — chase, scatter, frightened)
- [x] Power-pellet timer and frightened mode
- [x] Game FSM (starting → playing → game over)
- [x] Full top-level integration on FPGA
- [ ] Lives tracking / respawn fully wired through top
- [ ] Score on 7-segment display
- [ ] ASIC synthesis & tapeout

---

## Repository Layout

```
Pac-man-ASIC/
├── Pacman_FPGA/          # Active FPGA design
│   ├── source/           # SystemVerilog RTL
│   ├── support/          # Pinmap, iCE40 wrapper, UART
│   ├── build/            # Bitstream / synthesis artifacts
│   ├── Makefile          # Build, sim, flash targets
│   └── README.md         # STARS toolchain setup notes
├── maze.mem / maze2.mem  # Maze layout memory files
└── README.md             # This file
```

---

## Architecture

Display, game-state, memory, and movement subsystems are integrated in `top.sv`. VGA generates pixel coordinates; the VGA controller composites tiles, sprites, border, and text. Movement and ghosts tick at **60 Hz** from a clock divider on the 100 MHz board clock. Maze BRAM holds runtime pellet state; ROM supplies the initial layout and wall checks.

### Block Diagram

```
  hz100 ──► clock_div (60 Hz) ──► pacman / ghosts / pp_timer
    │
    ├──► vga_controller_top ──► hsync, vsync, RGB
    │         ├── vga_counter
    │         ├── vga_draw_tile
    │         ├── vga_draw_sprite
    │         ├── vga_draw_border
    │         └── vga_draw_text
    │
    ├──► maze_bram ◄──► pacman_collision (pellets, score, hits)
    │         ▲
    │         └── initial_maze_rom (reload + wall checks)
    │
    ├──► game_fsm
    ├──► pacman_movement
    ├──► ghost_mode_controller
    └──► ghost_controller
              ├── ghost_fsm (×2)
              ├── ghost_target (×2)
              └── ghost_movement (×2)
```

### Module Hierarchy

```
top
├── clock_div
├── pp_timer
├── game_fsm
├── pacman_movement
├── pacman_collision
├── maze_bram
├── initial_maze_rom
├── ghost_mode_controller
├── ghost_controller
│   ├── ghost_fsm
│   ├── ghost_target
│   └── ghost_movement
└── vga_controller_top
    ├── vga_counter
    ├── vga_draw_tile
    ├── vga_draw_sprite
    ├── vga_draw_border
    └── vga_draw_text
```

---

## Modules

| Module | Role |
|--------|------|
| `top.sv` | Board I/O and full game integration |
| `clock_div.sv` | Divides 100 MHz → ~60 Hz game tick |
| `game_fsm.sv` | Starting / playing / game-over states |
| `pacman_movement.sv` | Pac-Man grid position, direction, button input |
| `pacman_collision.sv` | Pellets, power pellets, ghost contact, score |
| `pp_timer.sv` | Power-pellet / frightened duration |
| `maze_bram.sv` | Dual-port BRAM for runtime maze + VGA reads |
| `initial_maze_rom.sv` | Static maze ROM (walls / pellets) |
| `ghost_mode_controller.sv` | Global scatter / chase schedule |
| `ghost_controller.sv` | Blinky & Pinky coordination |
| `ghost_fsm.sv` | Per-ghost: caged, scatter, chase, frightened |
| `ghost_target.sv` | Personality-based target tiles |
| `ghost_movement.sv` | Next direction toward target |
| `vga_controller_top.sv` | Composites display layers to VGA |
| `vga_counter.sv` | VGA timing |
| `vga_draw_tile.sv` | Tile map rendering |
| `vga_draw_sprite.sv` | Pac-Man / ghost sprites |
| `vga_draw_border.sv` | Screen border |
| `vga_draw_text.sv` | On-screen text |

### Tile encoding

| `tile_data` | Type | Color |
|-------------|------|-------|
| `2'b00` | Empty | Black |
| `2'b01` | Wall | Blue |
| `2'b10` | Pellet | Small white square |
| `2'b11` | Power pellet | Larger white square |

### Controls

| Button | Action |
|--------|--------|
| `pb[0]` | Up |
| `pb[1]` | Left |
| `pb[2]` | Down |
| `pb[3]` | Right |
| `pb[6]` | (extra input wired into movement) |

---

## Hardware

| Stage | Target |
|-------|--------|
| Prototype | Lattice iCE40 HX8K (CT256) |
| Tapeout | sky130A (via Volare PDK) |

| Signal | Direction | Description |
|--------|-----------|-------------|
| `hz100` | Input | 100 MHz system clock |
| `reset` | Input | Active-high reset |
| `pb` | Input | Pushbuttons [20:0] |
| `left[3:4]` | Output | VGA hsync / vsync |
| `right[3:1]` | Output | VGA RGB |
| `ss0–ss7` | Output | 7-segment displays (unused for score yet) |
| UART | I/O | Serial debug interface |

Pin assignments are in [`Pacman_FPGA/support/pinmap.pcf`](Pacman_FPGA/support/pinmap.pcf).

---

## Build & Run

Work from the FPGA project directory:

```bash
cd Pacman_FPGA
```

### Prerequisites

- Yosys, nextpnr-ice40, IcePack, iceprog
- Icarus Verilog (`iverilog`, `vvp`)
- Verilator, GTKWave
- For ASIC (repo root Makefile): `make setup_pdk` (Volare + sky130)

See [`Pacman_FPGA/README.md`](Pacman_FPGA/README.md) for STARS toolchain / SSH setup.

### FPGA

```bash
make cram       # Build bitstream and load CRAM (volatile)
make flash      # Build bitstream and program flash
make time       # Timing analysis
make fpga-cells # View synthesized FPGA netlist
```

### Simulation

```bash
make sim_<module>_src   # RTL simulation
make sim_<module>_syn   # Post-synthesis simulation
make vlint_<module>     # Verilator lint
make clean              # Remove build artifacts
```

Source files go in `Pacman_FPGA/source/`; testbenches in `Pacman_FPGA/testbench/`.

---

## Progress

| Milestone | Status | Notes |
|-----------|--------|-------|
| VGA display | Done | Counter + tile/sprite/border/text layers |
| Maze memory | Done | ROM + BRAM with VGA and gameplay ports |
| Pac-Man movement | Done | 60 Hz tick; integrated in `top` |
| Pellets / scoring | Done | Collision module clears pellets and tracks score |
| Ghost AI | Done | Blinky & Pinky with mode controller |
| Power pellet mode | Done | Timer + frightened / eatable ghosts |
| Full integration | Done | Wired in `Pacman_FPGA/source/top.sv` |
| Lives / game over UX | Partial | FSM present; lives still hardcoded in top |
| 7-segment score | Not started | Score exists in logic, not driven to `ss*` |
| ASIC tapeout | Not started | PDK setup available via Makefile |

---

## References

- STARS 2025 Makefile and course materials
- [sky130 PDK](https://github.com/google/skywater-pdk)
- [Yosys](https://yosyshq.net/yosys/) / [nextpnr](https://github.com/YosysHQ/nextpnr)
- Pac-Man hardware behavior (tile grid, ghost personalities, scatter/chase timing)
