// game_fsm - tapeout version
//
// Changes vs FPGA version: the maze-reload handshake (map_rst /
// reload_done / map_loaded) is gone. There is no ROM-to-BRAM copy any
// more - a new game only requires clearing the pellet_state array, which
// top.sv does combinationally while this FSM sits in GAME_STARTING.
// GAME_STARTING therefore starts the game on any button press.

module game_fsm (
    input  logic       clk,
    input  logic       reset,

    input  logic [1:0] lives,
    input  logic [8:0] pellets,
    input  logic [3:0] inputs,
    output logic [1:0] game_state
);

    localparam logic [1:0]
        GAME_STARTING = 2'd0,
        GAME_PLAYING  = 2'd1,
        GAME_OVER     = 2'd2,
        GAME_WIN      = 2'd3;

    logic [1:0] next_state;

    always_ff @(posedge clk) begin
        if (reset)
            game_state <= GAME_STARTING;
        else
            game_state <= next_state;
    end

    // Next-state logic
    always_comb begin
        next_state = game_state;

        case (game_state)

            // Pellet state is being held clear; wait for a button press.
            GAME_STARTING: begin
                if (|inputs)
                    next_state = GAME_PLAYING;
            end

            GAME_PLAYING: begin
                if (lives == 2'd0)
                    next_state = GAME_OVER;
                else if (pellets == 9'd0)
                    next_state = GAME_WIN;
            end

            GAME_OVER: begin
                if (|inputs)
                    next_state = GAME_STARTING;
            end

            GAME_WIN: begin
                if (|inputs)
                    next_state = GAME_STARTING;
            end

            default: begin
                next_state = GAME_STARTING;
            end

        endcase
    end

endmodule
