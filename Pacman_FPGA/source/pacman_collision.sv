`default_nettype none

module pacman_collision (
    input  logic       clk,
    input  logic       reset,
    input  logic       game_tick,
    input  logic       game_running,
    input  logic       game_starting,

    input  logic [4:0] pacman_x,
    input  logic [4:0] pacman_y,

    input  logic [4:0] blinky_x,
    input  logic [4:0] blinky_y,
    input  logic [4:0] pinky_x,
    input  logic [4:0] pinky_y,

    input  logic [1:0] dangerous_to_pacman,
    input  logic [1:0] vulnerable_to_pacman,
    input  logic       power_pellet_active,

    output logic [4:0] x_central,
    output logic [4:0] y_central,
    output logic       write_en,
    input  logic [1:0] rdata_central,

    output logic       pellet_eaten,
    output logic       power_pellet_eaten,
    output logic       pacman_hit,
    output logic [9:0] score,
    output logic [1:0] ghost_eaten,
    output logic [1:0] lives,
    output logic [8:0] pellets
);

    localparam logic [1:0] TILE_BLANK        = 2'b00;
    localparam logic [1:0] TILE_WALL         = 2'b01;
    localparam logic [1:0] TILE_PELLET       = 2'b10;
    localparam logic [1:0] TILE_POWER_PELLET = 2'b11;

    typedef enum logic [1:0] {
        S_READ,
        S_WAIT,
        S_CHECK
    } collision_state_t;

    collision_state_t state;
    logic collide_blinky;
    logic collide_pinky;
    logic [9:0] score_delta;

    always_comb begin
        collide_blinky =
            (pacman_x == blinky_x) &&
            (pacman_y == blinky_y);

        collide_pinky =
            (pacman_x == pinky_x) &&
            (pacman_y == pinky_y);
    end

    always_comb begin
        x_central = pacman_x;
        y_central = pacman_y;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state              <= S_READ;
            write_en           <= 1'b0;
            pellet_eaten       <= 1'b0;
            power_pellet_eaten <= 1'b0;
            pacman_hit         <= 1'b0;
            ghost_eaten        <= 2'b00;
            score              <= 10'd0;
            lives              <= 2'd3;
            pellets            <= 9'd288;
        end else if (game_starting) begin
            state              <= S_READ;
            write_en           <= 1'b0;
            pellet_eaten       <= 1'b0;
            power_pellet_eaten <= 1'b0;
            pacman_hit         <= 1'b0;
            ghost_eaten        <= 2'b00;
            score              <= 10'd0;
            lives              <= 2'd3;
            pellets            <= 9'd288; 
        end else begin
            write_en     <= 1'b0;
            pellet_eaten <= 1'b0;
            score_delta  = 10'd0;

            // Hold CDC events until the 60 Hz domain samples them, then clear.
            // Clear on the cycle after new_clock rises (game_tick still high).
            if (game_tick) begin
                power_pellet_eaten <= 1'b0;
                pacman_hit         <= 1'b0;
                ghost_eaten        <= 2'b00;
            end else if (game_running) begin
                if (collide_blinky) begin
                    if (power_pellet_active || vulnerable_to_pacman[0]) begin
                        if (!ghost_eaten[0]) begin
                            ghost_eaten[0] <= 1'b1;
                            score_delta = score_delta + 10'd10;
                        end
                    end else if (dangerous_to_pacman[0]) begin
                        if (!pacman_hit) begin
                            pacman_hit <= 1'b1;
                            lives <= lives - 2'd1;
                        end
                    end
                end

                if (collide_pinky) begin
                    if (power_pellet_active || vulnerable_to_pacman[1]) begin
                        if (!ghost_eaten[1]) begin
                            ghost_eaten[1] <= 1'b1;
                            score_delta = score_delta + 10'd10;
                        end
                    end else if (dangerous_to_pacman[1]) begin
                        if (!pacman_hit) begin
                            pacman_hit <= 1'b1;
                            lives <= lives - 2'd1;
                        end
                    end
                end

                case (state)
                    S_READ: begin
                        state <= S_WAIT;
                    end

                    S_WAIT: begin
                        state <= S_CHECK;
                    end

                    S_CHECK: begin
                        if (rdata_central == TILE_PELLET) begin
                            write_en     <= 1'b1;
                            pellet_eaten <= 1'b1;
                            score_delta  = score_delta + 10'd2;
                            pellets      <= pellets - 9'd1;
                        end else if (rdata_central == TILE_POWER_PELLET) begin
                            write_en <= 1'b1;
                            if (!power_pellet_eaten) begin
                                power_pellet_eaten <= 1'b1;
                                 score_delta = score_delta + 10'd10;
                                pellets <= pellets - 9'd1;
                            end
                        end

                        state <= S_READ;
                    end

                    default: begin
                        state <= S_READ;
                    end
                endcase

                 if (score_delta != 10'd0)
                     score <= score + score_delta;
            end

            if (!game_running)
                state <= S_READ;
        end
    end

endmodule

`default_nettype wire
