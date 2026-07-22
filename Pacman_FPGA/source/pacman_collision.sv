`default_nettype none

module pacman_collision (
    input  logic       clk,
    input  logic       reset,
    input  logic       game_running,

    input  logic [4:0] pacman_x,
    input  logic [4:0] pacman_y,

    input  logic [4:0] blinky_x,
    input  logic [4:0] blinky_y,
    input  logic [4:0] pinky_x,
    input  logic [4:0] pinky_y,

    input  logic [1:0] dangerous_to_pacman,
    input  logic [1:0] vulnerable_to_pacman,

    output logic [4:0] x_central,
    output logic [4:0] y_central,
    output logic       write_en,
    input  logic [1:0] rdata_central,

    output logic       pellet_eaten,
    output logic       power_pellet_eaten,
    output logic       pacman_hit,
    output logic [9:0] score,
    output logic [1:0] ghost_eaten
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
        end else begin
            write_en           <= 1'b0;
            pellet_eaten       <= 1'b0;
            power_pellet_eaten <= 1'b0;
            pacman_hit         <= 1'b0;
            ghost_eaten        <= 2'b00;

            if (!game_running) begin
                state <= S_READ;
            end else begin
                if (collide_blinky) begin
                    if (vulnerable_to_pacman[0]) begin
                        ghost_eaten[0] <= 1'b1;
                        score <= score + 10'd50;
                    end else if (dangerous_to_pacman[0])
                        pacman_hit <= 1'b1;
                end

                if (collide_pinky) begin
                    if (vulnerable_to_pacman[1]) begin
                        ghost_eaten[1] <= 1'b1;
                        score <= score + 10'd50;
                    end else if (dangerous_to_pacman[1])
                        pacman_hit <= 1'b1;
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
                            score <= score + 10'd2;
                        end else if (rdata_central == TILE_POWER_PELLET) begin
                            write_en           <= 1'b1;
                            power_pellet_eaten <= 1'b1;
                            score <= score + 10'd15;
                        end

                        state <= S_READ;
                    end

                    default: begin
                        state <= S_READ;
                    end
                endcase
            end
        end
    end

endmodule

`default_nettype wire
