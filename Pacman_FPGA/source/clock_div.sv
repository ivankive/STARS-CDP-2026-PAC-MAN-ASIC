module clock_div (
    input logic clk,   // 25 MHz system clock (from clock_40_to_25)
    input logic rst,
    output logic clk_div
);

    // 25_000_000 / 60 - 1 = 416_666 → single-cycle pulse at 60 Hz
    localparam logic [18:0] TERMINAL = 19'd416666;

    logic [18:0] count;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            count   <= '0;
            clk_div <= 1'b0;
        end else begin
            if (count == TERMINAL) begin
                count   <= '0;
                clk_div <= 1'b1;
            end else begin
                count   <= count + 1'b1;
                clk_div <= 1'b0;
            end
        end
    end

endmodule