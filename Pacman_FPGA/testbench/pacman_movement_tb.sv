`timescale 1ns/1ps

module pacman_movement_tb;

    logic       clk;
    logic       reset;
    logic       enable;
    logic       game_starting;
    logic [3:0] pb;
    logic       pacman_hit;
    logic [4:0] rom_x;
    logic [4:0] rom_y;
    logic       rom_valid;
    logic       rom_can_move;
    logic [4:0] xpos;
    logic [4:0] ypos;
    logic [1:0] direction;

    int pass_count;
    int fail_count;

    localparam logic [1:0] UP    = 2'd0;
    localparam logic [1:0] LEFT  = 2'd1;
    localparam logic [1:0] DOWN  = 2'd2;
    localparam logic [1:0] RIGHT = 2'd3;

    logic       force_wall;
    logic [4:0] wall_x;
    logic [4:0] wall_y;

    // Always valid for the address under test unless gated in a test.
    assign rom_valid = 1'b1;

    always_comb begin
        if (force_wall && (rom_x == wall_x) && (rom_y == wall_y))
            rom_can_move = 1'b0;
        else
            rom_can_move = 1'b1;
    end

    pacman_movement dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .game_starting(game_starting),
        .pb(pb),
        .pacman_hit(pacman_hit),
        .rom_x(rom_x),
        .rom_y(rom_y),
        .rom_valid(rom_valid),
        .rom_can_move(rom_can_move),
        .xpos(xpos),
        .ypos(ypos),
        .direction(direction)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic check(input string name, input logic cond);
        if (cond) begin
            pass_count++;
            $display("PASS: %s", name);
        end else begin
            fail_count++;
            $display("FAIL: %s (pos=%0d,%0d dir=%0d)", name, xpos, ypos, direction);
        end
    endtask

    task automatic tick(input int n = 1);
        repeat (n) @(posedge clk);
    endtask

    // 8 IDLE counts + CHECK_TURN (+ optional CHECK_FORWARD)
    task automatic wait_move_cycle;
        tick(10);
    endtask

    initial begin
        pass_count     = 0;
        fail_count     = 0;
        reset          = 1'b1;
        enable         = 1'b0;
        game_starting  = 1'b0;
        pb             = 4'b0;
        pacman_hit     = 1'b0;
        force_wall     = 1'b0;
        wall_x         = 5'd0;
        wall_y         = 5'd0;

        $dumpfile("waves/pacman_movement.vcd");
        $dumpvars(0, pacman_movement_tb);

        tick(2);
        reset = 1'b0;
        tick(1);
        check("reset pose (11,19)", (xpos === 5'd11) && (ypos === 5'd19));
        check("reset facing RIGHT", direction === RIGHT);

        enable = 1'b1;
        wait_move_cycle();
        check("moved right to (12,19)", (xpos === 5'd12) && (ypos === 5'd19));

        pb = 4'b0001; // UP
        tick(1);
        pb = 4'b0;
        wait_move_cycle();
        check("turned/moved up", (xpos === 5'd12) && (ypos === 5'd18) && (direction === UP));

        force_wall = 1'b1;
        wall_x     = 5'd11;
        wall_y     = 5'd18;
        pb         = 4'b1000; // LEFT
        tick(1);
        pb = 4'b0;
        wait_move_cycle();
        check("blocked left continues up",
              (xpos === 5'd12) && (ypos === 5'd17) && (direction === UP));
        force_wall = 1'b0;

        // Tunnel wrap left at (0,13)
        force dut.xpos = 5'd0;
        force dut.ypos = 5'd13;
        force dut.dir  = LEFT;
        force dut.stored_dir = LEFT;
        force dut.test_dir = LEFT;
        force dut.state = 2'd0;
        force dut.count = 3'd0;
        tick(1);
        release dut.xpos;
        release dut.ypos;
        release dut.dir;
        release dut.stored_dir;
        release dut.test_dir;
        release dut.state;
        release dut.count;

        force_wall = 1'b1;
        wall_x     = 5'd31;
        wall_y     = 5'd13;
        wait_move_cycle();
        check("wrap left tunnel to x=23", (xpos === 5'd23) && (ypos === 5'd13));
        force_wall = 1'b0;

        force dut.xpos = 5'd23;
        force dut.ypos = 5'd13;
        force dut.dir  = RIGHT;
        force dut.stored_dir = RIGHT;
        force dut.test_dir = RIGHT;
        force dut.state = 2'd0;
        force dut.count = 3'd0;
        tick(1);
        release dut.xpos;
        release dut.ypos;
        release dut.dir;
        release dut.stored_dir;
        release dut.test_dir;
        release dut.state;
        release dut.count;

        force_wall = 1'b1;
        wall_x     = 5'd24;
        wall_y     = 5'd13;
        wait_move_cycle();
        check("wrap right tunnel to x=0", (xpos === 5'd0) && (ypos === 5'd13));
        force_wall = 1'b0;

        pacman_hit = 1'b1;
        tick(1);
        pacman_hit = 1'b0;
        check("hit restores spawn", (xpos === 5'd11) && (ypos === 5'd19) && (direction === RIGHT));

        // Move away, then game_starting restores spawn.
        enable = 1'b1;
        wait_move_cycle();
        game_starting = 1'b1;
        tick(1);
        game_starting = 1'b0;
        check("game_starting restores spawn",
              (xpos === 5'd11) && (ypos === 5'd19) && (direction === RIGHT));

        $display("\npacman_movement_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count != 0) $fatal(1);
        $finish;
    end

endmodule
