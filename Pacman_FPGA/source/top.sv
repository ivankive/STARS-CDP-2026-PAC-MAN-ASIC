`default_nettype none
module top (
  // I/O ports
  input  logic hz100, reset,
  input  logic [20:0] pb,
  output logic [7:0] left, right,
         ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
  output logic red, green, blue,
);
  logic [9:0] hcount, vcount;

  logic [4:0] pacman_x, pacman_y;
  logic [1:0] pacman_dir;
  logic [1:0]  game_state;
  logic       map_loaded;

  logic [4:0] pac_rom_x;
  logic [4:0] pac_rom_y;
  logic       pac_rom_can_move;

  //RAM read for VGA
  logic [4:0] x_vga, y_vga,
  logic [1:0] rdata_vga;

  //RAM write/read for collision
  logic [4:0] x_central, y_central;
  logic       write_en;
  logic [1:0] rdata_central;

  //RAM reading ROM
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

  assign rom_x_a = (game_state == STARTING) ? reload_rom_x : pac_rom_x;
  assign rom_y_a = (game_state == STARTING) ? reload_rom_y : pac_rom_y;

  pacman_movement pacman_controller(
    .clk       (hz100),
    .reset     (reset),
    .pb        ({pb[3],pb[2],pb[1],pb[6]}),
    .xpos      (pacman_x),
    .ypos      (pacman_y),
    .direction (pacman_dir)
  );

  vga_controller_top vga_controller(
    .pixel_clk(hz100),
    .rst      (reset),
    .rgb      ({right[3:1]}),
    .hsync    (left[3]),
    .vsync    (left[4]),
    .pacman_x (pacman_x),
    .pacman_y (pacman_y)
    .pacman_dir(pacman_dir)
  );

  game_fsm game_fsm(
    .clk          (clk),
    .reset        (reset),
    .map_rst      (1'b0),
    .reload_done  (map_loaded),
    .lives        (2'd3),
    .game_state   (game_state)
  )

  maze_ram_temp maze_ram(
    .clk            (hz100),
    .reset          (reset),
    .map_rst        (1'b0), //no in game reset yet
    .map_loaded     (map_loaded),
    .x_vga          (x_vga),
    .y_vga          (y_vga),
    .rdata_vga      (rdata_vga),
    .x_central      (x_central),
    .y_central      (y_central),
    .write_en       (write_en),
    .rdata_central  (rdata_central),
    .rom_x          (reload_rom_x),
    .rom_y          (reload_rom_y),
    .rom_data       (reload_rom_data)
  )

  initial_maze_rom maze_rom(
    .x_a        (rom_x_a),
    .y_a        (rom_y_a),
    .tile_a     (rom_tile_a),
    .can_move_a (rom_can_move_a),
    .x_b        (ghost_rom_x),
    .y_b        (ghost_rom_y),
    .tile_b     (tile_b),
    .can_move_b (ghost_rom_can_move)
  )

  

endmodule
