`timescale 1ns/1ps

module ghost_mode_controller (
    input  logic clk,
    input  logic reset,

    input  logic game_running,
    input  logic tick_1hz,
    input  logic power_pellet_active,

    output logic global_ghost_mode
);

    // 0 = scatter, 1 = chase
    localparam logic MODE_SCATTER = 1'b0;
    localparam logic MODE_CHASE   = 1'b1;

    localparam logic [4:0] SCATTER_SECONDS = 5'd7;
    localparam logic [4:0] CHASE_SECONDS   = 5'd20;

    logic [4:0] mode_timer;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            global_ghost_mode <= MODE_SCATTER;
            mode_timer        <= 5'd0;
        end else if (!game_running) begin
            global_ghost_mode <= MODE_SCATTER;
            mode_timer        <= 5'd0;
        end else if (power_pellet_active) begin
            global_ghost_mode <= global_ghost_mode;
            mode_timer        <= mode_timer;
        end else if (tick_1hz) begin
            if (global_ghost_mode == MODE_SCATTER) begin
                if (mode_timer == SCATTER_SECONDS - 1'b1) begin
                    global_ghost_mode <= MODE_CHASE;
                    mode_timer        <= 5'd0;
                end else begin
                    mode_timer <= mode_timer + 1'b1;
                end
            end else begin
                if (mode_timer == CHASE_SECONDS - 1'b1) begin
                    global_ghost_mode <= MODE_SCATTER;
                    mode_timer        <= 5'd0;
                end else begin
                    mode_timer <= mode_timer + 1'b1;
                end
            end
        end
    end

endmodule
