`timescale 1ns/1ps

module initial_maze_rom_tb;

    logic [4:0] x_a, y_a, x_b, y_b;
    logic [1:0] tile_a, tile_b;
    logic       can_move_a, can_move_b;

    int pass_count;
    int fail_count;

    localparam logic [1:0] PATH_TILE  = 2'b00;
    localparam logic [1:0] WALL_TILE  = 2'b01;
    localparam logic [1:0] PELLET     = 2'b10;
    localparam logic [1:0] POWER_TILE = 2'b11;

    initial_maze_rom dut (
        .x_a(x_a),
        .y_a(y_a),
        .tile_a(tile_a),
        .can_move_a(can_move_a),
        .x_b(x_b),
        .y_b(y_b),
        .tile_b(tile_b),
        .can_move_b(can_move_b)
    );

    task automatic check(input string name, input logic cond);
        if (cond) begin
            pass_count++;
            $display("PASS: %s", name);
        end else begin
            fail_count++;
            $display("FAIL: %s (tile_a=%b can_a=%b tile_b=%b can_b=%b)",
                     name, tile_a, can_move_a, tile_b, can_move_b);
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        x_a = '0; y_a = '0;
        x_b = '0; y_b = '0;

        $dumpfile("waves/initial_maze_rom.vcd");
        $dumpvars(0, initial_maze_rom_tb);

        #1;

        // Outer wall row / corners
        x_a = 5'd0;  y_a = 5'd0;
        x_b = 5'd27; y_b = 5'd30;
        #1;
        check("corner (0,0) wall", tile_a === WALL_TILE && can_move_a === 1'b0);
        check("corner (27,30) wall", tile_b === WALL_TILE && can_move_b === 1'b0);

        // Pellet corridor on row 1
        x_a = 5'd1; y_a = 5'd1;
        #1;
        check("pellet at (1,1)", tile_a === PELLET && can_move_a === 1'b1);

        // Power pellets at (1,4) and (26,4)
        x_a = 5'd1;  y_a = 5'd4;
        x_b = 5'd26; y_b = 5'd4;
        #1;
        check("power pellet (1,4)", tile_a === POWER_TILE && can_move_a === 1'b1);
        check("power pellet (26,4)", tile_b === POWER_TILE && can_move_b === 1'b1);

        // Empty path in ghost house (row 14 tunnel / house empties)
        x_a = 5'd13; y_a = 5'd14;
        #1;
        check("house empty path tile", tile_a === PATH_TILE);

        // Pac-Man port blocks ghost-house door tiles (13,12) and (14,12)
        x_a = 5'd13; y_a = 5'd12;
        #1;
        check("pac door (13,12) blocked", can_move_a === 1'b0);
        x_a = 5'd14; y_a = 5'd12;
        #1;
        check("pac door (14,12) blocked",
              (tile_a !== WALL_TILE) && (can_move_a === 1'b0));

        // Ghost port blocks side house walls x=12 and x=15 for y in [12,16]
        x_a = 5'd6;  y_a = 5'd14;  // open tunnel for contrast on port A
        x_b = 5'd12; y_b = 5'd14;
        #1;
        check("ghost side wall (12,14) blocked on B", can_move_b === 1'b0);
        check("open path still free on A", can_move_a === 1'b1);

        x_b = 5'd15; y_b = 5'd16;
        #1;
        check("ghost side wall (15,16) blocked on B", can_move_b === 1'b0);

        // Dual-port independence
        x_a = 5'd1;  y_a = 5'd1;
        x_b = 5'd0;  y_b = 5'd0;
        #1;
        check("port A pellet while B wall",
              tile_a === PELLET && tile_b === WALL_TILE);

        // Out of bounds -> wall
        x_a = 5'd28; y_a = 5'd0;
        x_b = 5'd0;  y_b = 5'd31;
        #1;
        check("oob x wall", tile_a === WALL_TILE && can_move_a === 1'b0);
        check("oob y wall", tile_b === WALL_TILE && can_move_b === 1'b0);

        $display("\ninitial_maze_rom_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        $finish;
    end

endmodule
