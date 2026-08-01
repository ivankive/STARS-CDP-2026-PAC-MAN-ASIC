`timescale 1ns/1ps

module vga_draw_tile_tb;

    logic       map_loaded;
    logic [9:0] h_count_raw, v_count_raw;
    logic       video_on_raw;
    logic [9:0] h_count_d, v_count_d;
    logic       video_on_d;
    logic [4:0] x_vga, y_vga;
    logic [1:0] tile_data;
    logic [2:0] output_rgb;

    int pass_count;
    int fail_count;

    vga_draw_tile dut (
        .map_loaded(map_loaded),
        .h_count_raw(h_count_raw),
        .v_count_raw(v_count_raw),
        .video_on_raw(video_on_raw),
        .h_count_d(h_count_d),
        .v_count_d(v_count_d),
        .video_on_d(video_on_d),
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
            $display("FAIL: %s (rgb=%b x=%0d y=%0d)", name, output_rgb, x_vga, y_vga);
        end
    endtask

    // Screen pixel (hx, vy) maps to tile (hx[7:3], vy[7:3]+24)
    task automatic set_pixel(input int hx, input int vy, input logic [1:0] tile);
        h_count_raw = hx[9:0];
        v_count_raw = vy[9:0];
        h_count_d   = hx[9:0];
        v_count_d   = vy[9:0];
        video_on_raw = 1'b1;
        video_on_d   = 1'b1;
        tile_data    = tile;
        map_loaded   = 1'b1;
    endtask

    initial begin
        pass_count   = 0;
        fail_count   = 0;
        map_loaded   = 1'b0;
        h_count_raw  = '0;
        v_count_raw  = '0;
        video_on_raw = 1'b0;
        h_count_d    = '0;
        v_count_d    = '0;
        video_on_d   = 1'b0;
        tile_data    = 2'b00;

        $dumpfile("waves/vga_draw_tile.vcd");
        $dumpvars(0, vga_draw_tile_tb);

        #1;
        check("unloaded map black", output_rgb === 3'b000);

        // Tile (5,25): need v_count such that v[7:3]+24 = 25 => v[7:3]=1 => v in [8,15]
        // h in [40,47] => tile_x = 5
        set_pixel(40, 8, 2'b01);
        #1;
        check("request tile coords", (x_vga === 5'd5) && (y_vga === 5'd25));
        check("wall tile blue", output_rgb === 3'b001);

        set_pixel(40, 8, 2'b00);
        #1;
        check("empty tile black", output_rgb === 3'b000);

        // Pellet lit only at local pixels (3,3)/(3,4)/(4,3)/(4,4)
        set_pixel(40 + 3, 8 + 3, 2'b10);
        #1;
        check("pellet center white", output_rgb === 3'b111);

        set_pixel(40 + 0, 8 + 0, 2'b10);
        #1;
        check("pellet corner black", output_rgb === 3'b000);

        // Power pellet interior white (e.g. pixel 2,2), corners cut out
        set_pixel(40 + 2, 8 + 2, 2'b11);
        #1;
        check("power pellet body white", output_rgb === 3'b111);

        set_pixel(40 + 1, 8 + 1, 2'b11);
        #1;
        check("power pellet cut corner black", output_rgb === 3'b000);

        video_on_d = 1'b0;
        set_pixel(40, 8, 2'b01);
        video_on_d = 1'b0;
        #1;
        check("video_off forces black", output_rgb === 3'b000);

        // Outside map horizontally (tile_x >= 28): h >= 224
        video_on_raw = 1'b1;
        video_on_d   = 1'b1;
        h_count_raw  = 10'd224;
        v_count_raw  = 10'd8;
        h_count_d    = 10'd224;
        v_count_d    = 10'd8;
        map_loaded   = 1'b1;
        tile_data    = 2'b01;
        #1;
        check("oob request defaults x/y", (x_vga === 5'd0) && (y_vga === 5'd0));
        check("oob draw black", output_rgb === 3'b000);

        $display("\nvga_draw_tile_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        $finish;
    end

endmodule
