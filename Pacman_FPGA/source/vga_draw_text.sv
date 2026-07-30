module vga_draw_text(
    input  logic [9:0] h_count,    // Horizontal Display Counter
    input  logic [9:0] v_count,    // Vertical Display Counter
    input  logic       video_on, 
    input  logic [9:0] score,      //binary score from central control system
    input  logic [1:0] game_state,
    input  logic [2:0] input_rgb,  // pixel color from draw_tile
    output logic [2:0] output_rgb  // pixel color
);

    logic [4:0] tile_y;           // 0-27 Y tiles
    logic [4:0] tile_x;           // 0-35 X tiles
    logic [2:0] pixel_x, pixel_y; // 0-7 pixels in tile
    logic draw_pacman_text, draw_lose_text, draw_win_text, draw_press_button_text; // whether to draw the text or not
    logic draw_s, draw_c, draw_o, draw_r, draw_e;
 
  // digit tile enables (to the right of "SCORE")
    logic draw_hundreds, draw_tens, draw_ones;
    // Determine tile location and pixel position
    assign tile_y = v_count[7:3];
    assign tile_x = h_count[7:3];
    assign pixel_y = v_count[2:0];
    assign pixel_x = h_count[2:0];

    assign draw_pacman_text =
        (tile_y >= 5'd18) && (tile_y <= 5'd21) &&
        (tile_x >= 5'd1)  && (tile_x < 5'd27);

    assign draw_lose_text =
        (tile_y >= 5'd18) && (tile_y <= 5'd21) &&
        (tile_x >= 5'd3)  && (tile_x < 5'd25);

    assign draw_win_text =
        (tile_y >= 5'd18) && (tile_y <= 5'd21) &&
        (tile_x >= 5'd4)  && (tile_x < 5'd25);

    assign draw_press_button_text =
        (tile_y == 5'd24) &&
        (tile_x >= 5'd7)  && (tile_x < 5'd21);

    assign draw_s = (h_count <= 7) && (h_count > 0) && (v_count < 8);
    assign draw_c = (h_count <= 15) && (h_count > 7) && (v_count < 8);
    assign draw_o = (h_count <= 23) && (h_count > 15) && (v_count < 8);
    assign draw_r = (h_count <= 31) && (h_count > 23) && (v_count < 8);
    assign draw_e = (h_count <= 39) && (h_count > 31) && (v_count < 8); 


    // tile 5 is a blank gap.
    // tile 6 = hundreds, tile 7 = tens, tile 8 = ones.
    assign draw_hundreds = (h_count >= 48) && (h_count < 56) && (v_count < 8);
    assign draw_tens     = (h_count >= 56) && (h_count < 64) && (v_count < 8);
    assign draw_ones     = (h_count >= 64) && (h_count < 72) && (v_count < 8);
 


    // binary score -> decimal digits (updates every frame, so the
    // display changes automatically the moment `score` changes)
    assign hundreds = 4'((score / 10'd100) % 10'd10);
    assign tens     = 4'((score / 10'd10)  % 10'd10);
    assign ones     = 4'( score            % 10'd10);

    always_comb begin
        if  (draw_tens) 
        cur_digit = tens;
        else if (draw_ones) 
        cur_digit = ones;
        else                
        cur_digit = hundreds;
    end

    assign cur_row = digit_row(cur_digit, pixel_y);
    assign cur_pix = cur_row[3'd7 - pixel_x];

    // decimal digits of the binary score
    logic [3:0] hundreds, tens, ones;

    logic [3:0] cur_digit;   // which digit this tile shows
    logic [7:0] cur_row;     // that digit's glyph row
    logic       cur_pix;     // the single pixel we want
    
    
    localparam [113:0] ROW2 = 114'h39cf39c32511c97df3247cc1c8322;
    localparam [113:0] ROW3 = 114'h25284204b511291044b41121284a2;
    localparam [113:0] ROW4 = 114'h39ce3987ace1c91044ac1121c879c;
    localparam [113:0] ROW5 = 114'h21480844a441291044a4112108488;
    localparam [113:0] ROW6 = 114'h212f7384a441c610432410c10f488;

    logic pixel_on; // whether to draw the text pixel or not

    // Pixel generator for text
    logic [9:0] text_x;

    always_comb begin
        pixel_on = 1'b0;
        text_x = h_count - 10'd56;   // tile 7 = 7*8 = 56

        if (draw_press_button_text && text_x < 114) begin
            case (pixel_y)
                3'd2: pixel_on = ROW2[113-text_x];
                3'd3: pixel_on = ROW3[113-text_x];
                3'd4: pixel_on = ROW4[113-text_x];
                3'd5: pixel_on = ROW5[113-text_x];
                3'd6: pixel_on = ROW6[113-text_x];
                default: pixel_on = 1'b0;
            endcase
        end
    end





    always_comb begin
        // Default: pass through background
        output_rgb = input_rgb;
        //draw press any button to play text

        if (game_state == 2'b00 && draw_pacman_text && video_on) begin
            case (tile_y)

                // P  A  C  M  A  N
                5'd18:
                    output_rgb =
                        (tile_x != 4  &&
                         tile_x != 8  &&
                         tile_x != 12 &&
                         tile_x != 18 &&
                         tile_x != 22 &&
                         tile_x != 24 &&
                         tile_x != 25)
                        ? 3'b111 : input_rgb;

                5'd19:
                    output_rgb =
                        (tile_x != 2  &&
                         tile_x != 4  &&
                         tile_x != 6  &&
                         tile_x != 8  &&
                         tile_x != 10 &&
                         tile_x != 11 &&
                         tile_x != 12 &&
                         tile_x != 14 &&
                         tile_x != 16 &&
                         tile_x != 18 &&
                         tile_x != 20 &&
                         tile_x != 22 &&
                         tile_x != 25)
                        ? 3'b111 : input_rgb;

                5'd20:
                    output_rgb =
                        (tile_x != 4  &&
                         tile_x != 8  &&
                         tile_x != 10 &&
                         tile_x != 11 &&
                         tile_x != 12 &&
                         tile_x != 14 &&
                         tile_x != 16 &&
                         tile_x != 18 &&
                         tile_x != 22 &&
                         tile_x != 24)
                        ? 3'b111 : input_rgb;

                5'd21:
                    output_rgb =
                        (tile_x != 2  &&
                         tile_x != 3  &&
                         tile_x != 4  &&
                         tile_x != 6  &&
                         tile_x != 8  &&
                         tile_x != 12 &&
                         tile_x != 14 &&
                         tile_x != 16 &&
                         tile_x != 18 &&
                         tile_x != 20 &&
                         tile_x != 22 &&
                         tile_x != 24 &&
                         tile_x != 25)
                        ? 3'b111 : input_rgb;

                default: ;
            endcase
        end else if (game_state == 2'b10 && draw_lose_text && video_on) begin
            case (tile_y)

                // U SUCK!
                5'd18:
                      output_rgb =
                          (tile_x != 4  &&
                          tile_x != 6  &&
                          tile_x != 7 &&
                          tile_x != 9 &&
                          tile_x != 10 &&
                          tile_x != 11 &&
                          tile_x != 15 &&
                          tile_x != 19 &&
                          tile_x != 23)
                          ? 3'b111 : input_rgb;

                5'd19:
                      output_rgb =
                          (tile_x != 4  &&
                          tile_x != 6  &&
                          tile_x != 7  &&
                          tile_x != 9 &&
                          tile_x != 10 &&
                          tile_x != 11 &&
                          tile_x != 13 &&
                          tile_x != 15 && 
                          tile_x != 17 && //.5
                          tile_x != 18 && //.5
                          tile_x != 19 &&
                          tile_x != 21 && //.5
                          tile_x != 22 && //.5
                          tile_x != 23)   
                          ? 3'b111 : ((tile_x == 17 || tile_x == 18 || tile_x == 21 || tile_x == 22) && pixel_y >= 3'd5) ? 3'b111 : input_rgb;

                5'd20:
                      output_rgb =
                          (tile_x != 4  &&
                          tile_x != 6  &&
                          tile_x != 7  &&
                          tile_x != 9 &&
                          tile_x != 10 &&
                          tile_x != 11 &&
                          tile_x != 13 &&
                          tile_x != 15 && 
                          tile_x != 16 && //.5
                          tile_x != 17 && //.5
                          tile_x != 19 &&
                          tile_x != 21 && //.5
                          tile_x != 22 && //.5
                          tile_x != 23 &&
                          tile_x != 24) //.5   
                          ? 3'b111 : ((tile_x == 16 || tile_x == 17 || tile_x == 21 || tile_x == 22 || tile_x == 24) && pixel_y <= 3'd3) ? 3'b111 : input_rgb;

                5'd21:
                    output_rgb =
                        (tile_x != 6  &&
                         tile_x != 7  &&
                         tile_x != 11  &&
                         tile_x != 15  &&
                         tile_x != 19  &&
                         tile_x != 23
                        )
                        ? 3'b111 : input_rgb;

                default: ;
            endcase

        end else if (game_state == 2'b11 && draw_win_text && video_on) begin
            case (tile_y)

                // U WIN!
                5'd18:
                      output_rgb =
                          (tile_x != 5  &&
                          tile_x != 7  &&
                          tile_x != 8 &&
                          tile_x != 10 &&
                          tile_x != 11 &&
                          tile_x != 12 &&
                          tile_x != 14 &&
                          tile_x != 18 &&
                          tile_x != 20 &&
                          tile_x != 21 &&
                          tile_x != 23)
                          ? 3'b111 : input_rgb;

                5'd19:
                      output_rgb =
                          (tile_x != 5  &&
                          tile_x != 7  &&
                          tile_x != 8 &&
                          tile_x != 10 &&
                          tile_x != 12 &&
                          tile_x != 14 &&
                          tile_x != 15 &&
                          tile_x != 17 &&
                          tile_x != 18 &&
                          tile_x != 21 &&
                          tile_x != 23)
                          ? 3'b111 : input_rgb;

                5'd20:
                      output_rgb =
                          (tile_x != 5  &&
                          tile_x != 7  &&
                          tile_x != 8 &&
                          tile_x != 10 &&
                          tile_x != 12 &&
                          tile_x != 14 &&
                          tile_x != 15 &&
                          tile_x != 17 &&
                          tile_x != 18 &&
                          tile_x != 20 &&
                          tile_x != 23 &&
                          tile_x != 24)
                          ? 3'b111 : (tile_x == 24 && pixel_y <= 3'd3) ? 3'b111 : input_rgb;

                5'd21:
                      output_rgb =
                          (
                          tile_x != 7  &&
                          tile_x != 8 &&
                          tile_x != 9 &&
                          tile_x != 11 &&
                          tile_x != 13 &&
                          tile_x != 14 &&
                          tile_x != 18 &&
                          tile_x != 20 &&
                          tile_x != 21 &&
                          tile_x != 23)
                          ? 3'b111 : input_rgb;

                default: ;
            endcase
        
        end else if (game_state != 2'b01 && draw_press_button_text && video_on) begin

          output_rgb = pixel_on ? 3'b111 : input_rgb;

        end else if (draw_s && video_on)begin
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
            3'd0 : output_rgb = (pixel_x != 0 && pixel_x <  7)?        3'b111 : 3'b000;
            3'd1 : output_rgb = (pixel_x != 0 && pixel_x <  7)?        3'b111 : 3'b000;
            3'd2 : output_rgb = (pixel_x ==1  || pixel_x == 2)?        3'b111 : 3'b000;
            3'd3 : output_rgb = (pixel_x ==1  || pixel_x == 2)?        3'b111 : 3'b000;
            3'd4 : output_rgb = (pixel_x ==1  || pixel_x == 2)?        3'b111 : 3'b000;
            3'd5 : output_rgb = (pixel_x ==1  || pixel_x == 2)?        3'b111 : 3'b000;
            3'd6 : output_rgb = (pixel_x != 0 && pixel_x <  7)?        3'b111 : 3'b000;
            3'd7 : output_rgb = (pixel_x != 0 && pixel_x <  7)?        3'b111 : 3'b000;    
          endcase
      
        end else if (draw_o && video_on)begin
          casez (pixel_y)
            3'd0 : output_rgb  =  3'b111;
            3'd1 : output_rgb  =  3'b111;
            3'd2 : output_rgb = (pixel_x < 2 || pixel_x > 6)?          3'b111 : 3'b000;
            3'd3 : output_rgb = (pixel_x < 2 || pixel_x > 6)?          3'b111 : 3'b000;
            3'd4 : output_rgb = (pixel_x < 2 || pixel_x > 6)?          3'b111 : 3'b000;
            3'd5 : output_rgb = (pixel_x < 2 || pixel_x > 6)?          3'b111 : 3'b000;
            3'd6 : output_rgb  =  3'b111;
            3'd7 : output_rgb  =  3'b111; 
          endcase
  
  
        end else if (draw_r && video_on)begin
          casez (pixel_y)
            3'd0 : output_rgb = (pixel_x > 0)?                                                   3'b111 : 3'b000;
            3'd1 : output_rgb = (pixel_x != 0 && pixel_x != 3 && pixel_x !=4 && pixel_x != 5)?   3'b111 : 3'b000;
            3'd2 : output_rgb = (pixel_x != 0 && pixel_x != 3 && pixel_x !=4 && pixel_x != 5)?   3'b111 : 3'b000;
            3'd3 : output_rgb = (pixel_x > 0)?                                                   3'b111 : 3'b000;
            3'd4 : output_rgb = (pixel_x > 0 || pixel_x < 6)?                                    3'b111 : 3'b000;
            3'd5 : output_rgb = ((pixel_x > 0 && pixel_x < 3)|| (pixel_x > 3 && pixel_x < 7))?   3'b111 : 3'b000;
            3'd6 : output_rgb = ((pixel_x > 0 && pixel_x < 3)|| pixel_x > 4)?                    3'b111 : 3'b000;
            3'd7 : output_rgb = ((pixel_x > 0 && pixel_x < 3)|| pixel_x > 5)?                    3'b111 : 3'b000;    
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
 




    // draw numbers
    // basically a function gives you the values of the pixels in a row based on the height of the pixel y and then
    // access the value of the pixel you access it through array indexing and the leftmost is 7

       end else if ((draw_hundreds || draw_tens || draw_ones) && video_on) begin

            output_rgb = cur_pix ? 3'b111 : 3'b000;

       end else

        output_rgb = input_rgb;


    end



    function automatic logic [7:0] digit_row(input logic [3:0] digit, input logic [2:0] row);
    
    
    case (digit)
      4'd0: case (row)
        3'd0: digit_row = 8'b00111100;
        3'd1: digit_row = 8'b01100110;
        3'd2: digit_row = 8'b01100110;
        3'd3: digit_row = 8'b01100110;
        3'd4: digit_row = 8'b01100110;
        3'd5: digit_row = 8'b01100110;
        3'd6: digit_row = 8'b00111100;
        3'd7: digit_row = 8'b00000000;
      endcase
      4'd1: case (row)
        3'd0: digit_row = 8'b00011000;
        3'd1: digit_row = 8'b00111000;
        3'd2: digit_row = 8'b00011000;
        3'd3: digit_row = 8'b00011000;
        3'd4: digit_row = 8'b00011000;
        3'd5: digit_row = 8'b00011000;
        3'd6: digit_row = 8'b01111110;
        3'd7: digit_row = 8'b00000000;
      endcase
      4'd2: case (row)
        3'd0: digit_row = 8'b00111100;
        3'd1: digit_row = 8'b01100110;
        3'd2: digit_row = 8'b00000110;
        3'd3: digit_row = 8'b00001100;
        3'd4: digit_row = 8'b00110000;
        3'd5: digit_row = 8'b01100000;
        3'd6: digit_row = 8'b01111110;
        3'd7: digit_row = 8'b00000000;
      endcase
      4'd3: case (row)
        3'd0: digit_row = 8'b00111100;
        3'd1: digit_row = 8'b01100110;
        3'd2: digit_row = 8'b00000110;
        3'd3: digit_row = 8'b00011100;
        3'd4: digit_row = 8'b00000110;
        3'd5: digit_row = 8'b01100110;
        3'd6: digit_row = 8'b00111100;
        3'd7: digit_row = 8'b00000000;
      endcase
      4'd4: case (row)
        3'd0: digit_row = 8'b00001100;
        3'd1: digit_row = 8'b00011100;
        3'd2: digit_row = 8'b00111100;
        3'd3: digit_row = 8'b01101100;
        3'd4: digit_row = 8'b01111110;
        3'd5: digit_row = 8'b00001100;
        3'd6: digit_row = 8'b00001100;
        3'd7: digit_row = 8'b00000000;
      endcase
      4'd5: case (row)
        3'd0: digit_row = 8'b01111110;
        3'd1: digit_row = 8'b01100000;
        3'd2: digit_row = 8'b01111100;
        3'd3: digit_row = 8'b00000110;
        3'd4: digit_row = 8'b00000110;
        3'd5: digit_row = 8'b01100110;
        3'd6: digit_row = 8'b00111100;
        3'd7: digit_row = 8'b00000000;
      endcase
      4'd6: case (row)
        3'd0: digit_row = 8'b00111100;
        3'd1: digit_row = 8'b01100000;
        3'd2: digit_row = 8'b01100000;
        3'd3: digit_row = 8'b01111100;
        3'd4: digit_row = 8'b01100110;
        3'd5: digit_row = 8'b01100110;
        3'd6: digit_row = 8'b00111100;
        3'd7: digit_row = 8'b00000000;
      endcase
      4'd7: case (row)
        3'd0: digit_row = 8'b01111110;
        3'd1: digit_row = 8'b00000110;
        3'd2: digit_row = 8'b00001100;
        3'd3: digit_row = 8'b00011000;
        3'd4: digit_row = 8'b00110000;
        3'd5: digit_row = 8'b00110000;
        3'd6: digit_row = 8'b00110000;
        3'd7: digit_row = 8'b00000000;
      endcase
      4'd8: case (row)
        3'd0: digit_row = 8'b00111100;
        3'd1: digit_row = 8'b01100110;
        3'd2: digit_row = 8'b01100110;
        3'd3: digit_row = 8'b00111100;
        3'd4: digit_row = 8'b01100110;
        3'd5: digit_row = 8'b01100110;
        3'd6: digit_row = 8'b00111100;
        3'd7: digit_row = 8'b00000000;
      endcase
      4'd9: case (row)
        3'd0: digit_row = 8'b00111100;
        3'd1: digit_row = 8'b01100110;
        3'd2: digit_row = 8'b01100110;
        3'd3: digit_row = 8'b00111110;
        3'd4: digit_row = 8'b00000110;
        3'd5: digit_row = 8'b00000110;
        3'd6: digit_row = 8'b00111100;
        3'd7: digit_row = 8'b00000000;
      endcase
      default: digit_row = 8'b00000000;

      endcase

    endfunction

endmodule