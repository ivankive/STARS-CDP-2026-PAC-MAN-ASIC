module draw_sprite(
    input logic  [9:0] h_count,    //Horizontal Display Counter (max value is 640px)
    input logic  [9:0] v_count,    //Vertical Display Counter (maxvalue is 480px)
    input logic  [4:0] pacman_x,   //pacman tile x position
    input logic  [5:0] pacman_y,   //pacman tile y position
    input logic  [2:0] input_rgb,  //pixel color from draw_tile
    output logic [2:0] output_rgb  //pixel color
  );
  //variables
  logic [4:0] tile_y;           // 0-27 Y tiles
  logic [4:0] tile_x;           // 0-35 X tiles
  logic [2:0] pixel_x, pixel_y; //0-7 pixels in tiles
  
  //determine tile location and pixel position of VGA
  assign tile_y = v_count[7:3]; //quotient
  assign tile_x = h_count[8:3];
  assign pixel_y = v_count[2:0]; //remainder
  assign pixel_x = h_count[2:0];

  //determine whether pixel is pacman
  assign draw_pacman = (tile_x == pacman_x) && (tile_y == pacman_y) && (h_count < 224);

  //pixel generator for tile
  always_comb begin
    //draw black if not on map
    if (draw_pacman)
      output_rgb = 3'b110;
    else
      output_rgb = input_rgb;
  end

endmodule