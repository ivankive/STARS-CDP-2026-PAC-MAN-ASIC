// vga_controller_top - tapeout version
//
// Changes vs FPGA version:
//  * vga_draw_text (score digits + "PRESS BUTTON" banner) removed, along
//    with the score and game_state inputs it consumed. The draw chain is
//    now tile -> sprite -> border.
//  * The maze read port now talks to maze_query_arbiter instead of the
//    old maze_bram; same 1-cycle read latency, plus a vga_active strobe
//    so the arbiter knows when the VGA owns the ROM.
//  * map_loaded removed (there is no maze reload phase any more).

module vga_controller_top(

    input logic pixel_clk, rst,
    output logic [2:0] rgb,
    output logic hsync,
    output logic vsync,

    // Maze arbiter VGA read port
    output logic       vga_active,
    output logic [4:0] x_vga,
    output logic [4:0] y_vga,
    input  logic [1:0] rdata_vga,

    //sprites
    input logic [4:0] pacman_x,
    input logic [4:0] pacman_y,
    input logic [1:0] pacman_dir,
    input logic [4:0] blinky_x,
    input logic [4:0] blinky_y,
    input logic [1:0] blinky_dir,
    input logic [4:0] pinky_x,
    input logic [1:0] pinky_dir,
    input logic [4:0] pinky_y,
    input logic       pp_active,
    input logic [1:0] lives
);
    logic [9:0] hcount_raw, vcount_raw;
    logic       hsync_raw, vsync_raw;
    logic       video_on_raw;

    logic [9:0] hcount_d, vcount_d;
    logic       hsync_d, vsync_d;
    logic       video_on_d;

    logic [2:0] rgb_tile, rgb_sprite, rgb_border;

    vga_counter vga_counter(
        .clk(pixel_clk),
        .rst(rst),
        .hsync(hsync_raw),
        .vsync(vsync_raw),
        .hcount(hcount_raw),
        .vcount(vcount_raw),
        .video_on(video_on_raw)
    );

    always_ff @(posedge pixel_clk or posedge rst) begin
        if (rst) begin
            hcount_d   <= 10'd0;
            vcount_d   <= 10'd0;
            hsync_d    <= 1'b1;
            vsync_d    <= 1'b1;
            video_on_d <= 1'b0;
        end else begin
            hcount_d   <= hcount_raw;
            vcount_d   <= vcount_raw;
            hsync_d    <= hsync_raw;
            vsync_d    <= vsync_raw;
            video_on_d <= video_on_raw;
        end
    end

    assign hsync = hsync_d;
    assign vsync = vsync_d;

    vga_draw_tile draw_tile (
        .h_count_raw (hcount_raw),
        .v_count_raw (vcount_raw),
        .video_on_raw(video_on_raw),
        .h_count_d   (hcount_d),
        .v_count_d   (vcount_d),
        .video_on_d  (video_on_d),
        .vga_active  (vga_active),
        .x_vga       (x_vga),
        .y_vga       (y_vga),
        .tile_data   (rdata_vga),
        .output_rgb  (rgb_tile)
    );

    vga_draw_sprite draw_sprite(
        .h_count   (hcount_d),        //inputs from VGA_counter
        .v_count   (vcount_d),
        .video_on  (video_on_d),
        .pacman_x  (pacman_x),    //inputs from pacman_controller
        .pacman_y  (pacman_y),
        .pacman_dir(pacman_dir),
        .blinky_x   (blinky_x),   //inputs from ghost_controller
        .blinky_y   (blinky_y),
        .blinky_dir (blinky_dir),
        .pinky_x    (pinky_x),
        .pinky_y    (pinky_y),
        .pinky_dir  (pinky_dir),
        .pp_active  (pp_active),
        .lives      (lives),
        .input_rgb  (rgb_tile),   //inputs from draw_tile
        .output_rgb (rgb_sprite)  //outputs to border
    );

    vga_draw_border draw_border(
        .h_count(hcount_d),        //inputs from VGA_counter
        .v_count(vcount_d),
        .video_on(video_on_d),
        .input_rgb(rgb_sprite),  //inputs from draw_sprite
        .output_rgb(rgb_border)
    );

    assign rgb[0] = rgb_border[2]; //output to VGA
    assign rgb[1] = rgb_border[1];
    assign rgb[2] = rgb_border[0];

endmodule
