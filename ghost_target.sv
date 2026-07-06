`timescale 1ns/1ps

module ghost_target #(
    parameter int GRID_WIDTH  = 28,
    parameter int GRID_HEIGHT = 31,

    parameter logic [5:0] CAGE_X = 6'd14,
    parameter logic [5:0] CAGE_Y = 6'd15
)(
    input  logic [1:0] ghost_state,
    input  logic [1:0] ghost_id,

    input  logic [5:0] pacman_x,
    input  logic [5:0] pacman_y,
    input  logic [1:0] pacman_dir,

    input  logic [5:0] ghost_x,
    input  logic [5:0] ghost_y,

    output logic [5:0] target_x,
    output logic [5:0] target_y
);

    // Ghost FSM state encodings
    localparam logic [1:0] G_CAGED      = 2'd0;
    localparam logic [1:0] G_SCATTER    = 2'd1;
    localparam logic [1:0] G_CHASE      = 2'd2;
    localparam logic [1:0] G_FRIGHTENED = 2'd3;

    // Ghost IDs
    localparam logic [1:0] GHOST_BLINKY = 2'd0;
    localparam logic [1:0] GHOST_PINKY  = 2'd1;
    localparam logic [1:0] GHOST_INKY   = 2'd2;
    localparam logic [1:0] GHOST_CLYDE  = 2'd3;

    always_comb begin
        // Safe default 
        target_x = CAGE_X;
        target_y = CAGE_Y;

        case (ghost_state)

            G_CAGED: begin
                target_x = CAGE_X;
                target_y = CAGE_Y;
            end

            G_SCATTER: begin
                case (ghost_id)

                    // Top-right corner
                    GHOST_BLINKY: begin
                        target_x = GRID_WIDTH - 2;
                        target_y = 6'd1;
                    end

                    // Top-left corner
                    GHOST_PINKY: begin
                        target_x = 6'd1;
                        target_y = 6'd1;
                    end

                    // Bottom-right corner
                    GHOST_INKY: begin
                        target_x = GRID_WIDTH - 2;
                        target_y = GRID_HEIGHT - 2;
                    end

                    // Bottom-left corner
                    GHOST_CLYDE: begin
                        target_x = 6'd1;
                        target_y = GRID_HEIGHT - 2;
                    end

                    default: begin
                        target_x = CAGE_X;
                        target_y = CAGE_Y;
                    end

                endcase
            end

            G_CHASE: begin
                case(ghost_id)
                    GHOST_BLINKY: begin
                        target_x = pacman_x;
                        target_y = pacman_y;
                    end

                    GHOST_PINKY: begin 
                        if(pacman_dir == 1'b0) begin
                            target_x = pacman_x + 3'b100;
                        end else if(pacman_dir == 2'b10) begin
                            target_x = pacman_x - 3'b100;
                        end else if(pacman_dir == 2'b01) begin
                            target_y = pacman_y + 3'b100;
                        end else begin
                            target_y = pacman_y - 3'b100;
                        end
                    end

                    default: begin
                        target_x = CAGE_X;
                        target_y = CAGE_Y;
                    end
                endcase
            end

            G_FRIGHTENED: begin //is basically ignored since frightened movement is random and is controlled in movement, not as target
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