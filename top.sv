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
  assign left[7] = hz100;
  logic [9:0] hcount, vcount;
  logic video_on;


  vga_controller test
  (
    .clk(hz100), //inputs
    .rst(reset),
    .hsync(left[3]), //outputs to VGA
    .vsync(left[4]),
    .hcount(hcount), //outputs to draw_tile
    .vcount(vcount),
    .video_on(video_on)
  );

  draw_tile draw_tile (
    .rgb    ({right[1],right[2],right[3]}), //outputs to VGA
    .h_count(hcount), //inputs from vga_controller
    .v_count(vcount)
  );

endmodule
