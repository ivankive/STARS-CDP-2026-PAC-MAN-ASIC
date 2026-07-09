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
  draw_tile_test dt(
  .rgb      ({red, green, blue}),
  .pixel_y  ({pb[6:4]}),
  .pixel_x  ({pb[2:0]}), 
  .tile_data({pb[7], pb[3]}) //when pb 7, ~pb 3 = 10 (a pellet)
  );
  
endmodule

 module draw_tile_test(
    output logic [2:0]rgb,      //pixel color
    input logic [2:0]pixel_y,   
    input logic [2:0]pixel_x,    
    input logic [1:0] tile_data //Tile Data (blank, wall, pellet, power pellet)
  );
  
  //determine tile location and pixel position in tile
  //pixel generator for tile
  always_comb begin
    //draw blue wall if applicable
    if (tile_data == 2'b01) begin // wall
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