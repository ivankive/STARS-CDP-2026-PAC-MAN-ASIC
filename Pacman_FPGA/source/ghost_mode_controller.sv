module ghost_mode_controller (
    input  logic clk,          // 25 MHz clock
    input  logic reset,
    input  logic game_active,

    output logic ghost_mode    // 0 = scatter, 1 = chase
);

    localparam logic MODE_SCATTER = 1'b0;
    localparam logic MODE_CHASE   = 1'b1;

    // 25 MHz timing counts
    localparam logic [28:0] SCATTER_COUNT = 29'd175_000_000;
    localparam logic [28:0] CHASE_COUNT   = 29'd500_000_000;

    logic [28:0] mode_counter;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            ghost_mode  <= MODE_SCATTER;
            mode_counter <= 29'd0;
        end else if (!game_active) begin
            ghost_mode   <= MODE_SCATTER;
            mode_counter <= 29'd0;
        end else begin
            case (ghost_mode)
                MODE_SCATTER: begin
                    if (mode_counter == SCATTER_COUNT - 1'b1) begin
                        ghost_mode   <= MODE_CHASE;
                        mode_counter <= 29'd0;
                    end else begin
                        mode_counter <= mode_counter + 1'b1;
                    end
                end

                MODE_CHASE: begin
                    if (mode_counter == CHASE_COUNT - 1'b1) begin
                        ghost_mode   <= MODE_SCATTER;
                        mode_counter <= 29'd0;
                    end else begin
                        mode_counter <= mode_counter + 1'b1;
                    end
                end

                default: begin
                    ghost_mode   <= MODE_SCATTER;
                    mode_counter <= 29'd0;
                end
            endcase
        end
    end

endmodule