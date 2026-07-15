module vga_draw_tile(
  input  logic       map_loaded,

  // requests tile to RAM
  input  logic [9:0] h_count_raw,
  input  logic [9:0] v_count_raw,
  input logic        video_on_raw,

  // draw delayed tile given from RAM
  input  logic [9:0] h_count_d,
  input  logic [9:0] v_count_d,
  input  logic       video_on_d,

  // RAM VGA port
  output logic [4:0] x_vga,
  output logic [4:0] y_vga,
  input  logic [1:0] tile_data,
  output logic [2:0] output_rgb
);
  logic in_map_raw;
  logic in_map_d;

  //variables
  logic black_right, black_bottom, black_top;
  logic [4:0] tile_x_raw, tile_y_raw;
  logic [2:0] pixel_x_d, [2:0] pixel_y_d;
  logic [1:0] tile_data;
  
  //determine tile location and pixel position in tile
  assign tile_x_raw = h_count_raw[7:3];
  assign tile_y_raw = v_count_raw[7:3] + 5'd24;
  assign pixel_y_d = v_count_d[2:0]; //remainder
  assign pixel_x_d = h_count_d[2:0];

  assign in_map_raw = video_on_raw && (tile_x_raw < 5'd28) && (tile_y_raw < 5'd31);

  if (in_map_raw) begin
    x_vga = tile_x_raw;
    y_vga = tile_y_raw;
  end else begin
    x_vga = 5'd0;
    y_vga = 5'd0;
  end

  assign in_map_d = video_on_d && ((h_count_d[7:3]) < 5'd28) && ((v_count_d[7:3] + 5'd24) < 5'd31);
  
  //pixel generator for tile
  always_comb begin
    output_rgb = 3'b000;
    if (!video_on_d || !map_loaded || !in_map_d) begin
      output_rgb = 3'b000;
    end else begin
      case (tile_data)
        2'b0: begin 
          output_rgb = 3'b000;
        end
        2;b01: begin
          output_rgb = 3'b001;
        end
        2'b10: begin
          if ((pixel_x_d == 3'd3 || pixel_x_d == 3'd4) && (pixel_y_d == 3'd3 || pixel_y_d == 3'd4)) begin
            output_rgb = 3'b111;
          end else begin
            output_rgb = 3'b000;
          end
        end
        2b'11: begin
          if ((pixel_x_d > 3'd0) && (pixel_x_d < 3'd7) && (pixel_y_d > 3'd0) && (pixel_y_d < 3'd7)) begin
            if ((pixel_x_d == 3'd1 || pixel_x_d == 3'd6) && (pixel_y_d == 3'd1 || pixel_y_d == 3'd6)) begin
              output_rgb = 3'b000;
            end else begin
              output_rgb = 3'b111;
            end
          end else begin
            output_rgb = 3'b000;
          end
        end
        default: begin
          output_rgb = 3'b000;
        end
      endcase
    end
  end
endmodule