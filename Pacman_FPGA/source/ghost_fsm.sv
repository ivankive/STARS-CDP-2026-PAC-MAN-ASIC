module ghost_fsm (
    input  logic       clk,
    input  logic       reset,

    input  logic [1:0] game_state,
    input  logic       power_pellet_active,
    input  logic       ghost_eaten,
    input  logic       global_ghost_mode,

    output logic [1:0] ghost_state,
    output logic       ghost_can_move,
    output logic       dangerous_to_pacman,
    output logic       vulnerable_to_pacman,
    output logic       frightened_start
);

    // Game FSM encodings
    localparam logic [1:0] GAME_STARTING = 2'd0;
    localparam logic [1:0] GAME_PLAYING  = 2'd1;
    localparam logic [1:0] GAME_OVER     = 2'd2;

    // Ghost state encodings
    localparam logic [1:0] G_CAGED      = 2'd0;
    localparam logic [1:0] G_SCATTER    = 2'd1;
    localparam logic [1:0] G_CHASE      = 2'd2;
    localparam logic [1:0] G_FRIGHTENED = 2'd3;

    // Global ghost mode
    localparam logic GLOBAL_SCATTER = 1'b0;
    localparam logic GLOBAL_CHASE   = 1'b1;

    logic [1:0] state;
    logic [1:0] next_state;

    assign ghost_state = state;

    // State register; frightened pulse
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= G_CAGED;
            frightened_start <= 1'b0;
        end
        else begin
            state <= next_state;
            frightened_start <= (state != G_FRIGHTENED) && (next_state == G_FRIGHTENED);
        end
    end

    // Next-state logic
    always_comb begin
        next_state = state;

        if (game_state != GAME_PLAYING) begin
            next_state = G_CAGED;
        end else begin
            case (state)

                G_CAGED: begin
                    if (power_pellet_active)
                        next_state = G_CAGED;
                    else if (global_ghost_mode == GLOBAL_SCATTER)
                        next_state = G_SCATTER;
                    else
                        next_state = G_CHASE;
                end

                G_SCATTER: begin
                    if (power_pellet_active)
                        next_state = G_FRIGHTENED;
                    else if (global_ghost_mode == GLOBAL_CHASE)
                        next_state = G_CHASE;
                end

                G_CHASE: begin
                    if (power_pellet_active)
                        next_state = G_FRIGHTENED;
                    else if (global_ghost_mode == GLOBAL_SCATTER)
                        next_state = G_SCATTER;
                end

                G_FRIGHTENED: begin
                    if (ghost_eaten)
                        next_state = G_CAGED;
                    else if (!power_pellet_active) begin
                        if (global_ghost_mode == GLOBAL_SCATTER)
                            next_state = G_SCATTER;
                        else
                            next_state = G_CHASE;
                    end
                end

                default: begin
                    next_state = G_CAGED;
                end

            endcase
        end
    end

    always_comb begin
        ghost_can_move       = (state != G_CAGED);
        dangerous_to_pacman  = ((state == G_SCATTER) || (state == G_CHASE)) && !power_pellet_active;
        vulnerable_to_pacman = (state == G_FRIGHTENED) || (power_pellet_active && (state != G_CAGED));
    end

endmodule