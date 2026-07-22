module clock_div (
    input logic clk,
    input logic rst,
    output logic clk_div
);

    logic [23:0] count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= '0;
            ce <= 1'b0;
        end else begin
            if (count == 24'd3360000) begin
                count <= '0;
                ce <= 1'b1;
            end else begin
                count <= count + 1'b1;
                ce <= 1'b0;
            end
        end
    end

endmodule