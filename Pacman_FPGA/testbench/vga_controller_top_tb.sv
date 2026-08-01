`timescale 1ns/1ps

module vga_controller_top_tb;

    logic       pixel_clk;
    logic       rst;
    logic [2:0] rgb;
    logic       hsync;
    logic       vsync;
    logic       vga_active;
    logic [4:0] x_vga, y_vga;
    logic [1:0] rdata_vga;

    logic [4:0] pacman_x, pacman_y;
    logic [1:0] pacman_dir;
    logic [4:0] blinky_x, blinky_y;
    logic [1:0] blinky_dir;
    logic [4:0] pinky_x, pinky_y;
    logic [1:0] pinky_dir;
    logic       pp_active;
    logic [1:0] lives;

    int pass_count;
    int fail_count;
    int seen_hsync_low;
    int seen_active;

    // Stub maze: always wall so tile path paints blue when active/delayed.
    assign rdata_vga = 2'b01;

    vga_controller_top dut (
        .pixel_clk(pixel_clk),
        .rst(rst),
        .rgb(rgb),
        .hsync(hsync),
        .vsync(vsync),
        .vga_active(vga_active),
        .x_vga(x_vga),
        .y_vga(y_vga),
        .rdata_vga(rdata_vga),
        .pacman_x(pacman_x),
        .pacman_y(pacman_y),
        .pacman_dir(pacman_dir),
        .blinky_x(blinky_x),
        .blinky_y(blinky_y),
        .blinky_dir(blinky_dir),
        .pinky_x(pinky_x),
        .pinky_y(pinky_y),
        .pinky_dir(pinky_dir),
        .pp_active(pp_active),
        .lives(lives)
    );

    initial pixel_clk = 1'b0;
    always #5 pixel_clk = ~pixel_clk;

    task automatic check(input string name, input logic cond);
        if (cond) begin
            pass_count++;
            $display("PASS: %s", name);
        end else begin
            fail_count++;
            $display("FAIL: %s", name);
        end
    endtask

    task automatic tick(input int n = 1);
        repeat (n) @(posedge pixel_clk);
    endtask

    initial begin
        pass_count  = 0;
        fail_count  = 0;
        seen_hsync_low = 0;
        seen_active = 0;
        rst         = 1'b1;
        pacman_x    = 5'd10;
        pacman_y    = 5'd10;
        pacman_dir  = 2'd3;
        blinky_x    = 5'd11;
        blinky_y    = 5'd13;
        blinky_dir  = 2'd1;
        pinky_x     = 5'd12;
        pinky_y     = 5'd13;
        pinky_dir   = 2'd1;
        pp_active   = 1'b0;
        lives       = 2'd0;

        $dumpfile("waves/vga_controller_top.vcd");
        $dumpvars(0, vga_controller_top_tb);

        tick(2);
        check("reset hsync high", hsync === 1'b1);
        check("reset vsync high", vsync === 1'b1);
        rst = 1'b0;

        // Run enough pixels to cover one hsync pulse and map rows around v=64+.
        for (int i = 0; i < 900; i++) begin
            tick(1);
            if (hsync === 1'b0)
                seen_hsync_low = 1;
            if (vga_active === 1'b1)
                seen_active = 1;
        end
        check("saw hsync low", seen_hsync_low == 1);

        // Force into a known in-map raw coordinate and check address + delayed color.
        // h=24 -> tile_x=3; v=72 -> tile_y=1 (5-bit wrap), as in tile TB.
        force dut.hcount_raw = 10'd24;
        force dut.vcount_raw = 10'd72;
        force dut.video_on_raw = 1'b1;
        tick(1);
        #1;
        check("vga_active asserts", vga_active === 1'b1);
        check("x_vga address", x_vga === 5'd3);
        check("y_vga address", y_vga === 5'd1);

        // After one more cycle the delayed path should paint wall (swizzled).
        // tile blue=001 -> rgb assign swaps: rgb[0]=sprite[2], etc.
        // wall output_rgb from tile is 001, no sprite -> sprite=001
        // rgb[0]=0, rgb[1]=0, rgb[2]=1 => 3'b100 after bit reverse assign.
        force dut.hcount_d = 10'd24;
        force dut.vcount_d = 10'd72;
        force dut.video_on_d = 1'b1;
        #1;
        check("wall rgb swizzle", rgb === 3'b100);

        release dut.hcount_raw;
        release dut.vcount_raw;
        release dut.video_on_raw;
        release dut.hcount_d;
        release dut.vcount_d;
        release dut.video_on_d;

        $display("\nvga_controller_top_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count != 0) $fatal(1);
        $finish;
    end

endmodule
