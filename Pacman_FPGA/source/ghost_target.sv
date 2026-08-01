module ghost_target (
    input  logic [1:0]     ghost_state,
    input  logic           ghost_id,

    input  logic [4:0] ghost_x,
    input  logic [4:0] ghost_y,

    input  logic [4:0] pacman_x,
    input  logic [4:0] pacman_y,
    input  logic [1:0]     pacman_dir,

    output logic [4:0] target_x,
    output logic [4:0] target_y
);

    localparam logic [1:0] G_CAGED      = 2'd0;
    localparam logic [1:0] G_SCATTER    = 2'd1;
    localparam logic [1:0] G_CHASE      = 2'd2;
    localparam logic [1:0] G_FRIGHTENED = 2'd3;

    localparam logic [1:0] DIR_UP    = 2'd0;
    localparam logic [1:0] DIR_LEFT  = 2'd1;
    localparam logic [1:0] DIR_DOWN  = 2'd2;
    localparam logic [1:0] DIR_RIGHT = 2'd3;

    localparam logic [4:0] LOOKAHEAD = 5'(4);

    logic [4:0] pinky_target_x;
    logic [4:0] pinky_target_y;

    /*
     * Pinky targets four tiles ahead of Pac-Man.
     * The result is limited to the maze boundaries.
     */
    always_comb begin
        pinky_target_x = pacman_x;
        pinky_target_y = pacman_y;

        case (pacman_dir)
            DIR_UP: begin
                if (pacman_y >= LOOKAHEAD)
                    pinky_target_y = pacman_y - LOOKAHEAD;
                else
                    pinky_target_y = '0;
            end

            DIR_DOWN: begin
                if (pacman_y <= 30 - LOOKAHEAD)
                    pinky_target_y = pacman_y + LOOKAHEAD;
                else
                    pinky_target_y = 30;
            end

            DIR_LEFT: begin
                if (pacman_x >= LOOKAHEAD)
                    pinky_target_x = pacman_x - LOOKAHEAD;
                else
                    pinky_target_x = '0;
            end

            DIR_RIGHT: begin
                if (pacman_x <= 27 - LOOKAHEAD)
                    pinky_target_x = pacman_x + LOOKAHEAD;
                else
                    pinky_target_x = 27;
            end

            default: begin
                pinky_target_x = pacman_x;
                pinky_target_y = pacman_y;
            end
        endcase
    end

    always_comb begin
        target_x = 5'd14;
        target_y = 5'd17;

        case (ghost_state)
            G_SCATTER: begin
                /*
                 * Blinky: upper-right corner.
                 * Pinky:  upper-left corner.
                 */
                target_x = ghost_id ? '0 : 27;
                target_y = '0;
            end

            G_CHASE: begin
                if (ghost_id == 1'b0) begin
                    target_x = pacman_x;
                    target_y = pacman_y;
                end else begin
                    target_x = pinky_target_x;
                    target_y = pinky_target_y;
                end
            end

            G_FRIGHTENED: begin
                target_x = ghost_x;
                target_y = ghost_y;
            end

            G_CAGED: begin
                target_x = 5'd14;
                target_y = 5'd17;
            end

            default: begin
                target_x = 5'd14;
                target_y = 5'd17;
            end
        endcase
    end

endmodule