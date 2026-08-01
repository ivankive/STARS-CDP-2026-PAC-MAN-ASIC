module vga_draw_sprite(
    input  logic [9:0] h_count,    //Horizontal Display Counter (max value is 640px)
    input  logic [9:0] v_count,    //Vertical Display Counter (maxvalue is 480px)
    input  logic       video_on,   //video on signal from vga_counter
    input  logic [4:0] pacman_x,   //pacman tile x position
    input  logic [4:0] pacman_y,   //pacman tile y position
    input  logic [1:0] pacman_dir, //pacman direction
    input  logic [4:0] blinky_x,
    input  logic [4:0] blinky_y,
    input  logic [1:0] blinky_dir,
    input  logic [4:0] pinky_x,
    input  logic [4:0] pinky_y,
    input  logic [1:0] pinky_dir,
    input  logic [1:0] lives,
    input  logic       pp_active, 
    input  logic [2:0] input_rgb,  //pixel color from draw_tile
    output logic [2:0] output_rgb  //pixel color
  );
  //variables
  logic [4:0] tile_y;           // 0-27 Y tiles
  logic [4:0] tile_x;           // 0-35 X tiles
  logic [2:0] pixel_x, pixel_y; //0-7 pixels in tiles
  logic draw_pacman, draw_circle, draw_blinky, draw_pinky;
  
  //determine tile location and pixel position of VGA
  assign tile_y = v_count[7:3]+24; //quotient
  assign tile_x = h_count[7:3];
  assign pixel_y = v_count[2:0]; //remainder
  assign pixel_x = h_count[2:0];

  //determine whether pixel is pacman
  assign draw_pacman = (tile_x == pacman_x) && (tile_y == pacman_y);
  assign draw_blinky = (tile_x == blinky_x) && (tile_y == blinky_y);
  assign draw_pinky = (tile_x == pinky_x) && (tile_y == pinky_y);

//Sprite pixel generator
  always_comb begin
    //draw black if not on map
    if (draw_pacman && video_on) begin
      if (pacman_dir == 2'b00)      //up?
        casez (pixel_y)
          3'd0 : output_rgb = (pixel_x == 3'd0 || pixel_x == 3'd7)?  3'b110 : 3'b000;
          3'd1 : output_rgb = (pixel_x < 2 || pixel_x > 5)?          3'b110 : 3'b000;
          3'd2 : output_rgb = (pixel_x < 2 || pixel_x > 5)?          3'b110 : 3'b000;
          3'd3 : output_rgb = (pixel_x < 3 || pixel_x > 4)?          3'b110 : 3'b000;
          3'd4 : output_rgb =                                        3'b110         ;
          3'd5 : output_rgb =                                        3'b110         ;
          3'd6 : output_rgb =                                        3'b110         ;
          3'd7 : output_rgb = (pixel_x != 3'd0 || pixel_x != 3'd7)?  3'b110 : 3'b000;     
        endcase

      else if (pacman_dir == 2'b01) //left?
        casez (pixel_y)
          3'd0 : output_rgb = (pixel_x != 3'd7)?  3'b110 :3'b000;
          3'd1 : output_rgb = (pixel_x != 3'd0)?  3'b110: 3'b000;
          3'd2 : output_rgb = (pixel_x > 3'd2 )?  3'b110: 3'b000;
          3'd3 : output_rgb = (pixel_x > 3'd3 )?  3'b110: 3'b000;
          3'd4 : output_rgb = (pixel_x > 3'd3 )?  3'b110: 3'b000;
          3'd5 : output_rgb = (pixel_x > 3'd2 )?  3'b110: 3'b000;
          3'd6 : output_rgb = (pixel_x != 3'd0)?  3'b110: 3'b000;
          3'd7 : output_rgb = (pixel_x != 3'd7)?  3'b110: 3'b000;
        endcase


      else if (pacman_dir == 2'b10) //down?
        casez (pixel_y)
          3'd0 : output_rgb = (pixel_x != 3'd0 || pixel_x != 3'd7)?  3'b110 : 3'b000;
          3'd1 : output_rgb =                                        3'b110         ;
          3'd2 : output_rgb =                                        3'b110         ;
          3'd3 : output_rgb =                                        3'b110         ;
          3'd4 : output_rgb = (pixel_x < 3 || pixel_x > 4)?          3'b110 : 3'b000;
          3'd5 : output_rgb = (pixel_x < 2 || pixel_x > 5)?          3'b110 : 3'b000;
          3'd6 : output_rgb = (pixel_x < 2 || pixel_x > 5)?          3'b110 : 3'b000;
          3'd7 : output_rgb = (pixel_x == 3'd0 || pixel_x == 3'd7)?  3'b110 : 3'b000;
        endcase

      else                          //right?
        casez (pixel_y)
          3'd0 : output_rgb = (pixel_x != 3'b0)?  3'b110: 3'b000;
          3'd1 : output_rgb = (pixel_x != 3'd7)?  3'b110: 3'b000;
          3'd2 : output_rgb = (pixel_x < 3'd5)?   3'b110: 3'b000;
          3'd3 : output_rgb = (pixel_x < 3'd4)?   3'b110: 3'b000;
          3'd4 : output_rgb = (pixel_x < 3'd4)?   3'b110: 3'b000;
          3'd5 : output_rgb = (pixel_x < 3'd5)?   3'b110: 3'b000;
          3'd6 : output_rgb = (pixel_x != 3'd7)?  3'b110: 3'b000;
          3'd7 : output_rgb = (pixel_x != 3'b0)?  3'b110: 3'b000;
        endcase
    end else if (draw_blinky && video_on) begin
      if (pp_active) //powered up
        output_rgb = 3'b011 ;
      else
        output_rgb = 3'b100 ;
    
    end else if (draw_pinky && video_on) begin
      if (pp_active) //powered up
        output_rgb = 3'b011;
      else 
        output_rgb = 3'b101;
        
    end else
      output_rgb = input_rgb;

    //Lives display
    if (lives >= 2'd1) begin
      if((h_count <= 7) && (v_count < 320 && v_count > 311)) begin
        casez (pixel_y)
          3'd0 : output_rgb = (pixel_x != 3'b0)?  3'b110: 3'b000;
          3'd1 : output_rgb = (pixel_x != 3'd7)?  3'b110: 3'b000;
          3'd2 : output_rgb = (pixel_x < 3'd5)?   3'b110: 3'b000;
          3'd3 : output_rgb = (pixel_x < 3'd4)?   3'b110: 3'b000;
          3'd4 : output_rgb = (pixel_x < 3'd4)?   3'b110: 3'b000;
          3'd5 : output_rgb = (pixel_x < 3'd5)?   3'b110: 3'b000;
          3'd6 : output_rgb = (pixel_x != 3'd7)?  3'b110: 3'b000;
          3'd7 : output_rgb = (pixel_x != 3'b0)?  3'b110: 3'b000;
        endcase
      end
    end if (lives >= 2'd2) begin
      if ((h_count < 24 && h_count > 15) && (v_count < 320 && v_count > 311)) begin
        casez (pixel_y)
          3'd0 : output_rgb = (pixel_x != 3'b0)?  3'b110: 3'b000;
          3'd1 : output_rgb = (pixel_x != 3'd7)?  3'b110: 3'b000;
          3'd2 : output_rgb = (pixel_x < 3'd5)?   3'b110: 3'b000;
          3'd3 : output_rgb = (pixel_x < 3'd4)?   3'b110: 3'b000;
          3'd4 : output_rgb = (pixel_x < 3'd4)?   3'b110: 3'b000;
          3'd5 : output_rgb = (pixel_x < 3'd5)?   3'b110: 3'b000;
          3'd6 : output_rgb = (pixel_x != 3'd7)?  3'b110: 3'b000;
          3'd7 : output_rgb = (pixel_x != 3'b0)?  3'b110: 3'b000;
        endcase
      end
      end if (lives >= 2'd3) begin
      if ((h_count <= 39 && h_count > 31) && (v_count < 320 && v_count > 311)) begin
        casez (pixel_y)
          3'd0 : output_rgb = (pixel_x != 3'b0)?  3'b110: 3'b000;
          3'd1 : output_rgb = (pixel_x != 3'd7)?  3'b110: 3'b000;
          3'd2 : output_rgb = (pixel_x < 3'd5)?   3'b110: 3'b000;
          3'd3 : output_rgb = (pixel_x < 3'd4)?   3'b110: 3'b000;
          3'd4 : output_rgb = (pixel_x < 3'd4)?   3'b110: 3'b000;
          3'd5 : output_rgb = (pixel_x < 3'd5)?   3'b110: 3'b000;
          3'd6 : output_rgb = (pixel_x != 3'd7)?  3'b110: 3'b000;
          3'd7 : output_rgb = (pixel_x != 3'b0)?  3'b110: 3'b000;
        endcase
      end
    end
  end



endmodule
