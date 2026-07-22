module ghost_controller (
    input  logic clk,
    input  logic reset,

    input  logic [1:0] game_state,
    input  logic       power_pellet_active,
    input  logic       global_ghost_mode,

    input  logic [4:0] pacman_x,
    input  logic [4:0] pacman_y,
    input  logic [1:0] pacman_dir,
    input  logic       pacman_hit,

    input  logic [1:0] ghost_eaten,

    // Shared asynchronous maze ROM interface
    output logic [4:0] ghost_rom_x,
    output logic [4:0] ghost_rom_y,
    input  logic       ghost_rom_can_move,

    output logic [4:0] blinky_x,
    output logic [4:0] blinky_y,
    output logic [1:0] blinky_dir,

    output logic [4:0] pinky_x,
    output logic [4:0] pinky_y,
    output logic [1:0] pinky_dir,

    output logic [1:0] dangerous_to_pacman,
    output logic [1:0] vulnerable_to_pacman
);

    localparam logic GHOST_BLINKY = 1'b0;
    localparam logic GHOST_PINKY  = 1'b1;

    localparam logic [1:0] G_CAGED = 2'd0;

    localparam logic [1:0] DIR_UP    = 2'd0;
    localparam logic [1:0] DIR_LEFT  = 2'd1;
    localparam logic [1:0] DIR_DOWN  = 2'd2;
    localparam logic [1:0] DIR_RIGHT = 2'd3;

    localparam logic [4:0] GRID_MAX_X = 5'd27;
    localparam logic [4:0] GRID_MAX_Y = 5'd30;

    localparam logic [4:0] BLINKY_START_X = 5'd14;
    localparam logic [4:0] BLINKY_START_Y = 5'd14;

    localparam logic [4:0] PINKY_START_X = 5'd14;
    localparam logic [4:0] PINKY_START_Y = 5'd17;

    localparam logic [21:0] GHOST_MOVE_COUNT = 22'd3_360_000;

    logic [21:0] move_counter;

    logic [4:0] ghost_x   [0:1];
    logic [4:0] ghost_y   [0:1];
    logic [1:0] ghost_dir [0:1];

    logic [1:0] ghost_state [0:1];

    logic [1:0] ghost_can_move;
    logic [1:0] frightened_start;
    logic [1:0] pending_reverse;

    ghost_fsm blinky_fsm (
        .clk                  (clk),
        .reset                (reset),
        .game_state           (game_state),
        .power_pellet_active  (power_pellet_active),
        .ghost_eaten          (ghost_eaten[GHOST_BLINKY]),
        .global_ghost_mode    (global_ghost_mode),
        .ghost_state          (ghost_state[GHOST_BLINKY]),
        .ghost_can_move       (ghost_can_move[GHOST_BLINKY]),
        .dangerous_to_pacman  (dangerous_to_pacman[GHOST_BLINKY]),
        .vulnerable_to_pacman (vulnerable_to_pacman[GHOST_BLINKY]),
        .frightened_start     (frightened_start[GHOST_BLINKY])
    );

    ghost_fsm pinky_fsm (
        .clk                  (clk),
        .reset                (reset),
        .game_state           (game_state),
        .power_pellet_active  (power_pellet_active),
        .ghost_eaten          (ghost_eaten[GHOST_PINKY]),
        .global_ghost_mode    (global_ghost_mode),
        .ghost_state          (ghost_state[GHOST_PINKY]),
        .ghost_can_move       (ghost_can_move[GHOST_PINKY]),
        .dangerous_to_pacman  (dangerous_to_pacman[GHOST_PINKY]),
        .vulnerable_to_pacman (vulnerable_to_pacman[GHOST_PINKY]),
        .frightened_start     (frightened_start[GHOST_PINKY])
    );

    logic cur_ghost;

    logic [4:0] target_x;
    logic [4:0] target_y;

    ghost_target target_logic (
        .ghost_state (ghost_state[cur_ghost]),
        .ghost_id    (cur_ghost),
        .ghost_x     (ghost_x[cur_ghost]),
        .ghost_y     (ghost_y[cur_ghost]),
        .pacman_x    (pacman_x),
        .pacman_y    (pacman_y),
        .pacman_dir  (pacman_dir),
        .target_x    (target_x),
        .target_y    (target_y)
    );

    logic can_up;
    logic can_down;
    logic can_left;
    logic can_right;

    logic [4:0] next_x;
    logic [4:0] next_y;
    logic [1:0] next_dir;

    ghost_movement movement_logic (
        .ghost_can_move (ghost_can_move[cur_ghost]),
        .ghost_x        (ghost_x[cur_ghost]),
        .ghost_y        (ghost_y[cur_ghost]),
        .ghost_dir      (ghost_dir[cur_ghost]),
        .target_x       (target_x),
        .target_y       (target_y),
        .can_up         (can_up),
        .can_down       (can_down),
        .can_left       (can_left),
        .can_right      (can_right),
        .do_reverse     (pending_reverse[cur_ghost]),
        .next_x         (next_x),
        .next_y         (next_y),
        .next_dir       (next_dir)
    );

    typedef enum logic [1:0] {
        S_IDLE,
        S_CAPTURE,
        S_WRITE
    } scheduler_state_t;

    scheduler_state_t scheduler_state;

    logic [1:0] check_dir;
    logic       issued_oob;

    function automatic logic direction_oob (
        input logic [4:0] x,
        input logic [4:0] y,
        input logic [1:0] direction
    );
        begin
            case (direction)
                DIR_UP:
                    direction_oob = (y == 0);

                DIR_DOWN:
                    direction_oob = (y == GRID_MAX_Y);

                DIR_LEFT:
                    direction_oob = (x == 0);

                DIR_RIGHT:
                    direction_oob = (x == GRID_MAX_X);

                default:
                    direction_oob = 1'b1;
            endcase
        end
    endfunction

    function automatic logic [4:0] step_x (
        input logic [4:0] x,
        input logic [1:0] direction
    );
        begin
            case (direction)
                DIR_LEFT:
                    step_x = (x == 0) ? x : x - 1'b1;

                DIR_RIGHT:
                    step_x = (x == GRID_MAX_X) ? x : x + 1'b1;

                default:
                    step_x = x;
            endcase
        end
    endfunction

    function automatic logic [4:0] step_y (
        input logic [4:0] y,
        input logic [1:0] direction
    );
        begin
            case (direction)
                DIR_UP:
                    step_y = (y == 0) ? y : y - 1'b1;

                DIR_DOWN:
                    step_y = (y == GRID_MAX_Y) ? y : y + 1'b1;

                default:
                    step_y = y;
            endcase
        end
    endfunction

    assign blinky_x   = ghost_x[GHOST_BLINKY];
    assign blinky_y   = ghost_y[GHOST_BLINKY];
    assign blinky_dir = ghost_dir[GHOST_BLINKY];

    assign pinky_x    = ghost_x[GHOST_PINKY];
    assign pinky_y    = ghost_y[GHOST_PINKY];
    assign pinky_dir  = ghost_dir[GHOST_PINKY];

    integer i;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            scheduler_state <= S_IDLE;

            move_counter <= 22'd0;

            cur_ghost <= GHOST_BLINKY;
            check_dir <= DIR_UP;

            ghost_x[GHOST_BLINKY]   <= BLINKY_START_X;
            ghost_y[GHOST_BLINKY]   <= BLINKY_START_Y;
            ghost_dir[GHOST_BLINKY] <= DIR_LEFT;

            ghost_x[GHOST_PINKY]    <= PINKY_START_X;
            ghost_y[GHOST_PINKY]    <= PINKY_START_Y;
            ghost_dir[GHOST_PINKY]  <= DIR_LEFT;

            pending_reverse <= 2'b00;

            can_up    <= 1'b0;
            can_down  <= 1'b0;
            can_left  <= 1'b0;
            can_right <= 1'b0;

            ghost_rom_x <= 5'd0;
            ghost_rom_y <= 5'd0;

            issued_oob <= 1'b1;
        end else if (pacman_hit) begin
            scheduler_state <= S_IDLE;

            move_counter <= 22'd0;

            cur_ghost <= GHOST_BLINKY;
            check_dir <= DIR_UP;

            ghost_x[GHOST_BLINKY]   <= BLINKY_START_X;
            ghost_y[GHOST_BLINKY]   <= BLINKY_START_Y;
            ghost_dir[GHOST_BLINKY] <= DIR_LEFT;

            ghost_x[GHOST_PINKY]    <= PINKY_START_X;
            ghost_y[GHOST_PINKY]    <= PINKY_START_Y;
            ghost_dir[GHOST_PINKY]  <= DIR_LEFT;

            pending_reverse <= 2'b00;

            can_up    <= 1'b0;
            can_down  <= 1'b0;
            can_left  <= 1'b0;
            can_right <= 1'b0;

            ghost_rom_x <= 5'd0;
            ghost_rom_y <= 5'd0;

            issued_oob <= 1'b1;
        end else begin
            for (i = 0; i < 2; i = i + 1) begin
                if (frightened_start[i])
                    pending_reverse[i] <= 1'b1;
                else if ((scheduler_state == S_WRITE) &&
                         (cur_ghost == 1'(i)))
                    pending_reverse[i] <= 1'b0;
            end

            case (scheduler_state)
                S_IDLE: begin
                    if (move_counter == GHOST_MOVE_COUNT - 1'b1) begin
                        move_counter <= 22'd0;

                        cur_ghost <= GHOST_BLINKY;
                        check_dir <= DIR_UP;

                        can_up    <= 1'b0;
                        can_down  <= 1'b0;
                        can_left  <= 1'b0;
                        can_right <= 1'b0;

                        ghost_rom_x <=
                            step_x(ghost_x[GHOST_BLINKY], DIR_UP);

                        ghost_rom_y <=
                            step_y(ghost_y[GHOST_BLINKY], DIR_UP);

                        issued_oob <=
                            direction_oob(
                                ghost_x[GHOST_BLINKY],
                                ghost_y[GHOST_BLINKY],
                                DIR_UP
                            );

                        scheduler_state <= S_CAPTURE;
                    end else begin
                        move_counter <= move_counter + 1'b1;
                    end
                end

                S_CAPTURE: begin
                    case (check_dir)
                        DIR_UP:
                            can_up <= issued_oob
                                ? 1'b0
                                : ghost_rom_can_move;

                        DIR_DOWN:
                            can_down <= issued_oob
                                ? 1'b0
                                : ghost_rom_can_move;

                        DIR_LEFT:
                            can_left <= issued_oob
                                ? 1'b0
                                : ghost_rom_can_move;

                        DIR_RIGHT:
                            can_right <= issued_oob
                                ? 1'b0
                                : ghost_rom_can_move;

                        default: begin
                        end
                    endcase

                    if (check_dir == DIR_RIGHT) begin
                        scheduler_state <= S_WRITE;
                    end else begin
                        check_dir <= check_dir + 1'b1;

                        ghost_rom_x <=
                            step_x(
                                ghost_x[cur_ghost],
                                check_dir + 1'b1
                            );

                        ghost_rom_y <=
                            step_y(
                                ghost_y[cur_ghost],
                                check_dir + 1'b1
                            );

                        issued_oob <=
                            direction_oob(
                                ghost_x[cur_ghost],
                                ghost_y[cur_ghost],
                                check_dir + 1'b1
                            );
                    end
                end

                S_WRITE: begin
                    if (ghost_state[cur_ghost] == G_CAGED) begin
                        if (cur_ghost == GHOST_BLINKY) begin
                            ghost_x[cur_ghost]   <= BLINKY_START_X;
                            ghost_y[cur_ghost]   <= BLINKY_START_Y;
                            ghost_dir[cur_ghost] <= DIR_LEFT;
                        end else begin
                            ghost_x[cur_ghost]   <= PINKY_START_X;
                            ghost_y[cur_ghost]   <= PINKY_START_Y;
                            ghost_dir[cur_ghost] <= DIR_LEFT;
                        end
                    end else begin
                        ghost_x[cur_ghost]   <= next_x;
                        ghost_y[cur_ghost]   <= next_y;
                        ghost_dir[cur_ghost] <= next_dir;
                    end

                    if (cur_ghost == GHOST_PINKY) begin
                        scheduler_state <= S_IDLE;
                    end else begin
                        cur_ghost <= GHOST_PINKY;
                        check_dir <= DIR_UP;

                        can_up    <= 1'b0;
                        can_down  <= 1'b0;
                        can_left  <= 1'b0;
                        can_right <= 1'b0;

                        ghost_rom_x <=
                            step_x(ghost_x[GHOST_PINKY], DIR_UP);

                        ghost_rom_y <=
                            step_y(ghost_y[GHOST_PINKY], DIR_UP);

                        issued_oob <=
                            direction_oob(
                                ghost_x[GHOST_PINKY],
                                ghost_y[GHOST_PINKY],
                                DIR_UP
                            );

                        scheduler_state <= S_CAPTURE;
                    end
                end

                default: begin
                    scheduler_state <= S_IDLE;
                    move_counter    <= 22'd0;
                end
            endcase
        end
    end

endmodule