`timescale 1ns/1ps

module ghost_movement #(
    parameter logic [5:0] START_X = 6'd14,
    parameter logic [5:0] START_Y = 6'd15
)(
    input  logic clk,
    input  logic reset,

    input  logic move_tick,

    input  logic [1:0] ghost_state,
    input  logic       ghost_can_move,
    input  logic       frightened_start,

    input  logic [5:0] target_x,
    input  logic [5:0] target_y,

    // Legal movement signals from maze scheduler/arbiter
    input  logic can_up,
    input  logic can_down,
    input  logic can_left,
    input  logic can_right,

    output logic [5:0] ghost_x,
    output logic [5:0] ghost_y,
    output logic [1:0] ghost_dir
);

    // Ghost states
    localparam logic [1:0] G_CAGED      = 2'd0;
    localparam logic [1:0] G_SCATTER    = 2'd1;
    localparam logic [1:0] G_CHASE      = 2'd2;
    localparam logic [1:0] G_FRIGHTENED = 2'd3;

    // Directions
    localparam logic [1:0] DIR_UP    = 2'd0;
    localparam logic [1:0] DIR_DOWN  = 2'd1;
    localparam logic [1:0] DIR_LEFT  = 2'd2;
    localparam logic [1:0] DIR_RIGHT = 2'd3;

    logic [5:0] next_x;
    logic [5:0] next_y;
    logic [1:0] next_dir;

    logic [5:0] dx;
    logic [5:0] dy;

    logic [1:0] x_dir;
    logic [1:0] y_dir;

    logic x_needed;
    logic y_needed;
    logic prefer_x;

    logic [1:0] primary_dir;
    logic [1:0] secondary_dir;
    logic [1:0] chosen_dir;

    logic pending_reverse;
    logic do_reverse;

    // ------------------------------------------------------------
    // Check whether a direction is legal
    // ------------------------------------------------------------
    function automatic logic dir_legal;
        input logic [1:0] dir;
        begin
            case (dir)
                DIR_UP:    dir_legal = can_up;
                DIR_DOWN:  dir_legal = can_down;
                DIR_LEFT:  dir_legal = can_left;
                DIR_RIGHT: dir_legal = can_right;
                default:   dir_legal = 1'b0;
            endcase
        end
    endfunction

    // ------------------------------------------------------------
    // Opposite direction
    // ------------------------------------------------------------
    function automatic logic [1:0] opposite_dir;
        input logic [1:0] dir;
        begin
            case (dir)
                DIR_UP:    opposite_dir = DIR_DOWN;
                DIR_DOWN:  opposite_dir = DIR_UP;
                DIR_LEFT:  opposite_dir = DIR_RIGHT;
                DIR_RIGHT: opposite_dir = DIR_LEFT;
                default:   opposite_dir = DIR_LEFT;
            endcase
        end
    endfunction

    // ------------------------------------------------------------
    // Save reverse request if frightened_start occurs between moves
    // ------------------------------------------------------------
    assign do_reverse = frightened_start || pending_reverse;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pending_reverse <= 1'b0;
        end else begin
            if (frightened_start && !(move_tick && ghost_can_move))
                pending_reverse <= 1'b1;
            else if (move_tick && ghost_can_move && pending_reverse)
                pending_reverse <= 1'b0;
        end
    end

    // ------------------------------------------------------------
    // Compute rough target direction
    // Area-optimized: only dx/dy, not 4 full Manhattan distances
    // ------------------------------------------------------------
    always_comb begin
        if (target_x >= ghost_x)
            dx = target_x - ghost_x;
        else
            dx = ghost_x - target_x;

        if (target_y >= ghost_y)
            dy = target_y - ghost_y;
        else
            dy = ghost_y - target_y;

        x_needed = (target_x != ghost_x);
        y_needed = (target_y != ghost_y);

        if (target_x < ghost_x)
            x_dir = DIR_LEFT;
        else
            x_dir = DIR_RIGHT;

        if (target_y < ghost_y)
            y_dir = DIR_UP;
        else
            y_dir = DIR_DOWN;

        prefer_x = (dx >= dy);

        if (prefer_x) begin
            primary_dir   = x_dir;
            secondary_dir = y_dir;
        end else begin
            primary_dir   = y_dir;
            secondary_dir = x_dir;
        end

        if (!x_needed) begin
            primary_dir   = y_dir;
            secondary_dir = x_dir;
        end else if (!y_needed) begin
            primary_dir   = x_dir;
            secondary_dir = y_dir;
        end
    end

    // ------------------------------------------------------------
    // Choose direction
    // ------------------------------------------------------------
    always_comb begin
        chosen_dir = ghost_dir;

        if (!ghost_can_move) begin
            chosen_dir = ghost_dir;
        end

        // When frightened begins, reverse once if possible
        else if (do_reverse) begin
            chosen_dir = opposite_dir(ghost_dir);
        end

        // Frightened mode: simple low-area movement
        // Keep moving forward if possible; otherwise pick first legal turn.
        else if (ghost_state == G_FRIGHTENED) begin
            if (dir_legal(ghost_dir))
                chosen_dir = ghost_dir;
            else if (can_up)
                chosen_dir = DIR_UP;
            else if (can_left)
                chosen_dir = DIR_LEFT;
            else if (can_down)
                chosen_dir = DIR_DOWN;
            else if (can_right)
                chosen_dir = DIR_RIGHT;
            else
                chosen_dir = ghost_dir;
        end

        // Normal chase/scatter movement
        else begin
            // Try direction toward target, avoid immediate reverse
            if (dir_legal(primary_dir) &&
                (primary_dir != opposite_dir(ghost_dir))) begin
                chosen_dir = primary_dir;
            end

            else if (dir_legal(secondary_dir) &&
                     (secondary_dir != opposite_dir(ghost_dir))) begin
                chosen_dir = secondary_dir;
            end

            // Continue forward if the target directions are blocked
            else if (dir_legal(ghost_dir)) begin
                chosen_dir = ghost_dir;
            end

            // If needed, allow reverse as fallback
            else if (dir_legal(primary_dir)) begin
                chosen_dir = primary_dir;
            end

            else if (dir_legal(secondary_dir)) begin
                chosen_dir = secondary_dir;
            end

            // Final fallback priority
            else if (can_up) begin
                chosen_dir = DIR_UP;
            end

            else if (can_left) begin
                chosen_dir = DIR_LEFT;
            end

            else if (can_down) begin
                chosen_dir = DIR_DOWN;
            end

            else if (can_right) begin
                chosen_dir = DIR_RIGHT;
            end

            else begin
                chosen_dir = ghost_dir;
            end
        end
    end

    // ------------------------------------------------------------
    // Convert chosen direction into next tile
    // ------------------------------------------------------------
    always_comb begin
        next_x   = ghost_x;
        next_y   = ghost_y;
        next_dir = ghost_dir;

        if (ghost_can_move && dir_legal(chosen_dir)) begin
            next_dir = chosen_dir;

            case (chosen_dir)

                DIR_UP: begin
                    next_x = ghost_x;
                    next_y = ghost_y - 6'd1;
                end

                DIR_DOWN: begin
                    next_x = ghost_x;
                    next_y = ghost_y + 6'd1;
                end

                DIR_LEFT: begin
                    next_x = ghost_x - 6'd1;
                    next_y = ghost_y;
                end

                DIR_RIGHT: begin
                    next_x = ghost_x + 6'd1;
                    next_y = ghost_y;
                end

                default: begin
                    next_x = ghost_x;
                    next_y = ghost_y;
                end

            endcase
        end
    end

    // ------------------------------------------------------------
    // Position registers
    // ------------------------------------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            ghost_x   <= START_X;
            ghost_y   <= START_Y;
            ghost_dir <= DIR_LEFT;
        end else if (ghost_state == G_CAGED) begin
            ghost_x   <= START_X;
            ghost_y   <= START_Y;
            ghost_dir <= DIR_LEFT;
        end else if (move_tick) begin
            ghost_x   <= next_x;
            ghost_y   <= next_y;
            ghost_dir <= next_dir;
        end
    end

endmodule