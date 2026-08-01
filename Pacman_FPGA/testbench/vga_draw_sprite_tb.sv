`timescale 1ns/1ps

module vga_draw_sprite_tb;

    logic [9:0] h_count, v_count;
    logic       video_on;
    logic [4:0] pacman_x, pacman_y;
    logic [1:0] pacman_dir;
    logic [4:0] blinky_x, blinky_y;
    logic [1:0] blinky_dir;
    logic [4:0] pinky_x, pinky_y;
    logic [1:0] pinky_dir;
    logic [1:0] lives;
    logic       pp_active;
    logic [2:0] input_rgb;
    logic [2:0] output_rgb;

    int pass_count;
    int fail_count;

    vga_draw_sprite dut (
        .h_count(h_count),
        .v_count(v_count),
        .video_on(video_on),
        .pacman_x(pacman_x),
        .pacman_y(pacman_y),
        .pacman_dir(pacman_dir),
        .blinky_x(blinky_x),
        .blinky_y(blinky_y),
        .blinky_dir(blinky_dir),
        .pinky_x(pinky_x),
        .pinky_y(pinky_y),
        .pinky_dir(pinky_dir),
        .lives(lives),
        .pp_active(pp_active),
        .input_rgb(input_rgb),
        .output_rgb(output_rgb)
    );

    task automatic check(input string name, input logic cond);
        if (cond) begin
            pass_count++;
            $display("PASS: %s", name);
        end else begin
            fail_count++;
            $display("FAIL: %s (rgb=%b)", name, output_rgb);
        end
    endtask

    // Map tile (tx,ty) to a pixel inside that tile.
    // tile_x = h[7:3]; tile_y = v[7:3] + 24 (5-bit).
    // For ty=19: need v[7:3]+24 == 19 => v[7:3] == 19-24 = -5 => 27 in 5-bit.
    // v[7:3]=27 => v in 216..223.
    task automatic set_pixel(input logic [4:0] tx, input logic [4:0] ty,
                             input logic [2:0] px, input logic [2:0] py);
        logic [4:0] v_hi;
        v_hi = ty - 5'd24; // 5-bit wrap
        h_count = {2'b00, tx, px};
        v_count = {2'b00, v_hi, py};
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        video_on   = 1'b1;
        pacman_x   = 5'd5;
        pacman_y   = 5'd19;
        pacman_dir = 2'd3; // RIGHT
        blinky_x   = 5'd8;
        blinky_y   = 5'd19;
        blinky_dir = 2'd1;
        pinky_x    = 5'd9;
        pinky_y    = 5'd19;
        pinky_dir  = 2'd1;
        lives      = 2'd0;
        pp_active  = 1'b0;
        input_rgb  = 3'b001;
        h_count    = 10'd0;
        v_count    = 10'd0;

        $dumpfile("waves/vga_draw_sprite.vcd");
        $dumpvars(0, vga_draw_sprite_tb);

        // Background tile (not on a sprite) passes through.
        set_pixel(5'd1, 5'd19, 3'd0, 3'd0);
        #1;
        check("passthrough tile rgb", output_rgb === 3'b001);

        // Pac-Man facing right, body pixel.
        set_pixel(5'd5, 5'd19, 3'd2, 3'd2);
        #1;
        check("pacman yellow", output_rgb === 3'b110);

        // Blinky normal = red (100)
        set_pixel(5'd8, 5'd19, 3'd2, 3'd2);
        #1;
        check("blinky red", output_rgb === 3'b100);

        // Pinky normal = magenta-ish (101)
        set_pixel(5'd9, 5'd19, 3'd2, 3'd2);
        #1;
        check("pinky pink", output_rgb === 3'b101);

        pp_active = 1'b1;
        set_pixel(5'd8, 5'd19, 3'd2, 3'd2);
        #1;
        check("blinky frightened cyan", output_rgb === 3'b011);

        set_pixel(5'd9, 5'd19, 3'd2, 3'd2);
        #1;
        check("pinky frightened cyan", output_rgb === 3'b011);

        // Lives icon region: h<=7, v in (255,264) => 312-56=256, 320-56=264
        // Strict: v_count < 264 && v_count > 255
        pp_active = 1'b0;
        lives     = 2'd1;
        input_rgb = 3'b000;
        h_count   = 10'd3;
        v_count   = 10'd260;
        #1;
        check("life icon yellow", output_rgb === 3'b110);

        video_on = 1'b0;
        set_pixel(5'd5, 5'd19, 3'd2, 3'd2);
        #1;
        // With video off, pacman branch skipped; falls to input_rgb unless lives overwrite.
        lives = 2'd0;
        #1;
        check("video off uses input", output_rgb === 3'b000);

        $display("\nvga_draw_sprite_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count != 0) $fatal(1);
        $finish;
    end

endmodule
