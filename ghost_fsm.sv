`timescale 1ns/1ps

module ghost_fsm (
    input  logic clk,
    input  logic reset,

    input  logic [1:0] game_state, //from game_fsm
    input  logic power_pellet_active, //from power pellet register
    input  logic ghost_eaten, //from collision_fsm
    input  logic global_ghost_mode, //from global ghost mode register

    output logic [1:0] ghost_state,
    output logic       ghost_can_move,  
    output logic       dangerous_to_pacman,
    output logic       vulnerable_to_pacman
);

    typedef enum logic [1:0] {
        G_CAGED      = 2'd0,
        G_SCATTER    = 2'd1,
        G_CHASE      = 2'd2,
        G_FRIGHTENED = 2'd3
    } ghost_state_t;

    ghost_state_t state, next_state;

    assign ghost_state = state;

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            state <= G_CAGED;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;

        case (state)

            G_CAGED: begin
                if (ghost_release) begin
                    if (global_ghost_mode == 1'b0)
                        next_state = G_SCATTER;
                    else
                        next_state = G_CHASE;
                end
            end

            G_SCATTER: begin
                if (power_pellet_active)
                    next_state = G_FRIGHTENED;
                else if (global_ghost_mode == 1'b1)
                    next_state = G_CHASE;
            end

            G_CHASE: begin
                if (power_pellet_active)
                    next_state = G_FRIGHTENED;
                else if (global_ghost_mode == 1'b0)
                    next_state = G_SCATTER;
            end

            G_FRIGHTENED: begin
                if (ghost_eaten)
                    next_state = G_CAGED;
                else if (!power_pellet_active) begin
                    if (global_ghost_mode == 1'b0)
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

    always_comb begin
        ghost_can_move       = (state != G_CAGED);
        dangerous_to_pacman  = (state == G_SCATTER) || (state == G_CHASE);
        vulnerable_to_pacman = (state == G_FRIGHTENED);
    end

endmodule