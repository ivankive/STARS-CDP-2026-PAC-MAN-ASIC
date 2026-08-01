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

    // Convert maze tile (tx,ty) + local pixel to VGA counts.
    // tile_x = h[7:3], tile_y = v[7:3]+24
    function automatic logic [9:0] hx(input int tx, input int px);
        hx = {7'(tx), 3'(px)};
    endfunction

    function automatic logic [9:0] vy(input int ty, input int py);
        // ty = v[7:3] + 24 => v[7:3] = ty - 24
        vy = {2'b00, 5'(ty - 24), 3'(py)};
    endfunction

    initial begin
        pass_count = 0;
        fail_count = 0;
        video_on   = 1'b1;
        pacman_x   = 5'd10;
        pacman_y   = 5'd26; // on-screen: needs ty>=24
        pacman_dir = 2'd3;  // right
        blinky_x   = 5'd12;
        blinky_y   = 5'd26;
        blinky_dir = 2'd3;
        pinky_x    = 5'd14;
        pinky_y    = 5'd26;
        pinky_dir  = 2'd1;
        lives      = 2'd3;
        pp_active  = 1'b0;
        input_rgb  = 3'b001;
        h_count    = 10'd0;
        v_count    = 10'd0;

        $dumpfile("waves/vga_draw_sprite.vcd");
        $dumpvars(0, vga_draw_sprite_tb);

        // Background pass-through away from sprites
        h_count = hx(5, 0);
        v_count = vy(26, 0);
        #1;
        check("background pass-through", output_rgb === 3'b001);

        // Pac-Man body yellow (right facing, solid mid pixels)
        h_count = hx(10, 2);
        v_count = vy(26, 2);
        #1;
        check("pacman yellow", output_rgb === 3'b110);

        // Blinky red when not frightened
        h_count = hx(12, 4);
        v_count = vy(26, 4);
        #1;
        check("blinky red body", output_rgb === 3'b100);

        // Frightened cyan
        pp_active = 1'b1;
        #1;
        check("blinky frightened cyan", output_rgb === 3'b011);
        pp_active = 1'b0;

        // Pinky magenta/pink body
        h_count = hx(14, 4);
        v_count = vy(26, 4);
        #1;
        check("pinky body", output_rgb === 3'b101);

        // Lives icons at bottom (v in (311,320), h<=7); use solid body pixel
        h_count = 10'd2;
        v_count = 10'd315;
        #1;
        check("life icon 1 yellow", output_rgb === 3'b110);

        lives = 2'd0;
        #1;
        check("no lives hides icon", output_rgb === 3'b001);

        video_on = 1'b0;
        lives    = 2'd3;
        h_count  = hx(10, 2);
        v_count  = vy(26, 2);
        #1;
        check("video_off uses background", output_rgb === 3'b001);

        $display("\nvga_draw_sprite_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        $finish;
    end

endmodule
