#!/usr/bin/env bash
# Run all Pacman_FPGA testbenches with Icarus (no gtkwave).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

SRC=source
TB=testbench
BUILD=build/tb
mkdir -p "$BUILD" waves

TBS=(
  game_fsm
  pacman_movement
  pacman_collision
  pellet_state
  maze_wall_pellet_rom
  maze_query_arbiter
  ghost_fsm
  ghost_mode_controller
  ghost_movement
  ghost_target
  ghost_controller
  pp_timer
  clock_div
  vga_counter
  vga_draw_tile
  vga_draw_sprite
  vga_controller_top
)

pass=0
fail=0

for name in "${TBS[@]}"; do
  echo "============================================================"
  echo "TEST: ${name}_tb"
  echo "============================================================"
  if iverilog -g2012 -o "$BUILD/${name}_tb" -Y .sv -y "$SRC" "$TB/${name}_tb.sv" \
    && vvp "$BUILD/${name}_tb"; then
    echo "OK: ${name}_tb"
    pass=$((pass + 1))
  else
    echo "FAIL: ${name}_tb"
    fail=$((fail + 1))
  fi
  echo
done

echo "============================================================"
echo "SUMMARY: ${pass} passed, ${fail} failed out of ${#TBS[@]}"
echo "============================================================"
exit "$fail"
