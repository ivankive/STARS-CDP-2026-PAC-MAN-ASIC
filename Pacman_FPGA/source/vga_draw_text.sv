module vga_draw_text(
    input logic  [9:0] h_count,    //Horizontal Display Counter (max value is 640px)
    input logic  [9:0] v_count,    //Vertical Display Counter (maxvalue is 480px)
    input logic        video_on,  
    input logic  [9:0] score,                              //video on signal from vga_counter
    input logic  [2:0] input_rgb,  //pixel color from draw_tile
    output logic [2:0] output_rgb  //pixel color
  );


  logic [4:0] tile_y;           // 0-27 Y tiles
  logic [4:0] tile_x;           // 0-35 X tiles
  logic [2:0] pixel_x, pixel_y; //0-7 pixels in tiles
  logic draw_s, draw_c, draw_o, draw_r, draw_e;
  logic score_pos;
  
  //determine tile location and pixel position of VGA
  assign tile_y = v_count[7:3]; //quotient
  assign tile_x = h_count[7:3];
  assign pixel_y = v_count[2:0]; //remainder
  assign pixel_x = h_count[2:0];


assign draw_s = (h_count <= 7) && (h_count > 0) && (v_count < 8);
assign draw_c = (h_count <= 15) && (h_count > 7) && (v_count < 8);
assign draw_o = (h_count <= 23) && (h_count > 15) && (v_count < 8);
assign draw_r = (h_count <= 31) && (h_count > 23) && (v_count < 8);
assign draw_e = (h_count <= 39) && (h_count > 31) && (v_count < 8);

  //pixel generator for text
  always_comb begin
      if (draw_s && video_on)begin
        casez (pixel_y)
          3'd0 : output_rgb  =  3'b111;
          3'd1 : output_rgb =   3'b111;
          3'd2 : output_rgb = (pixel_x < 3)?  3'b111 : 3'b000;
          3'd3 : output_rgb =   3'b111;
          3'd4 : output_rgb =   3'b111;
          3'd5 : output_rgb =  (pixel_x > 5)?  3'b111 : 3'b000;
          3'd6 : output_rgb =  3'b111;
          3'd7 : output_rgb =  3'b111;     
        endcase
     
      end else if (draw_c && video_on)begin
        casez (pixel_y)
          3'd0 : output_rgb = (pixel_x != 0 && pixel_x != 6)?        3'b111 : 3'b000;
          3'd1 : output_rgb = (pixel_x != 0 && pixel_x != 6)?        3'b111 : 3'b000;
          3'd2 : output_rgb = (pixel_x ==1  || pixel_x == 2)?         3'b111 : 3'b000;
          3'd3 : output_rgb = (pixel_x ==1  || pixel_x == 2)?         3'b111 : 3'b000;
          3'd4 : output_rgb = (pixel_x ==1  || pixel_x == 2)?         3'b111 : 3'b000;
          3'd5 : output_rgb = (pixel_x ==1  || pixel_x == 2)?         3'b111 : 3'b000;
          3'd6 : output_rgb = (pixel_x != 0 && pixel_x != 6)?        3'b111 : 3'b000;
          3'd7 : output_rgb = (pixel_x != 0 && pixel_x != 6)?        3'b111 : 3'b000;    
        endcase
     
      end else if (draw_o && video_on)begin
        casez (pixel_y)
          3'd0 : output_rgb  =  3'b111;
          3'd1 : output_rgb  =  3'b111;
          3'd2 : output_rgb = (pixel_x < 3 || pixel_x > 6)?          3'b111 : 3'b000;
          3'd3 : output_rgb = (pixel_x < 3 || pixel_x > 6)?          3'b111 : 3'b000;
          3'd4 : output_rgb = (pixel_x < 3 || pixel_x > 6)?          3'b111 : 3'b000;
          3'd5 : output_rgb = (pixel_x < 3 || pixel_x > 6)?          3'b111 : 3'b000;
          3'd6 : output_rgb  =  3'b111;
          3'd7 : output_rgb  =  3'b111; 
        endcase


      end else if (draw_r && video_on)begin
        casez (pixel_y)
          3'd0 : output_rgb = (pixel_x > 0)?                                                   3'b111 : 3'b000;
          3'd1 : output_rgb = (pixel_x != 0 || pixel_x != 3 || pixel_x !=4 || pixel_x != 5)?   3'b111 : 3'b000;
          3'd2 : output_rgb = (pixel_x != 0 || pixel_x != 3 || pixel_x !=4 || pixel_x != 5)?   3'b111 : 3'b000;
          3'd3 : output_rgb = (pixel_x > 0)?                                                   3'b111 : 3'b000;
          3'd4 : output_rgb = (pixel_x > 0 || pixel_x < 6)?                                    3'b111 : 3'b000;
          3'd5 : output_rgb = ((pixel_x > 1 && pixel_x < 3)|| (pixel_x > 3 && pixel_x < 7))?   3'b111 : 3'b000;
          3'd6 : output_rgb = ((pixel_x > 1 && pixel_x < 3)|| pixel_x > 4)?                    3'b111 : 3'b000;
          3'd7 : output_rgb = ((pixel_x > 1 && pixel_x < 3)|| pixel_x > 5)?                    3'b111 : 3'b000;    
        endcase


      end else if (draw_e && video_on)begin
        casez (pixel_y)
          3'd0 : output_rgb = (pixel_x> 1 && pixel_x < 7)?           3'b111 : 3'b000;
          3'd1 : output_rgb = (pixel_x> 1 && pixel_x < 7)?           3'b111 : 3'b000;
          3'd2 : output_rgb = (pixel_x == 3 || pixel_x == 2)?        3'b111 : 3'b000;
          3'd3 : output_rgb = (pixel_x> 1 && pixel_x < 7)?           3'b111 : 3'b000;
          3'd4 : output_rgb = (pixel_x> 1 && pixel_x < 7)?           3'b111 : 3'b000;
          3'd5 : output_rgb = (pixel_x == 3 || pixel_x == 2)?        3'b111 : 3'b000;
          3'd6 : output_rgb = (pixel_x> 1 && pixel_x < 7)?           3'b111 : 3'b000;
          3'd7 : output_rgb = (pixel_x> 1 && pixel_x < 7)?           3'b111 : 3'b000;    
        endcase



      end else

        output_rgb = input_rgb;

  end



endmodule


