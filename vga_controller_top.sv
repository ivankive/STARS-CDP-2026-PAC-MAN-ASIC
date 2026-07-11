module vga_controller(

    input logic pixel_clk, rst,
    output logic [2:0] rgb,
    output logic hsync,
    output logic vsync,

    //draw_sprite
    input logic [4:0] pacman_x,
    input logic [4:0] pacman_y
);

    logic [9:0] hcount, vcount;
    logic [2:0] rgb_tile, rgb_sprite, rgb_text;

    vga_counter vga_counter(
        .clk(pixel_clk),        //inputs
        .rst(rst),
        .hsync(hsync),          //outputs to VGA
        .vsync(vsync),
        .hcount(hcount),        //outputs to draw_XXXX
        .vcount(vcount)
    );

    draw_tile draw_tile(
        .hcount(hcount),        //inputs from VGA_counter
        .vcount(vcount),
        .output_rgb(rgb_tile)   //outputs to draw_sprite
        );

    draw_sprite draw_sprite(
        .hcount(hcount),        //inputs from VGA_counter
        .vcount(vcount),
        .pacman_x(pacman_x),    //inputs from pacman_controller
        .pacman_y(pacman_y),
    //  .ghost_x(ghost_x),      //inputs from ghost_controller
    //  .ghost_y(ghost_y),
        .input_rgb(rgb_tile),   //inputs from draw_tile
        .output_rgb(rgb_sprite) //outputs to draw_text
        );

    draw_text draw_text(
        .hcount(hcount),        //inputs from VGA_counter
        .vcount(vcount),
    //  .score(8'd0),           //inputs from central control system
        .input_rgb(rgb_sprite), //inputs from draw_sprite
        .output_rgb(rgb_text)   //outputs to VGA
        );
    
    assign rgb = rgb_text; //output to VGA


endmodule
