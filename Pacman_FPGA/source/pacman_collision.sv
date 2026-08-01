`default_nettype none

module pacman_collision (
    input  wire logic       clk,
    input  wire logic       reset,
    input  wire logic       game_tick,
    input  wire logic       game_running,
    input  wire logic       game_starting,

    input  wire logic [4:0] pacman_x,
    input  wire logic [4:0] pacman_y,

    input  wire logic [4:0] blinky_x,
    input  wire logic [4:0] blinky_y,
    input  wire logic [4:0] pinky_x,
    input  wire logic [4:0] pinky_y,

    input  wire logic [1:0] dangerous_to_pacman,
    input  wire logic [1:0] vulnerable_to_pacman,
    input  wire logic       power_pellet_active,

    // Maze lookup via arbiter (collision port)
    output logic [4:0]      col_x,
    output logic [4:0]      col_y,
    input  wire logic       col_valid,
    input  wire logic       col_collectible,
    input  wire logic       col_is_power,
    input  wire logic [7:0] col_pellet_index,

    // pellet_state interface
    input  wire logic       pellet_already_eaten,  // eaten bit at col_pellet_index
    output logic            pellet_set_en,
    output logic [7:0]      pellet_set_index,

    output logic            pellet_eaten,
    output logic            power_pellet_eaten,
    output logic            pacman_hit,
    output logic [1:0]      ghost_eaten,
    output logic [1:0]      lives,
    output logic [7:0]      pellets
);

    logic collide_blinky;
    logic collide_pinky;

    always_comb begin
        collide_blinky =
            (pacman_x == blinky_x) &&
            (pacman_y == blinky_y);

        collide_pinky =
            (pacman_x == pinky_x) &&
            (pacman_y == pinky_y);
    end

    // Always query Pac-Man's current tile.
    always_comb begin
        col_x = pacman_x;
        col_y = pacman_y;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pellet_set_en      <= 1'b0;
            pellet_set_index   <= 8'd0;
            pellet_eaten       <= 1'b0;
            power_pellet_eaten <= 1'b0;
            pacman_hit         <= 1'b0;
            ghost_eaten        <= 2'b00;
            lives              <= 2'd3;
            pellets            <= 8'd186;
        end else if (game_starting) begin
            pellet_set_en      <= 1'b0;
            pellet_eaten       <= 1'b0;
            power_pellet_eaten <= 1'b0;
            pacman_hit         <= 1'b0;
            ghost_eaten        <= 2'b00;
            lives              <= 2'd3;
            pellets            <= 8'd186;
        end else begin
            pellet_set_en <= 1'b0;
            pellet_eaten  <= 1'b0;

            // Hold CDC events until the 60 Hz domain samples them, then clear.
            // Clear on the cycle after new_clock rises (game_tick still high).
            if (game_tick) begin
                power_pellet_eaten <= 1'b0;
                pacman_hit         <= 1'b0;
                ghost_eaten        <= 2'b00;
            end else if (game_running) begin
                if (collide_blinky) begin
                    if (power_pellet_active || vulnerable_to_pacman[0]) begin
                        if (!ghost_eaten[0])
                            ghost_eaten[0] <= 1'b1;
                    end else if (dangerous_to_pacman[0]) begin
                        if (!pacman_hit) begin
                            pacman_hit <= 1'b1;
                            lives <= lives - 2'd1;
                        end
                    end
                end

                if (collide_pinky) begin
                    if (power_pellet_active || vulnerable_to_pacman[1]) begin
                        if (!ghost_eaten[1])
                            ghost_eaten[1] <= 1'b1;
                    end else if (dangerous_to_pacman[1]) begin
                        if (!pacman_hit) begin
                            pacman_hit <= 1'b1;
                            lives <= lives - 2'd1;
                        end
                    end
                end

                // Pellet pickup: response must be valid for the current
                // position and the pellet must not already be eaten.
                if (col_valid && col_collectible && !pellet_already_eaten) begin
                    pellet_set_en    <= 1'b1;
                    pellet_set_index <= col_pellet_index;
                    pellets          <= pellets - 8'd1;

                    if (col_is_power) begin
                        power_pellet_eaten <= 1'b1;
                    end else begin
                        pellet_eaten <= 1'b1;
                    end
                end
            end
        end
    end

endmodule

`default_nettype wire
