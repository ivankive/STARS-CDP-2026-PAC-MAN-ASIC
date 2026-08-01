`timescale 1ns/1ps

module vga_draw_tile_tb;

    logic [9:0] h_count_raw, v_count_raw;
    logic       video_on_raw;
    logic [9:0] h_count_d, v_count_d;
    logic       video_on_d;
    logic       vga_active;
    logic [4:0] x_vga, y_vga;
    logic [1:0] tile_data;
    logic [2:0] output_rgb;

    int pass_count;
    int fail_count;

    vga_draw_tile dut (
        .h_count_raw(h_count_raw),
        .v_count_raw(v_count_raw),
        .video_on_raw(video_on_raw),
        .h_count_d(h_count_d),
        .v_count_d(v_count_d),
        .video_on_d(video_on_d),
        .vga_active(vga_active),
        .x_vga(x_vga),
        .y_vga(y_vga),
        .tile_data(tile_data),
        .output_rgb(output_rgb)
    );

    task automatic check(input string name, input logic cond);
        if (cond) begin
            pass_count++;
            $display("PASS: %s", name);
        end else begin
            fail_count++;
            $display("FAIL: %s (rgb=%b xy=%0d,%0d act=%b)",
                     name, output_rgb, x_vga, y_vga, vga_active);
        end
    endtask

    initial begin
        pass_count   = 0;
        fail_count   = 0;
        h_count_raw  = 10'd0;
        v_count_raw  = 10'd0;
        video_on_raw = 1'b0;
        h_count_d    = 10'd0;
        v_count_d    = 10'd0;
        video_on_d   = 1'b0;
        tile_data    = 2'b00;

        $dumpfile("waves/vga_draw_tile.vcd");
        $dumpvars(0, vga_draw_tile_tb);

        #1;
        check("inactive off-map", vga_active === 1'b0 && output_rgb === 3'b000);

        // Tile (2,0) is at pixel x=16..23. y_raw maps as tile_y = v[7:3]+24,
        // so tile_y=0 needs v_count such that v[7:3]+24 == 0 -> impossible.
        // Use tile_y = 24 + 0 = wait: tile_y_raw = v[7:3] + 24, so for tile 0
        // we need wrap... For in-map, tile_y < 24 means v[7:3]+24 < 24 => v[7:3]==0
        // and 24 < 24 is false! So tile_y is always >= 24?
        //
        // Looking again: tile_y_raw = v_count_raw[7:3] + 5'd24;
        // in_map: tile_y_raw < 24. That means (v[7:3]+24) < 24 => never true for
        // unsigned add unless overflow. 5-bit: 0+24=24, 24<24 false.
        // 8+24 = 32 = 0 in 5-bit! So when v[7:3]==8, tile_y=0.
        // v[7:3]==8 means v in 64..71.
        //
        // And tile_x = h[7:3], need < 24 so h < 192.

        // Request tile (3,1): h=24..31 -> tile_x=3; v=72..79 -> v[7:3]=9 -> y=9+24=33=1 in 5-bit.
        video_on_raw = 1'b1;
        h_count_raw  = 10'd24; // tile_x = 3
        v_count_raw  = 10'd72; // v[7:3]=9, y=9+24=33 -> 1
        #1;
        check("vga_active in map", vga_active === 1'b1);
        check("x_vga=3", x_vga === 5'd3);
        check("y_vga=1", y_vga === 5'd1);

        // Delayed path paints wall blue.
        video_on_d = 1'b1;
        h_count_d  = 10'd24;
        v_count_d  = 10'd72;
        tile_data  = 2'b01;
        #1;
        check("wall is blue", output_rgb === 3'b001);

        // Pellet center pixels white.
        tile_data = 2'b10;
        h_count_d = 10'd27; // pixel_x=3 within tile starting at 24
        v_count_d = 10'd75; // pixel_y=3 within tile starting at 72
        #1;
        check("pellet center white", output_rgb === 3'b111);

        h_count_d = 10'd24;
        v_count_d = 10'd72;
        #1;
        check("pellet edge black", output_rgb === 3'b000);

        tile_data = 2'b11;
        h_count_d = 10'd27;
        v_count_d = 10'd75;
        #1;
        check("power pellet body white", output_rgb === 3'b111);

        video_on_d = 1'b0;
        #1;
        check("video off blacks out", output_rgb === 3'b000);

        $display("\nvga_draw_tile_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count != 0) $fatal(1);
        $finish;
    end

endmodule
