`default_nettype none

// clock_40_to_25
//
// hz100 arrives as a 40 MHz reference. VGA and the rest of the game logic
// need a 25 MHz clock (640 × 480 pixel clock).
//
// Exact integer divide is impossible (40/25 = 1.6), so this uses a phase
// accumulator whose MSB is the output clock:
//   f_out = f_in * (STEP / 2^WIDTH) = 40 MHz * (160 / 256) = 25 MHz
// Edges have ±1 input-cycle jitter; average frequency is exact.

module clock_40_to_25 (
    input  logic clk_40,  // 40 MHz (hz100 port)
    input  logic rst,
    output logic clk_25
);

    localparam logic [7:0] STEP = 8'd160;  // 160/256 * 40 MHz = 25 MHz

    logic [7:0] phase;

    always_ff @(posedge clk_40 or posedge rst) begin
        if (rst)
            phase <= 8'd0;
        else
            phase <= phase + STEP;
    end

    assign clk_25 = phase[7];

endmodule

`default_nettype wire
