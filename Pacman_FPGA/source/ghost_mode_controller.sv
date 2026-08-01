module ghost_mode_controller (
    input  logic clk,          // 60 Hz clock
    input  logic reset,
    input  logic game_active,

    output logic ghost_mode    // 0 = scatter, 1 = chase
);

    localparam logic MODE_SCATTER = 1'b0;
    localparam logic MODE_CHASE   = 1'b1;

    localparam logic [8:0] SCATTER_COUNT = 9'd419; // 7 seconds
    localparam logic [9:0] CHASE_COUNT   = 10'd1023; // 17 seconds

    logic [9:0] mode_counter;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            ghost_mode  <= MODE_SCATTER;
            mode_counter <= 10'd0;
        end else if (!game_active) begin
            ghost_mode   <= MODE_SCATTER;
            mode_counter <= 10'd0;
        end else begin
            case (ghost_mode)
                MODE_SCATTER: begin
                    if (mode_counter == SCATTER_COUNT - 1'b1) begin
                        ghost_mode   <= MODE_CHASE;
                        mode_counter <= 10'd0;
                    end else begin
                        mode_counter <= mode_counter + 1'b1;
                    end
                end

                MODE_CHASE: begin
                    if (mode_counter == CHASE_COUNT - 1'b1) begin
                        ghost_mode   <= MODE_SCATTER;
                        mode_counter <= 10'd0;
                    end else begin
                        mode_counter <= mode_counter + 1'b1;
                    end
                end

                default: begin
                    ghost_mode   <= MODE_SCATTER;
                    mode_counter <= 10'd0;
                end
            endcase
        end
    end

endmodule