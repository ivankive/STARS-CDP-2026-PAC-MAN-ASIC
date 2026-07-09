`timescale 1ns/1ps

module ghost_target #(
    parameter logic [5:0] GRID_MAX_X = 6'd27,
    parameter logic [5:0] GRID_MAX_Y = 6'd30,

    parameter logic [5:0] CAGE_X = 6'd14,
    parameter logic [5:0] CAGE_Y = 6'd15,

    parameter logic [5:0] BLINKY_SCATTER_X = 6'd26,
    parameter logic [5:0] BLINKY_SCATTER_Y = 6'd1,

    parameter logic [5:0] PINKY_SCATTER_X  = 6'd1,
    parameter logic [5:0] PINKY_SCATTER_Y  = 6'd1
)(
    input  logic [1:0] ghost_state,
    input  logic [1:0] ghost_id,

    input  logic [5:0] pacman_x,
    input  logic [5:0] pacman_y,
    input  logic [1:0] pacman_dir,

    output logic [5:0] target_x,
    output logic [5:0] target_y
);

    // Ghost states
    localparam logic [1:0] G_CAGED      = 2'd0;
    localparam logic [1:0] G_SCATTER    = 2'd1;
    localparam logic [1:0] G_CHASE      = 2'd2;
    localparam logic [1:0] G_FRIGHTENED = 2'd3;

    // Ghost IDs
    localparam logic [1:0] GHOST_BLINKY = 2'd0;
    localparam logic [1:0] GHOST_PINKY  = 2'd1;
    localparam logic [1:0] GHOST_INKY   = 2'd2;
    localparam logic [1:0] GHOST_CLYDE  = 2'd3;

    // Directions
    localparam logic [1:0] DIR_UP    = 2'd0;
    localparam logic [1:0] DIR_DOWN  = 2'd1;
    localparam logic [1:0] DIR_LEFT  = 2'd2;
    localparam logic [1:0] DIR_RIGHT = 2'd3;

    logic [5:0] pinky_x;
    logic [5:0] pinky_y;

    // Pinky targets 4 tiles ahead of Pac-Man, saturated at maze edges.
    always_comb begin
        pinky_x = pacman_x;
        pinky_y = pacman_y;

        case (pacman_dir)

            DIR_UP: begin
                pinky_x = pacman_x;

                if (pacman_y >= 6'd4)
                    pinky_y = pacman_y - 6'd4;
                else
                    pinky_y = 6'd0;
            end

            DIR_DOWN: begin
                pinky_x = pacman_x;

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

                pinky_y = pacman_y;
            end

            DIR_RIGHT: begin
                if (pacman_x <= (GRID_MAX_X - 6'd4))
                    pinky_x = pacman_x + 6'd4;
                else
                    pinky_x = GRID_MAX_X;

                pinky_y = pacman_y;
            end

            default: begin
                pinky_x = pacman_x;
                pinky_y = pacman_y;
            end

        endcase
    end

    // Main target selector
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

                    GHOST_INKY: begin
                        target_x = INKY_SCATTER_X;
                        target_y = INKY_SCATTER_Y;
                    end

                    GHOST_CLYDE: begin
                        target_x = CLYDE_SCATTER_X;
                        target_y = CLYDE_SCATTER_Y;
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

            // Movement module ignores target during frightened mode.
            G_FRIGHTENED: begin
                target_x = pacman_x;
                target_y = pacman_y;
            end

            default: begin
                target_x = CAGE_X;
                target_y = CAGE_Y;
            end

        endcase
    end

endmodule