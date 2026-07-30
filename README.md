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
- [x] Sprite rendering (Pac-Man, Blinky, Pinky; lives icons; cyan frightened ghosts)
- [x] Maze ROM + BRAM (runtime pellet state, map reload)
- [x] Pac-Man movement with pushbutton input and wall collision
- [x] Pellet / power-pellet collection and scoring
- [x] On-screen SCORE text + decimal digits
- [x] Lives tracking (start with 3; lose life on ghost hit)
- [x] Ghost AI (Blinky & Pinky — chase, scatter, frightened)
- [x] Power-pellet timer and frightened mode
- [x] Game FSM (starting → playing → game over / win → restart)
- [x] Full top-level integration on FPGA
- [x] RTL unit testbenches for core gameplay modules
- [ ] ASIC synthesis & tapeout

---

## Repository Layout

```
Pac-man-ASIC/
├── Pacman_FPGA/          # Active FPGA design
│   ├── source/           # SystemVerilog RTL
│   ├── testbench/        # Unit testbenches (Icarus / GTKWave)
│   ├── waves/            # VCD / GTKWave save files
│   ├── support/          # Pinmap, iCE40 wrapper, UART
│   ├── build/            # Bitstream / sim artifacts
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
    │         ├── vga_draw_sprite  (Pac-Man, ghosts, lives icons)
    │         ├── vga_draw_border
    │         └── vga_draw_text    (PAC-MAN title, SCORE + digits)
    │
    ├──► maze_bram ◄──► pacman_collision (pellets, score, lives, hits)
    │         ▲
    │         └── initial_maze_rom (reload + wall checks)
    │
    ├──► game_fsm  (STARTING / PLAYING / OVER / WIN)
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
| `game_fsm.sv` | Starting / playing / game-over / win states |
| `pacman_movement.sv` | Pac-Man grid position, direction, button input |
| `pacman_collision.sv` | Pellets, power pellets, ghost contact, score, lives |
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
| `vga_draw_sprite.sv` | Pac-Man / ghost sprites and remaining lives |
| `vga_draw_border.sv` | Screen border |
| `vga_draw_text.sv` | Title screen + SCORE digits |

### Tile encoding

| `tile_data` | Type | Color |
|-------------|------|-------|
| `2'b00` | Empty | Black |
| `2'b01` | Wall | Blue |
| `2'b10` | Pellet | Small white square |
| `2'b11` | Power pellet | Larger white square |

### Controls

Wired in `top.sv` as `{pb[7], pb[6], pb[5], pb[10]}` into movement / FSM start inputs:

| Button | Action |
|--------|--------|
| `pb[7]` | Up |
| `pb[6]` | Right |
| `pb[5]` | Down |
| `pb[10]` | Left |

Any of these inputs can also advance the FSM from STARTING / OVER / WIN (after map load, or to restart).

### Scoring

| Event | Points |
|-------|--------|
| Pellet | +2 |
| Power pellet | +15 |
| Eaten ghost | +20 |

Score is shown on VGA as `SCORE` plus three decimal digits.

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
| `ss0–ss7` | Output | 7-segment displays (unused) |

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

Available gameplay unit tests (run with `make sim_<name>_src`):

| Testbench | Coverage |
|-----------|----------|
| `game_fsm` | STARTING → PLAYING → OVER / WIN; reload / lives / pellets |
| `pacman_movement` | Spawn, facing, turns, wall block, tunnel wrap, hit / `game_rst` |
| `pacman_collision` | Pellet / power clear, lives, ghost eat / hit (score checks partially commented) |
| `maze_bram` | Load, VGA / central reads, pellet clear, map reload |
| `pp_timer` | Activate, 180-tick window, retrigger, async reset |
| `ghost_mode_controller` | Scatter / chase schedule and pause |
| `ghost_fsm` | Caged / scatter / chase / frightened / eaten |
| `ghost_target` | Blinky & Pinky targets (chase offset, clamps, frightened) |
| `ghost_movement` | Pathing toward target, reverse, blocked / dead-end |

---

## Progress

| Milestone | Status | Notes |
|-----------|--------|-------|
| VGA display | Done | Counter + tile/sprite/border/text layers |
| Maze memory | Done | ROM + BRAM with VGA and gameplay ports |
| Pac-Man movement | Done | 60 Hz tick; integrated in `top` |
| Pellets / scoring | Done | Collision awards points; VGA shows SCORE |
| Lives / respawn | Done | 3 lives; icons on screen; FSM goes OVER at 0 |
| Win condition | Done | `GAME_WIN` when all pellets cleared |
| Restart UX | Done | Button input returns OVER / WIN → STARTING |
| Ghost AI | Done | Blinky & Pinky; frightened ghosts draw cyan |
| Power pellet mode | Done | Timer + frightened / eatable ghosts |
| Full integration | Done | Wired in `Pacman_FPGA/source/top.sv` |
| Unit testbenches | Done | 9 module TBs under `Pacman_FPGA/testbench/` |
| ASIC tapeout | Not started | PDK setup available via Makefile |

---

## References

- STARS 2025 Makefile and course materials
- [sky130 PDK](https://github.com/google/skywater-pdk)
- [Yosys](https://yosyshq.net/yosys/) / [nextpnr](https://github.com/YosysHQ/nextpnr)
- Pac-Man hardware behavior (tile grid, ghost personalities, scatter/chase timing)
