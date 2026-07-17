`timescale 1ns/1ps

module ghost_controller #(
    parameter int NUM_GHOSTS = 2,

    parameter int X_W = 6,
    parameter int Y_W = 6,

    parameter logic [X_W-1:0] GRID_MAX_X = 6'd27,
    parameter logic [Y_W-1:0] GRID_MAX_Y = 6'd30,

    parameter logic [X_W-1:0] BLINKY_START_X = 6'd14,
    parameter logic [Y_W-1:0] BLINKY_START_Y = 6'd14,

    parameter logic [X_W-1:0] PINKY_START_X  = 6'd14,
    parameter logic [Y_W-1:0] PINKY_START_Y  = 6'd17
)(
    input  logic clk,
    input  logic reset,

    input  logic move_tick,

    input  logic [1:0] game_state,
    input  logic       power_pellet_active,
    input  logic       global_ghost_mode,

    input  logic [X_W-1:0] pacman_x,
    input  logic [Y_W-1:0] pacman_y,
    input  logic [1:0]     pacman_dir,

    input  logic [NUM_GHOSTS-1:0] ghost_eaten,

    output logic [X_W-1:0] ghost_rom_x,
    output logic [Y_W-1:0] ghost_rom_y,
    input  logic           ghost_rom_can_move,

    output logic [X_W-1:0] blinky_x,
    output logic [Y_W-1:0] blinky_y,
    output logic [1:0]     blinky_dir,

    output logic [X_W-1:0] pinky_x,
    output logic [Y_W-1:0] pinky_y,
    output logic [1:0]     pinky_dir,

    output logic [NUM_GHOSTS-1:0] dangerous_to_pacman,
    output logic [NUM_GHOSTS-1:0] vulnerable_to_pacman
);

    localparam int GHOST_IDX_W = (NUM_GHOSTS <= 1) ? 1 : $clog2(NUM_GHOSTS);

    localparam logic [GHOST_IDX_W-1:0] GHOST_BLINKY = 'd0;
    localparam logic [GHOST_IDX_W-1:0] GHOST_PINKY  = 'd1;

    localparam logic [1:0] G_CAGED      = 2'd0;
    localparam logic [1:0] G_SCATTER    = 2'd1;
    localparam logic [1:0] G_CHASE      = 2'd2;
    localparam logic [1:0] G_FRIGHTENED = 2'd3;

    localparam logic [1:0] DIR_UP    = 2'd0;
    localparam logic [1:0] DIR_DOWN  = 2'd1;
    localparam logic [1:0] DIR_LEFT  = 2'd2;
    localparam logic [1:0] DIR_RIGHT = 2'd3;

    logic [X_W-1:0] ghost_x   [0:NUM_GHOSTS-1];
    logic [Y_W-1:0] ghost_y   [0:NUM_GHOSTS-1];
    logic [1:0]     ghost_dir [0:NUM_GHOSTS-1];

    logic [1:0] ghost_state    [0:NUM_GHOSTS-1];
    logic       ghost_can_move [0:NUM_GHOSTS-1];

    logic [NUM_GHOSTS-1:0] frightened_start;
    logic [NUM_GHOSTS-1:0] pending_reverse;

    genvar gi;

    generate
        for (gi = 0; gi < NUM_GHOSTS; gi = gi + 1) begin : GHOST_FSMS
            ghost_fsm u_ghost_fsm (
                .clk                 (clk),
                .reset               (reset),

                .game_state           (game_state),
                .power_pellet_active  (power_pellet_active),
                .ghost_eaten          (ghost_eaten[gi]),
                .global_ghost_mode    (global_ghost_mode),

                .ghost_state          (ghost_state[gi]),
                .ghost_can_move       (ghost_can_move[gi]),
                .dangerous_to_pacman  (dangerous_to_pacman[gi]),
                .vulnerable_to_pacman (vulnerable_to_pacman[gi]),
                .frightened_start     (frightened_start[gi])
            );
        end
    endgenerate

    logic [GHOST_IDX_W-1:0] cur_ghost;

    logic [X_W-1:0] target_x;
    logic [Y_W-1:0] target_y;

    ghost_target #(
        .X_W        (X_W),
        .Y_W        (Y_W),
        .GRID_MAX_X (GRID_MAX_X),
        .GRID_MAX_Y (GRID_MAX_Y)
    ) u_shared_target (
        .ghost_state (ghost_state[cur_ghost]),
        .ghost_id    (cur_ghost[0]),

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

    logic [X_W-1:0] next_x;
    logic [Y_W-1:0] next_y;
    logic [1:0]     next_dir;

    ghost_movement_brain #(
        .X_W (X_W),
        .Y_W (Y_W)
    ) u_shared_movement (
        .ghost_state    (ghost_state[cur_ghost]),
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
        S_WAIT_ROM,
        S_CAPTURE,
        S_WRITE
    } sched_state_t;

    sched_state_t sched_state;

    logic [1:0] check_dir;

    logic [X_W-1:0] ghost_rom_x_reg;
    logic [Y_W-1:0] ghost_rom_y_reg;
    logic           issued_oob;

    assign ghost_rom_x = ghost_rom_x_reg;
    assign ghost_rom_y = ghost_rom_y_reg;

    function automatic logic direction_oob;
        input logic [X_W-1:0] x;
        input logic [Y_W-1:0] y;
        input logic [1:0]     dir;
        begin
            case (dir)
                DIR_UP:    direction_oob = (y == 0);
                DIR_DOWN:  direction_oob = (y == GRID_MAX_Y);
                DIR_LEFT:  direction_oob = (x == 0);
                DIR_RIGHT: direction_oob = (x == GRID_MAX_X);
                default:   direction_oob = 1'b1;
            endcase
        end
    endfunction

    function automatic logic [X_W-1:0] step_x;
        input logic [X_W-1:0] x;
        input logic [1:0]     dir;
        begin
            case (dir)
                DIR_LEFT:  step_x = (x == 0)          ? x : x - 1'b1;
                DIR_RIGHT: step_x = (x == GRID_MAX_X) ? x : x + 1'b1;
                default:   step_x = x;
            endcase
        end
    endfunction

    function automatic logic [Y_W-1:0] step_y;
        input logic [Y_W-1:0] y;
        input logic [1:0]     dir;
        begin
            case (dir)
                DIR_UP:   step_y = (y == 0)          ? y : y - 1'b1;
                DIR_DOWN: step_y = (y == GRID_MAX_Y) ? y : y + 1'b1;
                default:  step_y = y;
            endcase
        end
    endfunction

    task automatic capture_can_move;
        input logic [1:0] dir;
        input logic       value;
        begin
            case (dir)
                DIR_UP:    can_up    <= value;
                DIR_DOWN:  can_down  <= value;
                DIR_LEFT:  can_left  <= value;
                DIR_RIGHT: can_right <= value;
                default: ;
            endcase
        end
    endtask

    task automatic issue_rom_read;
        input logic [GHOST_IDX_W-1:0] ghost_idx;
        input logic [1:0]             dir;
        begin
            ghost_rom_x_reg <= step_x(ghost_x[ghost_idx], dir);
            ghost_rom_y_reg <= step_y(ghost_y[ghost_idx], dir);

            issued_oob <= direction_oob(
                ghost_x[ghost_idx],
                ghost_y[ghost_idx],
                dir
            );
        end
    endtask

    assign blinky_x   = ghost_x[GHOST_BLINKY];
    assign blinky_y   = ghost_y[GHOST_BLINKY];
    assign blinky_dir = ghost_dir[GHOST_BLINKY];

    assign pinky_x    = ghost_x[GHOST_PINKY];
    assign pinky_y    = ghost_y[GHOST_PINKY];
    assign pinky_dir  = ghost_dir[GHOST_PINKY];

    integer i;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sched_state <= S_IDLE;

            cur_ghost <= GHOST_BLINKY;
            check_dir <= DIR_UP;

            ghost_x[GHOST_BLINKY]   <= BLINKY_START_X;
            ghost_y[GHOST_BLINKY]   <= BLINKY_START_Y;
            ghost_dir[GHOST_BLINKY] <= DIR_LEFT;

            ghost_x[GHOST_PINKY]    <= PINKY_START_X;
            ghost_y[GHOST_PINKY]    <= PINKY_START_Y;
            ghost_dir[GHOST_PINKY]  <= DIR_LEFT;

            pending_reverse <= '0;

            can_up    <= 1'b0;
            can_down  <= 1'b0;
            can_left  <= 1'b0;
            can_right <= 1'b0;

            ghost_rom_x_reg <= '0;
            ghost_rom_y_reg <= '0;
            issued_oob      <= 1'b1;
        end else begin

            for (i = 0; i < NUM_GHOSTS; i = i + 1) begin
                if (frightened_start[i]) begin
                    pending_reverse[i] <= 1'b1;
                end else if ((sched_state == S_WRITE) && (i == cur_ghost)) begin
                    pending_reverse[i] <= 1'b0;
                end
            end

            case (sched_state)

                S_IDLE: begin
                    if (move_tick) begin
                        cur_ghost <= GHOST_BLINKY;
                        check_dir <= DIR_UP;

                        can_up    <= 1'b0;
                        can_down  <= 1'b0;
                        can_left  <= 1'b0;
                        can_right <= 1'b0;

                        issue_rom_read(GHOST_BLINKY, DIR_UP);

                        sched_state <= S_WAIT_ROM;
                    end
                end

                S_WAIT_ROM: begin
                    sched_state <= S_CAPTURE;
                end

                S_CAPTURE: begin
                    capture_can_move(
                        check_dir,
                        issued_oob ? 1'b0 : ghost_rom_can_move
                    );

                    if (check_dir == DIR_RIGHT) begin
                        sched_state <= S_WRITE;
                    end else begin
                        check_dir <= check_dir + 1'b1;

                        issue_rom_read(
                            cur_ghost,
                            check_dir + 1'b1
                        );

                        sched_state <= S_WAIT_ROM;
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

                    if (cur_ghost == NUM_GHOSTS - 1) begin
                        sched_state <= S_IDLE;
                    end else begin
                        cur_ghost <= cur_ghost + 1'b1;
                        check_dir <= DIR_UP;

                        can_up    <= 1'b0;
                        can_down  <= 1'b0;
                        can_left  <= 1'b0;
                        can_right <= 1'b0;

                        issue_rom_read(cur_ghost + 1'b1, DIR_UP);

                        sched_state <= S_WAIT_ROM;
                    end
                end

                default: begin
                    sched_state <= S_IDLE;
                end

            endcase
        end
    end

endmodule