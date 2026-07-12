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
  logic [4:0] pacman_x, pacman_y;
  logic [1:0] pacman_dir;

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

  

endmodule
