`timescale 1ns/1ps

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

    localparam logic [1:0] GAME_PLAYING = 2'd1;

    localparam logic [1:0] G_CAGED      = 2'd0;
    localparam logic [1:0] G_SCATTER    = 2'd1;
    localparam logic [1:0] G_CHASE      = 2'd2;
    localparam logic [1:0] G_FRIGHTENED = 2'd3;

    logic [1:0] state;
    logic [1:0] next_state;

    always_comb begin
        if ((game_state != GAME_PLAYING) || ghost_eaten)
            next_state = G_CAGED;
        else if (power_pellet_active)
            next_state = G_FRIGHTENED;
        else if (global_ghost_mode)
            next_state = G_CHASE;
        else
            next_state = G_SCATTER;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state             <= G_CAGED;
            frightened_start <= 1'b0;
        end else begin
            state <= next_state;

            frightened_start <=
                (state != G_FRIGHTENED) &&
                (next_state == G_FRIGHTENED);
        end
    end

    assign ghost_state          = state;
    assign ghost_can_move       = (state != G_CAGED);
    assign dangerous_to_pacman  = (state == G_SCATTER) ||
                                  (state == G_CHASE);
    assign vulnerable_to_pacman = (state == G_FRIGHTENED);

endmodule