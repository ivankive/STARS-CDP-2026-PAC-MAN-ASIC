module vga_draw_border(
    input logic  [9:0] h_count,    //Horizontal Display Counter (max value is 640px)
    input logic  [9:0] v_count,    //Vertical Display Counter (maxvalue is 480px)
    input logic  [2:0] input_rgb,  //pixel color from draw_sprite
    output logic [2:0] output_rgb  //pixel color
  );
  //variables
    logic black_right, black_bottom, black_top;


  //determine whether pixel is in the map
  assign black_right   = ((h_count >= 224));
  assign black_bottom = ((v_count >= (288+24)) && (v_count < 480));
  assign black_top    = ((v_count < 64));


  //pixel generator for tile
  always_comb begin
    //draw black if not on map
    if (black_right)
      output_rgb = 3'b000;
    else if (black_bottom)
      output_rgb = 3'b000;
    else if (black_top)
      output_rgb = 3'b000;
    //draw blue wall if applicable
    else
      output_rgb = input_rgb;
  end
endmodule
