module game_fsm (
    input  logic       clk,
    input  logic       reset,

    // Maze reset/reload control
    input  logic       map_rst,
    input  logic       reload_done,
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

    // Rising edge of any button (level holds must not advance the FSM).
    logic inputs_any;
    logic inputs_any_d;
    logic inputs_rise;

    assign inputs_any  = |inputs;
    assign inputs_rise = inputs_any && !inputs_any_d;

    always_ff @(posedge clk) begin
        if (reset)
            inputs_any_d <= 1'b0;
        else
            inputs_any_d <= inputs_any;
    end

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

            // Wait for maze load, then require a fresh button press.
            GAME_STARTING: begin
                if (reload_done && inputs_rise)
                    next_state = GAME_PLAYING;
            end

            // Remain here while Pac-Man still has lives.
            GAME_PLAYING: begin
                if (lives == 2'd0)
                    next_state = GAME_OVER;
                else if (pellets == 9'd0)
                    next_state = GAME_WIN;
                else if (map_rst)
                    next_state = GAME_STARTING;
            end

            // Remain in game over until a fresh button press / map_rst.
            GAME_OVER: begin
                if (map_rst || inputs_rise)
                    next_state = GAME_STARTING;
            end

            GAME_WIN: begin
                if (map_rst || inputs_rise)
                    next_state = GAME_STARTING;
            end

            default: begin
                next_state = GAME_STARTING;
            end

        endcase
    end

endmodule
