module pacman_movement (
    input  logic       clk,
    input  logic       reset,

    input  logic       enable,
    input  logic       game_starting,
    input  logic [3:0] pb,

    input  logic       pacman_hit,

    // Shared maze lookup via arbiter
    output logic [4:0] rom_x,
    output logic [4:0] rom_y,
    input  logic       rom_valid,
    input  logic       rom_can_move,

    output logic [4:0] xpos,
    output logic [4:0] ypos,
    output logic [1:0] direction
);

    localparam logic [1:0] UP    = 2'd0;
    localparam logic [1:0] LEFT  = 2'd1;
    localparam logic [1:0] DOWN  = 2'd2;
    localparam logic [1:0] RIGHT = 2'd3;

    typedef enum logic [1:0] {
        S_IDLE,
        S_CHECK_TURN,
        S_CHECK_FORWARD
    } state_t;

    state_t state;

    logic [1:0] dir;
    logic [1:0] stored_dir;
    logic [1:0] test_dir;

    logic [2:0] count;

    assign direction = dir;

    // Tile currently being tested through the arbiter.
    always_comb begin
        rom_x = xpos;
        rom_y = ypos;
        case (test_dir)
            LEFT: begin
                rom_x = xpos - 5'd1;
                rom_y = ypos;
            end
            RIGHT: begin
                rom_x = xpos + 5'd1;
                rom_y = ypos;
            end
            UP: begin
                rom_x = xpos;
                rom_y = ypos - 5'd1;
            end
            DOWN: begin
                rom_x = xpos;
                rom_y = ypos + 5'd1;
            end
            default: begin
                rom_x = xpos;
                rom_y = ypos;
            end
        endcase
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            xpos       <= 5'd11;
            ypos       <= 5'd19;
            dir        <= RIGHT;
            stored_dir <= RIGHT;
            test_dir   <= RIGHT;
            count      <= 3'd0;
            state      <= S_IDLE;
        end else if (game_starting || pacman_hit) begin
            xpos       <= 5'd11;
            ypos       <= 5'd19;
            dir        <= RIGHT;
            stored_dir <= RIGHT;
            test_dir   <= RIGHT;
            count      <= 3'd0;
            state      <= S_IDLE;
        end else begin
            if (pb[0])
                stored_dir <= UP;
            else if (pb[1])
                stored_dir <= RIGHT;
            else if (pb[2])
                stored_dir <= DOWN;
            else if (pb[3])
                stored_dir <= LEFT;

            if (!enable) begin
                count <= 3'd0;
                state <= S_IDLE;
            end else begin
                case (state)

                    S_IDLE: begin
                        if (count == 3'd7) begin
                            count    <= 3'd0;
                            test_dir <= stored_dir;
                            state    <= S_CHECK_TURN;
                        end else begin
                            count <= count + 3'd1;
                        end
                    end

                    // Wait for a valid arbiter response before acting.
                    S_CHECK_TURN: begin
                        if (rom_valid) begin
                            if (rom_can_move) begin
                                dir  <= test_dir;
                                xpos <= rom_x;
                                ypos <= rom_y;
                                state <= S_IDLE;
                            end else begin
                                test_dir <= dir;
                                state    <= S_CHECK_FORWARD;
                            end
                        end
                    end

                    S_CHECK_FORWARD: begin
                        // Tunnel teleports need no maze lookup.
                        if (xpos == 5'd0 && ypos == 5'd13 && dir == LEFT) begin
                            xpos  <= 5'd23;
                            state <= S_IDLE;
                        end else if (xpos == 5'd23 && ypos == 5'd13 && dir == RIGHT) begin
                            xpos  <= 5'd0;
                            state <= S_IDLE;
                        end else if (rom_valid) begin
                            if (rom_can_move) begin
                                xpos <= rom_x;
                                ypos <= rom_y;
                            end
                            state <= S_IDLE;
                        end
                    end

                    default: begin
                        state <= S_IDLE;
                    end

                endcase
            end
        end
    end

endmodule
