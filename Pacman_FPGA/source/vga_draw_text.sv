module vga_draw_text(
    input  logic [9:0] h_count,    // Horizontal Display Counter
    input  logic [9:0] v_count,    // Vertical Display Counter
    input  logic       video_on,
    input  logic [1:0] game_state,
    input  logic [2:0] input_rgb,  // pixel color from draw_tile
    output logic [2:0] output_rgb  // pixel color
);

    logic [4:0] tile_y;           // 0-27 Y tiles
    logic [4:0] tile_x;           // 0-35 X tiles
    logic [2:0] pixel_x, pixel_y; // 0-7 pixels in tile
    logic draw_pacman_text;

    // Determine tile location and pixel position
    assign tile_y = v_count[7:3];
    assign tile_x = h_count[7:3];
    assign pixel_y = v_count[2:0];
    assign pixel_x = h_count[2:0];

    assign draw_pacman_text =
        (tile_y >= 5'd18) && (tile_y <= 5'd21) &&
        (tile_x >= 5'd1)  && (tile_x < 5'd27);

    // Pixel generator for text
    always_comb begin
        // Default: pass through background
        output_rgb = input_rgb;

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
        end
    end

endmodule