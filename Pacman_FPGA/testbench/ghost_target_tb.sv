`timescale 1ns/1ps

module ghost_target_tb;

    logic [1:0] ghost_state;
    logic       ghost_id;
    logic [4:0] ghost_x;
    logic [4:0] ghost_y;
    logic [4:0] pacman_x;
    logic [4:0] pacman_y;
    logic [1:0] pacman_dir;
    logic [4:0] target_x;
    logic [4:0] target_y;

    int pass_count;
    int fail_count;

    localparam logic [1:0] G_CAGED      = 2'd0;
    localparam logic [1:0] G_SCATTER    = 2'd1;
    localparam logic [1:0] G_CHASE      = 2'd2;
    localparam logic [1:0] G_FRIGHTENED = 2'd3;

    localparam logic [1:0] DIR_UP    = 2'd0;
    localparam logic [1:0] DIR_LEFT  = 2'd1;
    localparam logic [1:0] DIR_DOWN  = 2'd2;
    localparam logic [1:0] DIR_RIGHT = 2'd3;

    ghost_target dut (
        .ghost_state(ghost_state),
        .ghost_id(ghost_id),
        .ghost_x(ghost_x),
        .ghost_y(ghost_y),
        .pacman_x(pacman_x),
        .pacman_y(pacman_y),
        .pacman_dir(pacman_dir),
        .target_x(target_x),
        .target_y(target_y)
    );

    task automatic check(input string name, input logic cond);
        if (cond) begin
            pass_count++;
            $display("PASS: %s", name);
        end else begin
            fail_count++;
            $display("FAIL: %s (got tx=%0d ty=%0d)", name, target_x, target_y);
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        ghost_state = G_CAGED;
        ghost_id    = 1'b0;
        ghost_x     = 5'd10;
        ghost_y     = 5'd10;
        pacman_x    = 5'd14;
        pacman_y    = 5'd17;
        pacman_dir  = DIR_RIGHT;

        $dumpfile("waves/ghost_target.vcd");
        $dumpvars(0, ghost_target_tb);

        #1;
        check("caged target (14,17)", (target_x === 5'd14) && (target_y === 5'd17));

        // Scatter Blinky / Pinky
        ghost_state = G_SCATTER;
        ghost_id    = 1'b0;
        #1;
        check("scatter Blinky (27,0)", (target_x === 5'd27) && (target_y === 5'd0));

        ghost_id = 1'b1;
        #1;
        check("scatter Pinky (0,0)", (target_x === 5'd0) && (target_y === 5'd0));

        // Chase Blinky follows Pac-Man
        ghost_state = G_CHASE;
        ghost_id    = 1'b0;
        pacman_x    = 5'd8;
        pacman_y    = 5'd12;
        #1;
        check("chase Blinky = Pac-Man", (target_x === 5'd8) && (target_y === 5'd12));

        // Chase Pinky lookahead
        ghost_id   = 1'b1;
        pacman_dir = DIR_RIGHT;
        pacman_x   = 5'd10;
        pacman_y   = 5'd10;
        #1;
        check("Pinky right +4", (target_x === 5'd14) && (target_y === 5'd10));

        pacman_dir = DIR_LEFT;
        #1;
        check("Pinky left -4", (target_x === 5'd6) && (target_y === 5'd10));

        pacman_dir = DIR_UP;
        #1;
        check("Pinky up -4", (target_x === 5'd10) && (target_y === 5'd6));

        pacman_dir = DIR_DOWN;
        #1;
        check("Pinky down +4", (target_x === 5'd10) && (target_y === 5'd14));

        // Clamp near edges
        pacman_dir = DIR_LEFT;
        pacman_x   = 5'd2;
        pacman_y   = 5'd5;
        #1;
        check("Pinky left clamp to 0", (target_x === 5'd0) && (target_y === 5'd5));

        pacman_dir = DIR_RIGHT;
        pacman_x   = 5'd25;
        #1;
        check("Pinky right clamp to 27", (target_x === 5'd27) && (target_y === 5'd5));

        pacman_dir = DIR_UP;
        pacman_x   = 5'd10;
        pacman_y   = 5'd2;
        #1;
        check("Pinky up clamp to 0", (target_x === 5'd10) && (target_y === 5'd0));

        pacman_dir = DIR_DOWN;
        pacman_y   = 5'd28;
        #1;
        check("Pinky down clamp to 30", (target_x === 5'd10) && (target_y === 5'd30));

        // Frightened targets self
        ghost_state = G_FRIGHTENED;
        ghost_x     = 5'd7;
        ghost_y     = 5'd19;
        #1;
        check("frightened = ghost pos", (target_x === 5'd7) && (target_y === 5'd19));

        $display("\nghost_target_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        $finish;
    end

endmodule
