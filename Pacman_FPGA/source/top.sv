`default_nettype none

// top - tapeout version
//
// Memory architecture vs the FPGA version:
//  * maze_bram (2048-bit writable maze + ROM-to-BRAM reload FSM) and
//    initial_maze_rom (two combinational ports) are gone.
//  * maze_wall_pellet_rom: one combinational ROM instance holding the
//    static maze; also produces a compact pellet_index (0..287).
//  * pellet_state: the ONLY writable maze memory - 288 eaten bits.
//  * maze_query_arbiter: shares the single ROM among the VGA (priority)
//    and the three game requesters (collision / pacman / ghosts).
//  * game_fsm no longer waits on a maze reload; a new game just clears
//    pellet_state (held clear during GAME_STARTING).
//  * Score tracking and vga_draw_text are removed for tapeout.

module top (
  // I/O ports
  input  logic hz100, reset,
  input  logic [20:0] pb,
  output logic [7:0] left, right, ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
  output logic red, green, blue,

  // UART ports
  output logic [7:0] txdata,
  input  logic [7:0] rxdata,
  output logic txclk, rxclk,
  input  logic txready, rxready
);
  assign right[7] = hz100;

  // Clock
  logic new_clock;

  // Game state
  logic [1:0] game_state;

  // pacman
  logic [4:0] pacman_x, pacman_y;
  logic [1:0] pacman_dir;

  logic       pellet_eaten;
  logic       power_pellet_eaten;
  logic       pacman_hit;
  logic [1:0] ghost_eaten;
  logic [1:0] lives;
  logic [7:0] pellets;

  // Arbiter VGA port
  logic       vga_active;
  logic [4:0] x_vga, y_vga;
  logic [1:0] rdata_vga;

  // Arbiter collision port
  logic [4:0] col_x, col_y;
  logic       col_valid;
  logic       col_collectible;
  logic       col_is_power;
  logic [7:0] col_pellet_index;

  // Arbiter pacman port
  logic [4:0] pac_rom_x, pac_rom_y;
  logic       pac_rom_valid;
  logic       pac_rom_can_move;

  // Arbiter ghost port
  logic [4:0] ghost_rom_x, ghost_rom_y;
  logic       ghost_rom_valid;
  logic       ghost_rom_can_move;

  // Shared ROM wires
  logic [4:0] rom_x, rom_y;
  logic [1:0] rom_tile;
  logic       rom_collectible;
  logic [7:0] rom_pellet_index;
  logic       rom_can_move_pac;
  logic       rom_can_move_ghost;

  // pellet_state wires
  logic       pellet_set_en;
  logic [7:0] pellet_set_index;
  logic       pellet_already_eaten;
  logic [7:0] pellet_vga_index;
  logic       pellet_vga_bit;

  // Ghost stuff
  logic global_ghost_mode;
  logic power_pellet_active;

  logic [4:0] blinky_x;
  logic [4:0] blinky_y;
  logic [1:0] blinky_dir;

  logic [4:0] pinky_x;
  logic [4:0] pinky_y;
  logic [1:0] pinky_dir;

  logic [1:0] dangerous_to_pacman;
  logic [1:0] vulnerable_to_pacman;

  logic [3:0] inputs;

  assign inputs = {pb[7], pb[6], pb[5], pb[10]};

  clock_div marcus(.clk(hz100), .rst(reset), .clk_div(new_clock));

  pp_timer pp(.pp_collision(power_pellet_eaten), .clk(new_clock), .rst(reset), .pp_active(power_pellet_active));
  assign red = power_pellet_active;

  // ---------------- Maze memory subsystem ----------------

  maze_wall_pellet_rom maze_rom (
    .x              (rom_x),
    .y              (rom_y),
    .tile           (rom_tile),
    .collectible    (rom_collectible),
    .pellet_index   (rom_pellet_index),
    .can_move_pac   (rom_can_move_pac),
    .can_move_ghost (rom_can_move_ghost)
  );

  pellet_state pellet_state_inst (
    .clk        (hz100),
    .reset      (reset),
    .clear      (game_state == 2'd0),   // held clear during GAME_STARTING
    .set_en     (pellet_set_en),
    .set_index  (pellet_set_index),
    .rd_index_a (col_pellet_index),     // collision checks its response index
    .rd_bit_a   (pellet_already_eaten),
    .rd_index_b (pellet_vga_index),     // VGA suppresses eaten pellets
    .rd_bit_b   (pellet_vga_bit)
  );

  maze_query_arbiter arbiter (
    .clk              (hz100),
    .reset            (reset),

    .vga_active       (vga_active),
    .vga_x            (x_vga),
    .vga_y            (y_vga),
    .rdata_vga        (rdata_vga),

    .col_x            (col_x),
    .col_y            (col_y),
    .col_valid        (col_valid),
    .col_collectible  (col_collectible),
    .col_is_power     (col_is_power),
    .col_pellet_index (col_pellet_index),

    .pac_x            (pac_rom_x),
    .pac_y            (pac_rom_y),
    .pac_valid        (pac_rom_valid),
    .pac_can_move     (pac_rom_can_move),

    .ghost_x          (ghost_rom_x),
    .ghost_y          (ghost_rom_y),
    .ghost_valid      (ghost_rom_valid),
    .ghost_can_move   (ghost_rom_can_move),

    .rom_x              (rom_x),
    .rom_y              (rom_y),
    .rom_tile           (rom_tile),
    .rom_collectible    (rom_collectible),
    .rom_pellet_index   (rom_pellet_index),
    .rom_can_move_pac   (rom_can_move_pac),
    .rom_can_move_ghost (rom_can_move_ghost),

    .pellet_rd_index  (pellet_vga_index),
    .pellet_rd_bit    (pellet_vga_bit)
  );

  // ---------------- Game logic ----------------

  pacman_movement pacman_movement(
    .clk          (new_clock),
    .reset        (reset),
    .enable       (game_state == 2'b01),
    .pb           (inputs),
    .pacman_hit   (pacman_hit),
    .rom_x        (pac_rom_x),
    .rom_y        (pac_rom_y),
    .rom_valid    (pac_rom_valid),
    .rom_can_move (pac_rom_can_move),
    .xpos         (pacman_x),
    .ypos         (pacman_y),
    .direction    (pacman_dir)
  );

  pacman_collision pacman_collision_inst (
    .clk                   (hz100),
    .reset                 (reset),
    .game_tick             (new_clock),
    .game_running          (game_state == 2'd1),
    .game_starting         (game_state == 2'd0),

    .pacman_x              (pacman_x),
    .pacman_y              (pacman_y),

    .blinky_x              (blinky_x),
    .blinky_y              (blinky_y),
    .pinky_x               (pinky_x),
    .pinky_y               (pinky_y),

    .dangerous_to_pacman   (dangerous_to_pacman),
    .vulnerable_to_pacman  (vulnerable_to_pacman),
    .power_pellet_active   (power_pellet_active),

    .col_x                 (col_x),
    .col_y                 (col_y),
    .col_valid             (col_valid),
    .col_collectible       (col_collectible),
    .col_is_power          (col_is_power),
    .col_pellet_index      (col_pellet_index),

    .pellet_already_eaten  (pellet_already_eaten),
    .pellet_set_en         (pellet_set_en),
    .pellet_set_index      (pellet_set_index),

    .pellet_eaten          (pellet_eaten),
    .power_pellet_eaten    (power_pellet_eaten),
    .pacman_hit            (pacman_hit),
    .ghost_eaten           (ghost_eaten),

    .lives                 (lives),
    .pellets               (pellets)
  );

  vga_controller_top vga_controller(
    .pixel_clk  (hz100),
    .rst        (reset),
    .rgb        ({right[3:1]}),
    .hsync      (left[3]),
    .vsync      (left[4]),
    .vga_active (vga_active),
    .x_vga      (x_vga),
    .y_vga      (y_vga),
    .rdata_vga  (rdata_vga),
    .pacman_x   (pacman_x),
    .pacman_y   (pacman_y),
    .pacman_dir (pacman_dir),
    .blinky_x   (blinky_x),
    .blinky_y   (blinky_y),
    .blinky_dir (blinky_dir),
    .pinky_x    (pinky_x),
    .pinky_y    (pinky_y),
    .pinky_dir  (pinky_dir),
    .pp_active  (power_pellet_active),
    .lives      (lives)
  );

  game_fsm game_fsm(
    .clk          (hz100),
    .reset        (reset),
    .lives        (lives),
    .pellets      (pellets),
    .inputs       (inputs),
    .game_state   (game_state)
  );

  ghost_mode_controller ghost_mode (
    .clk                 (new_clock),
    .reset               (reset),
    .game_active        (game_state == 2'd1),
    .ghost_mode   (global_ghost_mode)
  );

  ghost_controller ghost_controller (
    .clk                  (new_clock),
    .reset                (reset),

    .game_state           (game_state),
    .power_pellet_active  (power_pellet_active),
    .global_ghost_mode    (global_ghost_mode),

    .pacman_x             (pacman_x),
    .pacman_y             (pacman_y),
    .pacman_dir           (pacman_dir),
    .pacman_hit           (pacman_hit),

    .ghost_eaten          (ghost_eaten),

    .ghost_rom_x          (ghost_rom_x),
    .ghost_rom_y          (ghost_rom_y),
    .ghost_rom_valid      (ghost_rom_valid),
    .ghost_rom_can_move   (ghost_rom_can_move),

    .blinky_x             (blinky_x),
    .blinky_y             (blinky_y),
    .blinky_dir           (blinky_dir),

    .pinky_x              (pinky_x),
    .pinky_y              (pinky_y),
    .pinky_dir            (pinky_dir),

    .dangerous_to_pacman  (dangerous_to_pacman),
    .vulnerable_to_pacman (vulnerable_to_pacman)
  );

endmodule

`default_nettype wire
