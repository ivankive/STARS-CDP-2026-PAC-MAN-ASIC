`timescale 1ns/1ps

module maze_wall_pellet_rom_tb;

    logic [4:0] x, y;
    logic [1:0] tile;
    logic       collectible;
    logic [7:0] pellet_index;
    logic       can_move_pac;
    logic       can_move_ghost;

    int pass_count;
    int fail_count;

    localparam logic [1:0] PATH_TILE  = 2'b00;
    localparam logic [1:0] WALL_TILE  = 2'b01;
    localparam logic [1:0] PELLET     = 2'b10;
    localparam logic [1:0] POWER_TILE = 2'b11;

    maze_wall_pellet_rom dut (
        .x(x),
        .y(y),
        .tile(tile),
        .collectible(collectible),
        .pellet_index(pellet_index),
        .can_move_pac(can_move_pac),
        .can_move_ghost(can_move_ghost)
    );

    task automatic check(input string name, input logic cond);
        if (cond) begin
            pass_count++;
            $display("PASS: %s", name);
        end else begin
            fail_count++;
            $display("FAIL: %s (x=%0d y=%0d tile=%b idx=%0d)", name, x, y, tile, pellet_index);
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        x = 5'd0;
        y = 5'd0;

        $dumpfile("waves/maze_wall_pellet_rom.vcd");
        $dumpvars(0, maze_wall_pellet_rom_tb);

        #1;
        check("corner wall", tile === WALL_TILE && !collectible);

        // Bottom row has 22 pellets; left/right must not share indices.
        y = 5'd22;
        x = 5'd1;
        #1;
        check("bottom-left pellet", tile === PELLET && collectible);
        check("bottom-left index base", pellet_index === 8'd164);

        x = 5'd17;
        #1;
        check("bottom x=17 distinct from x=1", pellet_index === 8'd180);

        x = 5'd22;
        #1;
        check("bottom-right last index", pellet_index === 8'd185);

        // Power pellets on row 19 corners.
        y = 5'd19;
        x = 5'd1;
        #1;
        check("power pellet bottom-left", tile === POWER_TILE && collectible);

        x = 5'd22;
        #1;
        check("power pellet bottom-right", tile === POWER_TILE && collectible);
        check("power right index unique", pellet_index === 8'd155);

        // OOB
        x = 5'd24;
        y = 5'd0;
        #1;
        check("oob is wall", tile === WALL_TILE && pellet_index === 8'd0);

        // Ghost house door tiles blocked for pac.
        x = 5'd11;
        y = 5'd12;
        #1;
        check("ghost door blocks pac", can_move_pac === 1'b0);

        $display("\nmaze_wall_pellet_rom_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count != 0) $fatal(1);
        $finish;
    end

endmodule
