`timescale 1ns/1ps

module ghost_movement_tb;

    logic       ghost_can_move;
    logic [4:0] ghost_x;
    logic [4:0] ghost_y;
    logic [1:0] ghost_dir;
    logic [4:0] target_x;
    logic [4:0] target_y;
    logic       can_up;
    logic       can_down;
    logic       can_left;
    logic       can_right;
    logic       do_reverse;
    logic [4:0] next_x;
    logic [4:0] next_y;
    logic [1:0] next_dir;

    int pass_count;
    int fail_count;

    localparam logic [1:0] DIR_UP    = 2'd0;
    localparam logic [1:0] DIR_LEFT  = 2'd1;
    localparam logic [1:0] DIR_DOWN  = 2'd2;
    localparam logic [1:0] DIR_RIGHT = 2'd3;

    ghost_movement dut (
        .ghost_can_move(ghost_can_move),
        .ghost_x(ghost_x),
        .ghost_y(ghost_y),
        .ghost_dir(ghost_dir),
        .target_x(target_x),
        .target_y(target_y),
        .can_up(can_up),
        .can_down(can_down),
        .can_left(can_left),
        .can_right(can_right),
        .do_reverse(do_reverse),
        .next_x(next_x),
        .next_y(next_y),
        .next_dir(next_dir)
    );

    task automatic check(input string name, input logic cond);
        if (cond) begin
            pass_count++;
            $display("PASS: %s", name);
        end else begin
            fail_count++;
            $display("FAIL: %s (dir=%0d x=%0d y=%0d)", name, next_dir, next_x, next_y);
        end
    endtask

    task automatic set_open_all;
        can_up    = 1'b1;
        can_down  = 1'b1;
        can_left  = 1'b1;
        can_right = 1'b1;
    endtask

    initial begin
        pass_count     = 0;
        fail_count     = 0;
        ghost_can_move = 1'b0;
        ghost_x        = 5'd10;
        ghost_y        = 5'd10;
        ghost_dir      = DIR_RIGHT;
        target_x       = 5'd15;
        target_y       = 5'd10;
        do_reverse     = 1'b0;
        set_open_all();

        $dumpfile("waves/ghost_movement.vcd");
        $dumpvars(0, ghost_movement_tb);

        #1;
        check("cannot move holds pose",
              (next_dir === DIR_RIGHT) && (next_x === 5'd10) && (next_y === 5'd10));

        // Prefer right toward target
        ghost_can_move = 1'b1;
        #1;
        check("move right toward target",
              (next_dir === DIR_RIGHT) && (next_x === 5'd11) && (next_y === 5'd10));

        // Prefer left
        target_x  = 5'd5;
        ghost_dir = DIR_LEFT;
        #1;
        check("move left toward target",
              (next_dir === DIR_LEFT) && (next_x === 5'd9) && (next_y === 5'd10));

        // Prefer down (x equal)
        target_x  = 5'd10;
        target_y  = 5'd15;
        ghost_dir = DIR_DOWN;
        #1;
        check("move down toward target",
              (next_dir === DIR_DOWN) && (next_x === 5'd10) && (next_y === 5'd11));

        // Prefer up
        target_y  = 5'd5;
        ghost_dir = DIR_UP;
        #1;
        check("move up toward target",
              (next_dir === DIR_UP) && (next_x === 5'd10) && (next_y === 5'd9));

        // do_reverse takes reverse when legal
        ghost_dir  = DIR_RIGHT;
        target_x   = 5'd20;
        target_y   = 5'd10;
        do_reverse = 1'b1;
        #1;
        check("do_reverse chooses left",
              (next_dir === DIR_LEFT) && (next_x === 5'd9) && (next_y === 5'd10));
        do_reverse = 1'b0;

        // Continue straight when target axes blocked / reverse-only
        ghost_x   = 5'd10;
        ghost_y   = 5'd10;
        ghost_dir = DIR_RIGHT;
        target_x  = 5'd10;
        target_y  = 5'd10;
        can_up    = 1'b0;
        can_down  = 1'b0;
        can_left  = 1'b0;
        can_right = 1'b1;
        #1;
        check("continue straight",
              (next_dir === DIR_RIGHT) && (next_x === 5'd11) && (next_y === 5'd10));

        // Alternate non-reverse when forward blocked
        can_right = 1'b0;
        can_up    = 1'b1;
        can_left  = 1'b0;
        can_down  = 1'b0;
        ghost_dir = DIR_RIGHT;
        #1;
        check("pick up when forward blocked",
              (next_dir === DIR_UP) && (next_x === 5'd10) && (next_y === 5'd9));

        // Dead-end forces reverse
        can_up    = 1'b0;
        can_down  = 1'b0;
        can_left  = 1'b1;
        can_right = 1'b0;
        ghost_dir = DIR_RIGHT;
        #1;
        check("dead-end reverse",
              (next_dir === DIR_LEFT) && (next_x === 5'd9) && (next_y === 5'd10));

        // Illegal chosen dir does not update position
        set_open_all();
        can_right = 1'b0;
        can_left  = 1'b0;
        can_up    = 1'b0;
        can_down  = 1'b0;
        ghost_dir = DIR_RIGHT;
        target_x  = 5'd20;
        #1;
        check("no legal move holds position",
              (next_x === 5'd10) && (next_y === 5'd10));

        $display("\nghost_movement_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        $finish;
    end

endmodule
