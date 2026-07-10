`timescale 1ns/1ps

module ghost_target #(
    parameter int X_W = 6,
    parameter int Y_W = 6,

    parameter logic [X_W-1:0] GRID_MAX_X = 6'd27,
    parameter logic [Y_W-1:0] GRID_MAX_Y = 6'd30,

    parameter logic [X_W-1:0] CAGE_X = 6'd14,
    parameter logic [Y_W-1:0] CAGE_Y = 6'd17
)(
    input  logic [1:0]     ghost_state,
    input  logic           ghost_id,

    input  logic [X_W-1:0] ghost_x,
    input  logic [Y_W-1:0] ghost_y,

    input  logic [X_W-1:0] pacman_x,
    input  logic [Y_W-1:0] pacman_y,
    input  logic [1:0]     pacman_dir,

    output logic [X_W-1:0] target_x,
    output logic [Y_W-1:0] target_y
);

    // Ghost states
    localparam logic [1:0] G_CAGED      = 2'd0;
    localparam logic [1:0] G_SCATTER    = 2'd1;
    localparam logic [1:0] G_CHASE      = 2'd2;
    localparam logic [1:0] G_FRIGHTENED = 2'd3;

    // Ghost IDs
    localparam logic GHOST_BLINKY = 1'b0;
    localparam logic GHOST_PINKY  = 1'b1;

    // Directions
    localparam logic [1:0] DIR_UP    = 2'd0;
    localparam logic [1:0] DIR_DOWN  = 2'd1;
    localparam logic [1:0] DIR_LEFT  = 2'd2;
    localparam logic [1:0] DIR_RIGHT = 2'd3;

    // Scatter corners
    localparam logic [X_W-1:0] BLINKY_SCATTER_X = GRID_MAX_X;
    localparam logic [Y_W-1:0] BLINKY_SCATTER_Y = 6'd0;

    localparam logic [X_W-1:0] PINKY_SCATTER_X  = 6'd0;
    localparam logic [Y_W-1:0] PINKY_SCATTER_Y  = 6'd0;

    logic [X_W-1:0] pinky_x;
    logic [Y_W-1:0] pinky_y;

    always_comb begin
        pinky_x = pacman_x;
        pinky_y = pacman_y;

        case (pacman_dir)

            DIR_UP: begin
                if (pacman_y >= 6'd4)
                    pinky_y = pacman_y - 6'd4;
                else
                    pinky_y = 6'd0;
            end

            DIR_DOWN: begin
                if (pacman_y <= (GRID_MAX_Y - 6'd4))
                    pinky_y = pacman_y + 6'd4;
                else
                    pinky_y = GRID_MAX_Y;
            end

            DIR_LEFT: begin
                if (pacman_x >= 6'd4)
                    pinky_x = pacman_x - 6'd4;
                else
                    pinky_x = 6'd0;
            end

            DIR_RIGHT: begin
                if (pacman_x <= (GRID_MAX_X - 6'd4))
                    pinky_x = pacman_x + 6'd4;
                else
                    pinky_x = GRID_MAX_X;
            end

            default: begin
                pinky_x = pacman_x;
                pinky_y = pacman_y;
            end

        endcase
    end

    always_comb begin
        target_x = CAGE_X;
        target_y = CAGE_Y;

        case (ghost_state)

            G_CAGED: begin
                target_x = CAGE_X;
                target_y = CAGE_Y;
            end

            G_SCATTER: begin
                case (ghost_id)
                    GHOST_BLINKY: begin
                        target_x = BLINKY_SCATTER_X;
                        target_y = BLINKY_SCATTER_Y;
                    end

                    GHOST_PINKY: begin
                        target_x = PINKY_SCATTER_X;
                        target_y = PINKY_SCATTER_Y;
                    end

                    default: begin
                        target_x = CAGE_X;
                        target_y = CAGE_Y;
                    end
                endcase
            end

            G_CHASE: begin
                case (ghost_id)
                    GHOST_BLINKY: begin
                        target_x = pacman_x;
                        target_y = pacman_y;
                    end

                    GHOST_PINKY: begin
                        target_x = pinky_x;
                        target_y = pinky_y;
                    end

                    default: begin
                        target_x = pacman_x;
                        target_y = pacman_y;
                    end
                endcase
            end

            G_FRIGHTENED: begin
                target_x = ghost_x;
                target_y = ghost_y;
            end

            default: begin
                target_x = CAGE_X;
                target_y = CAGE_Y;
            end

        endcase
    end

endmodule