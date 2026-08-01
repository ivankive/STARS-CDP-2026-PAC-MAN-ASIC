module vga_draw_tile(
  // requests tile to arbiter (shared maze ROM)
  input  logic [9:0] h_count_raw,
  input  logic [9:0] v_count_raw,
  input logic        video_on_raw,

  // draw delayed tile given from RAM
  input  logic [9:0] h_count_d,
  input  logic [9:0] v_count_d,
  input  logic       video_on_d,

  // Arbiter VGA port
  output logic       vga_active,
  output logic [4:0] x_vga,
  output logic [4:0] y_vga,
  input  logic [1:0] tile_data,
  output logic [2:0] output_rgb
);
  logic in_map_raw;
  logic in_map_d;

  //variables
  logic [4:0] tile_x_raw, tile_y_raw;
  logic [2:0] pixel_x_d, pixel_y_d;
  
  //determine tile location and pixel position in tile
  assign tile_x_raw = h_count_raw[7:3];
  assign tile_y_raw = v_count_raw[7:3] + 5'd24;
  assign pixel_y_d = v_count_d[2:0]; //remainder
  assign pixel_x_d = h_count_d[2:0];

  assign in_map_raw = video_on_raw && (tile_x_raw < 5'd24) && (tile_y_raw < 5'd24);
  assign vga_active = in_map_raw;

  always_comb begin
    if (in_map_raw) begin
      x_vga = tile_x_raw;
      y_vga = tile_y_raw;
    end else begin
      x_vga = 5'd0;
      y_vga = 5'd0;
    end
  end

  assign in_map_d = video_on_d && ((h_count_d[7:3]) < 5'd24) && ((v_count_d[7:3] + 5'd24) < 5'd24);
  
  //pixel generator for tile
  always_comb begin
    output_rgb = 3'b000;
    if (!video_on_d || !in_map_d) begin
      output_rgb = 3'b000;
    end else begin
      case (tile_data)
        2'b0: begin 
          output_rgb = 3'b000;
        end
        2'b01: begin
          output_rgb = 3'b001;
        end
        2'b10: begin
          if ((pixel_x_d == 3'd3 || pixel_x_d == 3'd4) && (pixel_y_d == 3'd3 || pixel_y_d == 3'd4)) begin
            output_rgb = 3'b111;
          end else begin
            output_rgb = 3'b000;
          end
        end
        2'b11: begin
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