module draw_sprite(
    input logic  [9:0] h_count,    //Horizontal Display Counter (max value is 640px)
    input logic  [9:0] v_count,    //Vertical Display Counter (maxvalue is 480px)
    input logic  [2:0] input_rgb,  //pixel color from draw_tile
    output logic [2:0] output_rgb  //pixel color
  );
  //pixel generator for text
  always_comb begin
      output_rgb = input_rgb;
  end

endmodule