module draw_tile(
    output logic [2:0]  rgb,       //pixel color
    input logic  [9:0]  h_count,   //Horizontal Display Counter (max value is 640px)
    input logic  [9:0]  v_count    //Vertical Display Counter (maxvalue is 480px)
  );
  //variables
  logic black_left, black_bottom;
  logic [4:0] tile_y;           // 0-27 Y tiles
  logic [5:0] tile_x;           // 0-35 X tiles
  logic [2:0] pixel_x, pixel_y; //0-7 pixels in tiles
  logic [9:0] tile_addr;
  logic [1:0] tile_data;
  
  //determine whether pixel is in the map
  assign black_left   = ((h_count >= 416) && (h_count < 640) && (v_count >= 0)   && (v_count < 480));
  assign black_bottom = ((h_count >= 0)   && (h_count < 640) && (v_count >= 192) && (v_count < 480));
  
  //determine tile location and pixel position in tile
  assign tile_y = v_count[7:3]; //quotient
  assign tile_x = h_count[8:3];
  assign pixel_y = v_count[2:0]; //remainder
  assign pixel_x = h_count[2:0];
  
  assign tile_data = 2'b11;
  //determine tile_data
    //assign tile_addr = 27 * tile_y + tile_x
    //get tile data
  
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