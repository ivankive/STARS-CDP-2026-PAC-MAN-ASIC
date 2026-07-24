`timescale 1ns/1ps

module maze_bram_tb;

    logic       clk;
    logic       reset;
    logic       map_rst;
    logic       map_loaded;

    logic [4:0] x_vga;
    logic [4:0] y_vga;
    logic [1:0] rdata_vga;

    logic [4:0] x_central;
    logic [4:0] y_central;
    logic       write_en;
    logic [1:0] rdata_central;

    logic [4:0] rom_x;
    logic [4:0] rom_y;
    logic [1:0] rom_data;

    int pass_count;
    int fail_count;
    int timeout;

    localparam logic [1:0] PATH_TILE  = 2'b00;
    localparam logic [1:0] WALL_TILE  = 2'b01;
    localparam logic [1:0] PELLET     = 2'b10;
    localparam logic [1:0] POWER_TILE = 2'b11;

    // Deterministic ROM stub for reload
    always_comb begin
        if ((rom_x == 5'd5) && (rom_y == 5'd5))
            rom_data = PELLET;
        else if ((rom_x == 5'd6) && (rom_y == 5'd6))
            rom_data = POWER_TILE;
        else if ((rom_x == 5'd0) || (rom_y == 5'd0))
            rom_data = WALL_TILE;
        else
            rom_data = PATH_TILE;
    end

    maze_bram dut (
        .clk(clk),
        .reset(reset),
        .map_rst(map_rst),
        .map_loaded(map_loaded),
        .x_vga(x_vga),
        .y_vga(y_vga),
        .rdata_vga(rdata_vga),
        .x_central(x_central),
        .y_central(y_central),
        .write_en(write_en),
        .rdata_central(rdata_central),
        .rom_x(rom_x),
        .rom_y(rom_y),
        .rom_data(rom_data)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

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
        repeat (n) @(posedge clk);
    endtask

    task automatic wait_loaded;
        timeout = 0;
        while (!map_loaded && timeout < 2000) begin
            @(posedge clk);
            timeout++;
        end
        check("map_loaded within timeout", map_loaded === 1'b1);
    endtask

    task automatic settle_central_read;
        // Address must be stable for two clocks after map_loaded
        tick(2);
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        reset      = 1'b1;
        map_rst    = 1'b0;
        write_en   = 1'b0;
        x_vga      = 5'd0;
        y_vga      = 5'd0;
        x_central  = 5'd0;
        y_central  = 5'd0;

        $dumpfile("waves/maze_bram.vcd");
        $dumpvars(0, maze_bram_tb);

        tick(2);
        reset = 1'b0;
        check("not loaded after reset", map_loaded === 1'b0);

        wait_loaded();

        // VGA in-bounds pellet tile
        x_vga = 5'd5;
        y_vga = 5'd5;
        tick(2);
        check("VGA reads pellet at (5,5)", rdata_vga === PELLET);

        // VGA wall on border
        x_vga = 5'd0;
        y_vga = 5'd3;
        tick(2);
        check("VGA reads wall at (0,3)", rdata_vga === WALL_TILE);

        // VGA path
        x_vga = 5'd4;
        y_vga = 5'd4;
        tick(2);
        check("VGA reads path at (4,4)", rdata_vga === PATH_TILE);

        // VGA OOB -> wall (valid flag low)
        x_vga = 5'd28;
        y_vga = 5'd0;
        tick(2);
        check("VGA OOB returns wall", rdata_vga === WALL_TILE);

        // Central read pellet, then clear
        x_central = 5'd5;
        y_central = 5'd5;
        settle_central_read();
        check("central pellet before clear", rdata_central === PELLET);

        write_en = 1'b1;
        tick(1);
        write_en = 1'b0;
        settle_central_read();
        check("central pellet cleared to path", rdata_central === PATH_TILE);

        // Central power tile
        x_central = 5'd6;
        y_central = 5'd6;
        settle_central_read();
        check("central power tile", rdata_central === POWER_TILE);

        write_en = 1'b1;
        tick(1);
        write_en = 1'b0;
        settle_central_read();
        check("central power cleared to path", rdata_central === PATH_TILE);

        // Central OOB
        x_central = 5'd31;
        y_central = 5'd0;
        tick(2);
        check("central OOB returns wall", rdata_central === WALL_TILE);

        // map_rst reloads
        map_rst = 1'b1;
        tick(1);
        map_rst = 1'b0;
        check("map_rst clears map_loaded", map_loaded === 1'b0);
        wait_loaded();

        x_central = 5'd5;
        y_central = 5'd5;
        settle_central_read();
        check("pellet restored after reload", rdata_central === PELLET);

        $display("\nmaze_bram_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        $finish;
    end

endmodule
