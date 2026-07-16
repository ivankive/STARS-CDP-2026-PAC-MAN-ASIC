`default_nettype none
// Empty top module

module top (
  // I/O ports
  input  logic hz100, reset,
  input  logic [20:0] pb,
  output logic [7:0] left, right,
         ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
  output logic red, green, blue,

  // UART ports
  output logic [7:0] txdata,
  input  logic [7:0] rxdata,
  output logic txclk, rxclk,
  input  logic txready, rxready
);
  // Your code goes here...
  logic [9:0] hcount, vcount;

//ROM Signals

  logic [4:0] pacman_x, pacman_y;
  logic [1:0] pacman_dir;
  logic pac_can_move_right, pac_can_move_left, pac_can_move_up, pac_can_move_down;
  logic [1:0] tile_a, tile_b, tile_RAM;

  logic [4:0] ghost_x, ghost_y;
  logic ghost_can_move_right, ghost_can_move_left, ghost_can_move_up, ghost_can_move_down;

  logic [4:0] x_c, y_c;


  //RAM Signals

    logic       map_rst;
    logic       map_loaded;

    //Port A: VGA read only 
    logic [4:0] x_vga;
    logic [4:0] y_vga;
    logic [1:0] rdata_vga;


    // Port B: Central Control read/write


    // Initial maze ROM interface, asynchronous x/y read
    //logic [4:0] x_c,
    //logic [4:0] y_c,
    //logic [1:0] tile_c


  maze_ram RAM(

    .clk(hz100),
    .reset(reset),

    .map_rst(map_rst),
    .map_loaded(map_loaded),

    // Port A: VGA read-only


    // Port B: Central Control read/write


    // Initial maze ROM interface, asynchronous x/y read
    .rom_x(x_c),
    .rom_y(y_c),
    .rom_data(tile_c)

  );

  maze_rom Read_only_memory(
    .x_a(pacman_x),
    .y_a(pacman_y),
    .tile_a(tile_a),
    .pac_can_move_right(pac_can_move_right),
    .pac_can_move_left (pac_can_move_left), 
    .pac_can_move_up   (pac_can_move_up), 
    .pac_can_move_down (pac_can_move_down),

    .x_b(ghost_x),
    .y_b(ghost_y),
    .tile_b(tile_b),
    .ghost_can_move_right(ghost_can_move_right),
    .ghost_can_move_left (ghost_can_move_left), 
    .ghost_can_move_up   (ghost_can_move_up), 
    .ghost_can_move_down (ghost_can_move_down),

    .x_c(x_c),
    .y_c(y_c),
    .tile_c(tile_c)
    );

  pacman_movement pacman_controller(
    .clk       (hz100),
    .reset     (reset),
    .pb        ({pb[3],pb[2],pb[1],pb[6]}),
    .xpos      (pacman_x),
    .ypos      (pacman_y),

    .pac_can_move_right(pac_can_move_right),
    .pac_can_move_left (pac_can_move_left), 
    .pac_can_move_up   (pac_can_move_up), 
    .pac_can_move_down (pac_can_move_down),

    .direction (pacman_dir)
  );

  vga_controller_top vga_controller(
    .pixel_clk(hz100),
    .rst      (reset),
    .rgb      ({right[3:1]}),
    .hsync    (left[3]),
    .vsync    (left[4]),
    .pacman_x (pacman_x),
    .pacman_y (pacman_y),
    .pacman_dir(pacman_dir)
  );

  

endmodule