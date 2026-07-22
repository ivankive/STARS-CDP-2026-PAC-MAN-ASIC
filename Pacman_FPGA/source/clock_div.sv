module clock_div (
    input logic clk,
    input logic rst,
    output logic clk_div
);

    logic [21:0] count;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            count <= '0;
            clk_div <= 1'b0;
        end else begin
            if (count == 22'd3350000) begin
                count <= '0;
                clk_div <= 1'b1;
            end else begin
                count <= count + 1'b1;
                clk_div <= 1'b0;
            end
        end
    end

endmodule