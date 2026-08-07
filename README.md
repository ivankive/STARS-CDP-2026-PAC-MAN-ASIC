# Pac-Man ASIC

> Hardware implementation of Pac-Man for STARS 2026 — **`tapeout-nukeEverything`** branch.

---

## Overview

This project implements Pac-Man entirely in hardware using SystemVerilog. Development still targets an **iCE40 HX8K FPGA**, but this branch is a **tapeout-oriented rewrite**: the writable maze BRAM / dual-port ROM path was removed and replaced with a smaller memory subsystem so the design fits a tight ASIC cell budget (**under ~4k cells**; current FPGA synth of the board wrapper is ~2.5k primitives / ~1.7k LUTs).

Gameplay (Pac-Man, Blinky, Pinky, pellets, lives, power-pellet mode) still runs on a **24 × 24** tile maze over VGA. Score tracking was dropped to save area; on-screen state text remains (PAC-MAN / U LOSE / U WIN).

The working design lives under [`Pacman_FPGA/`](Pacman_FPGA/).

---

## What’s different from the full FPGA build

| Before (FPGA-heavy) | This branch (tapeout) |
|---------------------|------------------------|
| `maze_bram` + `initial_maze_rom` + reload FSM | Single `maze_wall_pellet_rom` + `pellet_state` + `maze_query_arbiter` |
| Writable 2-bit maze tiles in BRAM | Static ROM; only **186 pellet eaten-bits** are writable |
| Score + SCORE digits on VGA | Score removed |
| Map reload on restart | Clear `pellet_state` while `GAME_STARTING` |
| Larger maze / heavier display text | 24 × 24 maze; slim PAC-MAN / lose / win overlays |

---

## Features

- [x] VGA timing generator (640 × 480)
- [x] 24 × 24 tile maze (walls, pellets, power pellets)
- [x] Sprite rendering (Pac-Man, Blinky, Pinky; lives icons; cyan frightened ghosts)
- [x] Shared maze ROM + pellet-bit RAM (arbiter: VGA priority, round-robin game ports)
- [x] Pac-Man movement with pushbutton input and wall collision
- [x] Pellet / power-pellet collection (no score counters)
- [x] On-screen PAC-MAN / U LOSE / U WIN overlays
- [x] Lives tracking (start with 3; lose life on ghost hit)
- [x] Ghost AI (Blinky & Pinky — chase, scatter, frightened; slower when frightened)
- [x] Power-pellet timer (~3 s) and frightened mode
- [x] Game FSM (starting → playing → over / win → restart)
- [x] Soft restart via button edge (clears pellet bits; spawn reset held into next game tick)
- [x] Full top-level integration on FPGA
- [x] RTL unit testbenches + `run_tb.sh` batch runner
- [ ] ASIC synthesis & tapeout (area path prepared; PDK via root Makefile)

---

## Repository Layout

```
Pac-man-ASIC/
├── Pacman_FPGA/               # Active design
│   ├── source/                # SystemVerilog RTL (tapeout memory path)
│   ├── testbench/             # Unit testbenches (Icarus / GTKWave)
│   ├── waves/                 # VCD dumps
│   ├── support/               # Pinmap, iCE40 wrapper, UART
│   ├── build/                 # Bitstream / sim artifacts
│   ├── run_tb.sh              # Run all listed unit TBs
│   ├── Makefile               # Build, sim, flash targets
│   └── README.md              # STARS toolchain setup notes
├── 24x24_full_pellets         # Maze layout reference
├── 24x24_half_pellets         # Alternate / denser layout reference
├── 18x18_full_pellets         # Smaller layout exploration
├── maze.mem / maze2.mem       # Legacy maze memory files
└── README.md                  # This file
```

---

## Architecture

`top.sv` integrates display, game state, and the shared maze query path. A 100 MHz board clock drives VGA; `clock_div` produces a ~60 Hz game tick for Pac-Man, ghosts, and the power-pellet timer.

**Memory (tapeout path):**

1. `maze_wall_pellet_rom` — one combinational ROM for the static 24 × 24 map; also emits `pellet_index` (0…185) for collectible tiles.
2. `pellet_state` — 186-bit eaten array (only writable maze storage). Held clear during `GAME_STARTING`.
3. `maze_query_arbiter` — multiplexes the single ROM: VGA has priority; collision / Pac-Man / ghosts round-robin on non-VGA cycles. VGA responses suppress eaten pellets to empty path tiles.

There is no BRAM maze reload. Restart = clear pellet bits + spawn-reset hold until the next 60 Hz tick.

### Block Diagram

```
  hz100 ──► clock_div (60 Hz) ──► pacman / ghosts / pp_timer
    │
    ├──► vga_controller_top ──► hsync, vsync, RGB
    │         ├── vga_counter
    │         ├── vga_draw_tile
    │         ├── vga_draw_sprite  (Pac-Man, ghosts, lives)
    │         ├── vga_draw_text    (PAC-MAN / U LOSE / U WIN)
    │         └── vga_draw_border
    │
    ├──► maze_query_arbiter ──► maze_wall_pellet_rom
    │         │                      ▲
    │         ├── VGA (priority)
    │         ├── collision / pacman / ghost (round-robin)
    │         └── pellet_state (eaten bits; clear on STARTING)
    │
    ├──► game_fsm  (STARTING / PLAYING / OVER / WIN)
    ├──► pacman_movement / pacman_collision
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
├── maze_wall_pellet_rom
├── pellet_state
├── maze_query_arbiter
├── game_fsm
├── pacman_movement
├── pacman_collision
├── ghost_mode_controller
├── ghost_controller
│   ├── ghost_fsm
│   ├── ghost_target
│   └── ghost_movement
└── vga_controller_top
    ├── vga_counter
    ├── vga_draw_tile
    ├── vga_draw_sprite
    ├── vga_draw_text
    └── vga_draw_border
```

---

## Modules

| Module | Role |
|--------|------|
| `top.sv` | Board I/O, tapeout memory wiring, spawn-reset hold |
| `clock_div.sv` | 100 MHz → ~60 Hz game tick |
| `game_fsm.sv` | STARTING / PLAYING / OVER / WIN; edge + release-armed start |
| `pacman_movement.sv` | Grid position, direction, button input; arbiter wall checks |
| `pacman_collision.sv` | Pellet pickup via arbiter + `pellet_state`; ghost hit / eat; lives; pellet count |
| `pp_timer.sv` | Power-pellet / frightened window (~180 ticks / 3 s) |
| `maze_wall_pellet_rom.sv` | Static 24 × 24 maze ROM + pellet index |
| `pellet_state.sv` | 186 eaten bits; clear-all on new game |
| `maze_query_arbiter.sv` | Shared ROM mux (VGA priority, RR game ports) |
| `ghost_mode_controller.sv` | Global scatter / chase schedule |
| `ghost_controller.sv` | Blinky & Pinky; move cadence (slower when frightened) |
| `ghost_fsm.sv` | Per-ghost: caged, scatter, chase, frightened |
| `ghost_target.sv` | Personality-based target tiles |
| `ghost_movement.sv` | Next direction toward target |
| `vga_controller_top.sv` | Composites tile → sprite → text → border |
| `vga_counter.sv` | VGA timing |
| `vga_draw_tile.sv` | 24 × 24 tile map rendering |
| `vga_draw_sprite.sv` | Pac-Man / ghost sprites and remaining lives |
| `vga_draw_text.sv` | PAC-MAN / U LOSE / U WIN overlays (no SCORE) |
| `vga_draw_border.sv` | Screen border / letterbox |

### Tile encoding

| `tile_data` | Type | Color |
|-------------|------|-------|
| `2'b00` | Empty / path | Black |
| `2'b01` | Wall | Blue |
| `2'b10` | Pellet | Small white square |
| `2'b11` | Power pellet | Larger white square |

Collectibles: **186** (counted down in `pacman_collision`; win when count hits 0).

### Controls

Wired in `top.sv` as `{pb[7], pb[6], pb[5], pb[10]}`:

| Button | Action |
|--------|--------|
| `pb[7]` | Up |
| `pb[6]` | Right |
| `pb[5]` | Down |
| `pb[10]` | Left |

FSM uses **rising edges** only. STARTING → PLAYING also requires a short button **release** first (`start_armed`) so a WIN/OVER press cannot bounce straight through into PLAYING. OVER / WIN → STARTING on a fresh press; pellet bits stay cleared while STARTING.

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

Pin assignments: [`Pacman_FPGA/support/pinmap.pcf`](Pacman_FPGA/support/pinmap.pcf).

---

## Build & Run

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

./run_tb.sh             # Batch-run all listed unit testbenches
```

| Testbench | Coverage |
|-----------|----------|
| `game_fsm` | Edge + release-armed start; OVER / WIN restart; lives / pellets |
| `pacman_movement` | Spawn, turns, walls, tunnel, hit / `game_starting` |
| `pacman_collision` | Arbiter pellet pickup, power / ghost eat / hit, lives, pellet count |
| `pellet_state` | Set / clear / dual read ports |
| `maze_wall_pellet_rom` | 24 × 24 tiles, pellet index, move flags |
| `maze_query_arbiter` | VGA priority, RR ports, eaten → path for display |
| `pp_timer` | 180-tick window, retrigger, reset |
| `clock_div` | 60 Hz pulse |
| `ghost_mode_controller` | Scatter / chase schedule |
| `ghost_fsm` | Caged / scatter / chase / frightened / eaten |
| `ghost_target` | Blinky & Pinky targets |
| `ghost_movement` | Pathing, reverse, blocked / dead-end |
| `ghost_controller` | Spawn, cage exit, frightened / hit reset |
| `vga_counter` | 640 × 480 timing |
| `vga_draw_tile` | Wall / pellet / power pixels |
| `vga_draw_sprite` | Sprites, frightened cyan, lives icons |
| `vga_controller_top` | Pipeline compose with arbiter VGA port |

---

## Progress

| Milestone | Status | Notes |
|-----------|--------|-------|
| VGA display | Done | Tile / sprite / text / border; 24 × 24 playfield |
| Tapeout memory | Done | ROM + 186-bit `pellet_state` + arbiter (no maze BRAM) |
| Pac-Man movement | Done | 60 Hz; shared ROM wall checks |
| Pellets | Done | Collect + clear bits; no score |
| Lives / respawn | Done | 3 lives; icons; OVER at 0 |
| Win condition | Done | `GAME_WIN` when pellet count reaches 0 |
| Restart UX | Done | Button edge → STARTING; pellets cleared; spawn reset |
| State text | Done | PAC-MAN / U LOSE / U WIN (SCORE removed) |
| Ghost AI | Done | Blinky & Pinky; cyan when frightened |
| Power pellet mode | Done | ~3 s timer + eatable ghosts |
| Area target | Done | Under ~4k cells; FPGA synth ~2.5k primitives |
| Unit testbenches | Done | 17 TBs + `run_tb.sh` |
| ASIC tapeout | Done | PDK setup via root Makefile |

---

## References

- STARS 2025 Makefile and course materials
- [sky130 PDK](https://github.com/google/skywater-pdk)
- [Yosys](https://yosyshq.net/yosys/) / [nextpnr](https://github.com/YosysHQ/nextpnr)
- Pac-Man hardware behavior (tile grid, ghost personalities, scatter/chase timing)
