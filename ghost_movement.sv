`timescale 1ns/1ps

module ghost_movement_brain #(
    parameter int X_W = 6,
    parameter int Y_W = 6
)(
    input  logic [1:0]     ghost_state,
    input  logic           ghost_can_move,

    input  logic [X_W-1:0] ghost_x,
    input  logic [Y_W-1:0] ghost_y,
    input  logic [1:0]     ghost_dir,

    input  logic [X_W-1:0] target_x,
    input  logic [Y_W-1:0] target_y,

    input  logic           can_up,
    input  logic           can_down,
    input  logic           can_left,
    input  logic           can_right,

    input  logic           do_reverse,

    output logic [X_W-1:0] next_x,
    output logic [Y_W-1:0] next_y,
    output logic [1:0]     next_dir
);

    // Ghost states
    localparam logic [1:0] G_CAGED      = 2'd0;
    localparam logic [1:0] G_SCATTER    = 2'd1;
    localparam logic [1:0] G_CHASE      = 2'd2;
    localparam logic [1:0] G_FRIGHTENED = 2'd3;

    // Directions
    localparam logic [1:0] DIR_UP    = 2'd0; // 00
    localparam logic [1:0] DIR_DOWN  = 2'd1; // 01
    localparam logic [1:0] DIR_LEFT  = 2'd2; // 10
    localparam logic [1:0] DIR_RIGHT = 2'd3; // 11

    logic [1:0] reverse_dir;

    always_comb begin
        reverse_dir = ghost_dir ^ 2'b01;
    end

    // Check if a direction is legal.
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

    always_comb begin
        next_dir = ghost_dir;

        if (!ghost_can_move || (ghost_state == G_CAGED)) begin
            next_dir = ghost_dir;
        end

        else if (do_reverse && dir_legal(reverse_dir)) begin
            next_dir = reverse_dir;
        end

        else begin
            if ((target_x > ghost_x) && can_right && (DIR_RIGHT != reverse_dir)) begin
                next_dir = DIR_RIGHT;
            end

            else if ((target_x < ghost_x) && can_left && (DIR_LEFT != reverse_dir)) begin
                next_dir = DIR_LEFT;
            end

            else if ((target_y > ghost_y) && can_down && (DIR_DOWN != reverse_dir)) begin
                next_dir = DIR_DOWN;
            end

            else if ((target_y < ghost_y) && can_up && (DIR_UP != reverse_dir)) begin
                next_dir = DIR_UP;
            end

            else if (dir_legal(ghost_dir)) begin
                next_dir = ghost_dir;
            end

            // Then pick first legal non-reverse direction.
            else if (can_up && (DIR_UP != reverse_dir)) begin
                next_dir = DIR_UP;
            end

            else if (can_left && (DIR_LEFT != reverse_dir)) begin
                next_dir = DIR_LEFT;
            end

            else if (can_down && (DIR_DOWN != reverse_dir)) begin
                next_dir = DIR_DOWN;
            end

            else if (can_right && (DIR_RIGHT != reverse_dir)) begin
                next_dir = DIR_RIGHT;
            end

            // Reverse only as final fallback.
            else if (dir_legal(reverse_dir)) begin
                next_dir = reverse_dir;
            end

            else begin
                next_dir = ghost_dir;
            end
        end
    end

    always_comb begin
        next_x = ghost_x;
        next_y = ghost_y;

        if (ghost_can_move && (ghost_state != G_CAGED)) begin
            case (next_dir)

                DIR_UP: begin
                    next_y = ghost_y - 1'b1;
                end

                DIR_DOWN: begin
                    next_y = ghost_y + 1'b1;
                end

                DIR_LEFT: begin
                    next_x = ghost_x - 1'b1;
                end

                DIR_RIGHT: begin
                    next_x = ghost_x + 1'b1;
                end

                default: begin
                    next_x = ghost_x;
                    next_y = ghost_y;
                end

            endcase
        end
    end

endmodule