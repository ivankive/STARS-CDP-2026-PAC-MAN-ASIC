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
    logic [1:0] tile_data;
    
    // test values
    assign h_count = 10'd3;
    assign v_count = 9'd3;
    assign tile_data = 2'b11;
    
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
    input logic [1:0] tile_data //TEMPORARILY IT CODE SHOULD KNOW WHAT TILE IT IS FROM h_count and v_count... Tile Data (blank, wall, pellet, power pellet)
  );

  //variables
  logic black_left, black_bottom;
  logic [4:0] tile_y;     // 0-27 Y tiles
  logic [5:0] tile_x;     // 0-35 X tiles
  logic [2:0] pixel_x, pixel_y; //0-7 pixels in tiles
  
  //determine whether pixel is in the map
  assign black_left   = ((h_count >= 416) && (h_count < 640) && (v_count >= 0)   && (v_count < 480));
  assign black_bottom = ((h_count >= 0)   && (h_count < 640) && (v_count >= 192) && (v_count < 480));
  
  //determine tile location and pixel position in tile
  assign tile_y = v_count[7:3]; //quotient
  assign tile_x = h_count[8:3];
  assign pixel_y = v_count[2:0]; //remainder
  assign pixel_x = h_count[2:0];
  
  //pixel generator for tile
  always_comb begin
    //draw black if not on map
    if (black_left)
      rgb = 3'b000;
    else if (black_bottom)
      rgb = 3'b000;
  
    //draw blue wall if applicable
    else if (tile_data == 2'b01) begin // wall
      rgb = 3'b001;
    end
    
    //draw 2 by 2 white square in center if applicable
    else if (tile_data == 2'b10) begin // pellet
      if ((pixel_x == 3 || pixel_x == 4) &&
          (pixel_y == 3 || pixel_y == 4))
        rgb = 3'b111;
      else
        rgb = 3'b000;
    end
  
    //draw 6 by 6 white square with black corners if applicable 
    else if (tile_data == 2'b11) begin // power pellet
      if (pixel_x > 0 && pixel_x < 7 &&
          pixel_y > 0 && pixel_y < 7) begin
  
        // black corners
        if ((pixel_x == 1 || pixel_x == 6) &&
            (pixel_y == 1 || pixel_y == 6))
          rgb = 3'b000;
        else
          rgb = 3'b111;
  
      end else
        rgb = 3'b000;
    end
  
    else
      rgb = 3'b000; // blank
  end
  endmodule
