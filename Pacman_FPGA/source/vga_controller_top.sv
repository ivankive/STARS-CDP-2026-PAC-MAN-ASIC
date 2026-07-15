module vga_controller_top(

    input logic pixel_clk, rst,
    output logic [2:0] rgb,
    output logic hsync,
    output logic vsync,

    // to RAM

    output logic [4:0] x_out,
    output logic [4:0] y_out, 

     //draw_sprite
    input logic [4:0] pacman,
    input logic [4:0] pacman,
    input logic [1:0] pacman_dir
);

    logic [9:0] hcount, vcount;
    logic [2:0] rgb_tile, rgb_sprite, rgb_border, rgb_text;
    logic video_on;

    vga_counter vga_counter(
        .clk(pixel_clk),        //inputs
        .rst(rst),
        .hsync(hsync),          //outputs to VGA
        .vsync(vsync),
        .hcount(hcount),        //outputs to draw_XXXX
        .vcount(vcount),
        .video_on(video_on)
    );

    vga_draw_tile draw_tile (
        .h_count   (hcount),
        .v_count   (vcount),
        .video_on  (video_on),
        .output_rgb(rgb_tile)
    );

    vga_draw_sprite draw_sprite(
        .h_count(hcount),        //inputs from VGA_counter
        .v_count(vcount),
        .video_on(video_on),
        .pacman_x(pacman_x),    //inputs from pacman_controller
        .pacman_y(pacman_y),
        .pacman_dir(pacman_dir),
      //.ghost_x(ghost_x),        //inputs from ghost_controller
      //.ghost_y(ghost_y),
        .input_rgb(rgb_tile),   //inputs from draw_tile
        .output_rgb(rgb_sprite) //outputs to draw_text
    );

    vga_draw_border draw_border(
        .h_count(hcount),        //inputs from VGA_counter
        .v_count(vcount),
        .video_on(video_on),
        .input_rgb(rgb_sprite), //inputs from draw_sprite
        .output_rgb(rgb_border)   //outputs to draw_text
    );

    vga_draw_text draw_text(
        .h_count(hcount),        //inputs from VGA_counter
        .v_count(vcount),
        .video_on(video_on),
      //.score(8'd0),           //inputs from central control system
        .input_rgb(rgb_border), //inputs from draw_border
        .output_rgb(rgb_text)   //outputs to VGA
    );
    
    assign rgb[0] = rgb_text[2]; //output to VGA
    assign rgb[1] = rgb_text[1];
    assign rgb[2] = rgb_text[0];

    // to RAM

    assign x__out = 
    assign x__out = 

endmodule
