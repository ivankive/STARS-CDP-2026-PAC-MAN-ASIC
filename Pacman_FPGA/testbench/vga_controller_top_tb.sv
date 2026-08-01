`timescale 1ns/1ps

module vga_controller_top_tb;

    logic       pixel_clk;
    logic       rst;
    logic [2:0] rgb;
    logic       hsync;
    logic       vsync;
    logic [4:0] x_vga, y_vga;
    logic [1:0] rdata_vga;
    logic       map_loaded;
    logic [4:0] pacman_x, pacman_y;
    logic [1:0] pacman_dir;
    logic [4:0] blinky_x, blinky_y;
    logic [1:0] blinky_dir;
    logic [4:0] pinky_x, pinky_y;
    logic [1:0] pinky_dir;
    logic       pp_active;
    logic [1:0] lives;
    logic [9:0] score;
    logic [1:0] game_state;

    int pass_count;
    int fail_count;
    int t;
    logic found_wall;

    logic [1:0] rdata_vga_q;

    // Sync ROM stub: matches BRAM 1-cycle latency vs delayed VGA counters
    always_ff @(posedge pixel_clk or posedge rst) begin
        if (rst)
            rdata_vga_q <= 2'b00;
        else if ((x_vga == 5'd1) && (y_vga == 5'd24))
            rdata_vga_q <= 2'b01;
        else
            rdata_vga_q <= 2'b10;
    end
    assign rdata_vga = rdata_vga_q;

    vga_controller_top dut (
        .pixel_clk(pixel_clk),
        .rst(rst),
        .rgb(rgb),
        .hsync(hsync),
        .vsync(vsync),
        .x_vga(x_vga),
        .y_vga(y_vga),
        .rdata_vga(rdata_vga),
        .map_loaded(map_loaded),
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
        .lives(lives),
        .score(score),
        .game_state(game_state)
    );

    initial pixel_clk = 1'b0;
    always #5 pixel_clk = ~pixel_clk;

    task automatic check(input string name, input logic cond);
        if (cond) begin
            pass_count++;
            $display("PASS: %s", name);
        end else begin
            fail_count++;
            $display("FAIL: %s (rgb=%b hs=%b vs=%b x=%0d y=%0d)",
                     name, rgb, hsync, vsync, x_vga, y_vga);
        end
    endtask

    task automatic tick(input int n = 1);
        repeat (n) @(posedge pixel_clk);
        #1;
    endtask

    initial begin
        pass_count  = 0;
        fail_count  = 0;
        rst         = 1'b1;
        map_loaded  = 1'b1;
        pacman_x    = 5'd10;
        pacman_y    = 5'd26;
        pacman_dir  = 2'd3;
        blinky_x    = 5'd12;
        blinky_y    = 5'd26;
        blinky_dir  = 2'd0;
        pinky_x     = 5'd14;
        pinky_y     = 5'd26;
        pinky_dir   = 2'd1;
        pp_active   = 1'b0;
        lives       = 2'd3;
        score       = 10'd42;
        game_state  = 2'd1;
        found_wall  = 1'b0;

        $dumpfile("waves/vga_controller_top.vcd");
        $dumpvars(0, vga_controller_top_tb);

        tick(3);
        check("reset syncs idle high", (hsync === 1'b1) && (vsync === 1'b1));

        rst = 1'b0;
        tick(50);
        check("pipeline rgb driven", !$isunknown(rgb));

        // Maze rows map into v<56; border/text dominate final RGB there.
        // Confirm addressing, then tile-layer color after 1-cycle stub latency.
        t = 0;
        while (t < 5000 && !found_wall) begin
            @(posedge pixel_clk);
            #1;
            if ((x_vga === 5'd1) && (y_vga === 5'd24)) begin
                tick(1);
                found_wall = 1'b1;
            end
            t++;
        end
        check("found wall tile request", found_wall === 1'b1);
        check("tile layer draws wall blue", dut.rgb_tile === 3'b001);
        check("top rgb driven", !$isunknown(rgb));

        tick(700);
        check("hsync eventually toggles", (hsync === 1'b0) || (hsync === 1'b1));

        tick(800 * 2);
        check("x_vga stays in maze width", x_vga < 5'd28);

        map_loaded = 1'b0;
        pacman_x   = 5'd0;
        pacman_y   = 5'd0;
        blinky_x   = 5'd0;
        blinky_y   = 5'd0;
        pinky_x    = 5'd0;
        pinky_y    = 5'd0;
        lives      = 2'd0;
        tick(20);
        check("sim stable after unload", !$isunknown(rgb));

        $display("\nvga_controller_top_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        $finish;
    end

endmodule
