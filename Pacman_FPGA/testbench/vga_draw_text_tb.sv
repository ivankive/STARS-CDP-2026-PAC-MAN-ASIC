`timescale 1ns/1ps

module vga_draw_text_tb;

    logic [9:0] h_count, v_count;
    logic       video_on;
    logic [9:0] score;
    logic [1:0] game_state;
    logic [2:0] input_rgb;
    logic [2:0] output_rgb;

    int pass_count;
    int fail_count;

    localparam logic [1:0] GAME_STARTING = 2'd0;
    localparam logic [1:0] GAME_PLAYING  = 2'd1;
    localparam logic [1:0] GAME_OVER     = 2'd2;
    localparam logic [1:0] GAME_WIN      = 2'd3;

    vga_draw_text dut (
        .h_count(h_count),
        .v_count(v_count),
        .video_on(video_on),
        .score(score),
        .game_state(game_state),
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

    initial begin
        pass_count = 0;
        fail_count = 0;
        video_on   = 1'b1;
        score      = 10'd0;
        game_state = GAME_PLAYING;
        input_rgb  = 3'b001;
        h_count    = 10'd100;
        v_count    = 10'd100;

        $dumpfile("waves/vga_draw_text.vcd");
        $dumpvars(0, vga_draw_text_tb);

        #1;
        check("playing mid-screen pass-through", output_rgb === 3'b001);

        // SCORE 'S' glyph region: h in (0,7], v < 8 — solid white on rows 0/1
        h_count = 10'd4;
        v_count = 10'd0;
        #1;
        check("SCORE S glyph white", output_rgb === 3'b111);

        // Digit ones place for score=7 -> ones=7: h in [64,72), v<8
        // Digit 7 row0 = 8'b00111100, pixel_x=0 -> bit7=0 -> black
        score   = 10'd7;
        h_count = 10'd64; // pixel_x = 0
        v_count = 10'd0;
        #1;
        check("digit 7 leading black", output_rgb === 3'b000);

        h_count = 10'd66; // pixel_x = 2, bit5 of 00111100 = 1
        #1;
        check("digit 7 body white", output_rgb === 3'b111);

        // Hundreds for score=123: hundreds=1
        score   = 10'd123;
        h_count = 10'd51; // hundreds tile start 48, pixel_x=3
        v_count = 10'd6;  // digit 1 row6 = 01111110, pix3 = 1
        #1;
        check("hundreds digit drawn", output_rgb === 3'b111);

        // Title screen PAC-MAN banner: tile_y 18-21, lit tiles white
        game_state = GAME_STARTING;
        // tile_y = v[7:3] = 18 => v in [144,151]; tile_x=1 => h in [8,15]
        h_count = 10'd8;
        v_count = 10'd144;
        #1;
        check("starting title white block", output_rgb === 3'b111);

        // Game over text region
        game_state = GAME_OVER;
        h_count    = 10'd24; // tile_x = 3
        v_count    = 10'd144;
        #1;
        check("game over text white", output_rgb === 3'b111);

        // Win text
        game_state = GAME_WIN;
        h_count    = 10'd32; // tile_x = 4
        v_count    = 10'd144;
        #1;
        check("win text white", output_rgb === 3'b111);

        video_on = 1'b0;
        #1;
        check("video_off pass-through", output_rgb === 3'b001);

        $display("\nvga_draw_text_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        $finish;
    end

endmodule
