module pp_timer (
    input logic pp_collision,
    input logic clk,
    input logic rst,
    output logic pp_active
);

    logic [7:0] timer; // assuming a 60 hz clock input

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pp_active <= 1'b0;
            timer     <= 8'b0;
        end else if (pp_collision) begin
            pp_active <= 1'b1;
            timer     <= 8'b0;
        end else if (pp_active) begin
            if (timer == 8'd179) begin // 180/60 = 3 second active
                pp_active <= 1'b0;
                timer     <= 8'b0;
            end else begin
                timer <= timer + 1'b1;
            end
        end
    end

endmodule
