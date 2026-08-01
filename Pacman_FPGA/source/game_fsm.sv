// game_fsm - tapeout version
//
// Changes vs FPGA version: the maze-reload handshake (map_rst /
// reload_done / map_loaded) is gone. There is no ROM-to-BRAM copy any
// more - a new game only requires clearing the pellet_state array, which
// top.sv does combinationally while this FSM sits in GAME_STARTING.
// GAME_STARTING therefore starts the game on a button press edge.
//
// Button edges (not levels) are required so WIN/OVER -> STARTING does not
// immediately fall through to PLAYING while the same press is still held.

module game_fsm (
    input  logic       clk,
    input  logic       reset,

    input  logic [1:0] lives,
    input  logic [7:0] pellets,
    input  logic [3:0] inputs,
    output logic [1:0] game_state
);

    localparam logic [1:0]
        GAME_STARTING = 2'd0,
        GAME_PLAYING  = 2'd1,
        GAME_OVER     = 2'd2,
        GAME_WIN      = 2'd3;

    logic [1:0] next_state;
    logic       inputs_any;
    logic       inputs_any_d;
    logic       press;

    assign inputs_any = |inputs;
    assign press      = inputs_any & ~inputs_any_d;

    always_ff @(posedge clk) begin
        if (reset) begin
            game_state    <= GAME_STARTING;
            inputs_any_d  <= 1'b0;
        end else begin
            game_state   <= next_state;
            inputs_any_d <= inputs_any;
        end
    end

    // Next-state logic
    always_comb begin
        next_state = game_state;

        case (game_state)

            // Pellet state is being held clear; wait for a new button press.
            GAME_STARTING: begin
                if (press)
                    next_state = GAME_PLAYING;
            end

            GAME_PLAYING: begin
                if (lives == 2'd0)
                    next_state = GAME_OVER;
                else if (pellets == 8'd0)
                    next_state = GAME_WIN;
            end

            GAME_OVER: begin
                if (press)
                    next_state = GAME_STARTING;
            end

            GAME_WIN: begin
                if (press)
                    next_state = GAME_STARTING;
            end

            default: begin
                next_state = GAME_STARTING;
            end

        endcase
    end

endmodule
