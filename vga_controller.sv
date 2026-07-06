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
    logic [2:0] rgb;
    logic [9:0] h_count;
    logic [8:0] v_count;
    logic [2:0] tile_data;
    
    // test values
    assign h_count = 10'd110;
    assign v_count = 9'd100;
    assign tile_data = 3'd0;
    
    draw_tile dt_test (
      .rgb(rgb),
      .h_count(h_count),
      .v_count(v_count),
      .tile_data(tile_data)
    );
    
    // connect to outputs
    assign red   = rgb[2];
    assign green = rgb[1];
    assign blue  = rgb[0];

    
  endmodule
  
  module draw_tile(
    output logic [2:0]rgb,      //pixel color
    input logic [9:0]h_count,   //Horizontal Display Counter (max value is 640px)
    input logic [8:0]v_count,    //Vertical Display Counter (maxvalue is 480px)
    input logic [2:0] tile_data //Tile Data (blank, wall, pellet, power pellet)
  );
  
  logic black_left, black_bottom;
  
  //determine whether pixel is in the map
  assign black_left   = ((h_count >= 416) && (h_count < 640) && (v_count >= 0)   && (v_count < 480));
  assign black_bottom = ((h_count >= 0)   && (h_count < 640) && (v_count >= 192) && (v_count < 480));
  
  //draw black if not on map
  always_comb begin
    if (black_left) //black border when h_count is higher than 416px
      rgb = 3'b000;
    else if (black_bottom) //black border when v_count is higher than 192px
      rgb = 3'b000;
    else
      rgb = 3'b111;
  end
  //get pixel position using division, quotient is tile position and remainder is pixel position in tile
  
  

  

  
  endmodule
