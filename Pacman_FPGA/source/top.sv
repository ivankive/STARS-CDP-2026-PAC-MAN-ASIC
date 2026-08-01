`default_nettype none
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

  logic [9:0] hcount, vcount;

  // Clock
  logic new_clock;

  // Game state
  logic [1:0] game_state;
  logic       map_loaded;

  // pacman
  logic [4:0] pacman_x, pacman_y;
  logic [1:0] pacman_dir;

  logic [4:0] pac_rom_x;
  logic [4:0] pac_rom_y;
  logic       pac_rom_can_move;
  
  logic       pellet_eaten;
  logic       power_pellet_eaten;
  logic       pacman_hit;
  logic [1:0] ghost_eaten;
  logic [9:0] score;
  logic [1:0] lives;
  logic [8:0] pellets;

  //RAM VGA read port
  logic [4:0] x_vga, y_vga;
  logic [1:0] rdata_vga;

  //RAM Central read/write port
  logic [4:0] x_central, y_central;
  logic       write_en;
  logic [1:0] rdata_central;

  //RAM ROM write port; shared with Central
  logic [4:0] reload_rom_x, reload_rom_y;
  logic [1:0] reload_rom_data;

  //ROM port A I/O
  logic [4:0] rom_x_a, rom_y_a;
  logic [1:0] rom_tile_a;
  logic       rom_can_move_a;

  //ROM port B I/O
  logic [4:0] ghost_rom_x, ghost_rom_y;
  logic [1:0] tile_b;
  logic       ghost_rom_can_move;

  //Ghost stuff
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
  assign rom_x_a = (game_state == 2'b0) ? reload_rom_x : pac_rom_x;
  assign rom_y_a = (game_state == 2'b0) ? reload_rom_y : pac_rom_y;
  assign reload_rom_data = rom_tile_a;
  assign pac_rom_can_move = rom_can_move_a;

  clock_div marcus(.clk(hz100), .rst(reset), .clk_div(new_clock));

  // Clear frightened window on hard reset and soft restart (STARTING).
  pp_timer pp(
    .pp_collision(power_pellet_eaten),
    .clk(new_clock),
    .rst(reset || (game_state == 2'd0)),
    .pp_active(power_pellet_active)
  );
  assign red = power_pellet_active;

  pacman_movement pacman_movement(
    .clk          (new_clock),
    .reset        (reset),
    .enable       ((game_state == 2'b01) && map_loaded),
    .pb           (inputs),
    .rom_x        (pac_rom_x),
    .rom_y        (pac_rom_y),
    .rom_can_move (pac_rom_can_move),
    .xpos         (pacman_x),
    .ypos         (pacman_y),
    .direction    (pacman_dir),
    .pacman_hit   (pacman_hit),
    .game_rst     (game_state == 2'd0)
  );

  pacman_collision pacman_collision_inst (
    .clk                   (hz100),
    .reset                 (reset),
    .game_tick             (new_clock),
    .game_running          ((game_state == 2'd1) && map_loaded),
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

    .x_central             (x_central),
    .y_central             (y_central),
    .write_en              (write_en),
    .rdata_central         (rdata_central),

    .pellet_eaten          (pellet_eaten),
    .power_pellet_eaten    (power_pellet_eaten),
    .pacman_hit            (pacman_hit),
    .ghost_eaten           (ghost_eaten),
    .score                 (score),

    .lives                 (lives),
    .pellets               (pellets)
  );

  vga_controller_top vga_controller(
    .pixel_clk  (hz100),
    .rst        (reset),
    .rgb        ({right[3:1]}),
    .hsync      (left[3]),
    .vsync      (left[4]),
    .x_vga      (x_vga),
    .y_vga      (y_vga),
    .rdata_vga  (rdata_vga),
    .map_loaded (map_loaded),
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
    .lives      (lives),
    .game_state (game_state),
    .score      (score)
  );

  game_fsm game_fsm(
    .clk          (hz100),
    .reset        (reset),
    .map_rst      ((game_state == 2'd2 || game_state == 2'd3) && |inputs),
    .reload_done  (map_loaded),
    .lives        (lives),
    .pellets      (pellets),
    .inputs       (inputs),
    .game_state   (game_state)
  );

maze_bram maze_ram (
      .clk           (hz100),
      .reset         (reset),
      .map_rst       ((game_state == 2'd2 || game_state == 2'd3) && |inputs),
      .map_loaded    (map_loaded),
      .x_vga         (x_vga),
      .y_vga         (y_vga),
      .rdata_vga     (rdata_vga),
      .x_central     (x_central),
      .y_central     (y_central),
      .write_en      (write_en),
      .rdata_central (rdata_central),
      .rom_x         (reload_rom_x),
      .rom_y         (reload_rom_y),
      .rom_data      (reload_rom_data)
  );

  initial_maze_rom maze_rom(
    .x_a        (rom_x_a),
    .y_a        (rom_y_a),
    .tile_a     (rom_tile_a),
    .can_move_a (rom_can_move_a),
    .x_b        (ghost_rom_x),
    .y_b        (ghost_rom_y),
    .tile_b     (tile_b),
    .can_move_b (ghost_rom_can_move)
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
