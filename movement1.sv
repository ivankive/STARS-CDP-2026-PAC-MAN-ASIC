`default_nettype none

module top (
    input  logic hz100,
    input  logic reset,
    input  logic [20:0] pb,

    output logic [7:0] left, right,
                       ss7, ss6, ss5, ss4,
                       ss3, ss2, ss1, ss0,

    output logic red, green, blue,

    output logic [7:0] txdata,
    input  logic [7:0] rxdata,
    output logic txclk, rxclk,
    input  logic txready, rxready
);

    // x and y positions
    logic [13:0] xpos;
    logic [13:0] ypos;

    // direction enums
    typedef enum logic [1:0] {
        UP,
        LEFT,
        DOWN,
        RIGHT
    } dir_t;

    dir_t dir;

    // counter for clock divider
    logic [4:0] count;

    always_ff @(posedge hz100) begin
        if (reset) begin
            xpos <= 0;
            ypos <= 0;
            dir <= RIGHT;
            count <= 0;
        end
        else begin

            // last button pressed determines direction
            if (pb[6])
                dir <= UP;
            else if (pb[1])
                dir <= RIGHT;
            else if (pb[2])
                dir <= DOWN;
            else if (pb[3])
                dir <= LEFT;

            // move every 19 cycles
            if (count == 19) begin
                count <= 0;

                case (dir)

                    UP:
                        if (ypos < 9999)
                            ypos <= ypos + 1;

                    DOWN:
                        if (ypos > 0)
                            ypos <= ypos - 1;

                    LEFT:
                        if (xpos > 0)
                            xpos <= xpos - 1;

                    RIGHT:
                        if (xpos < 9999)
                            xpos <= xpos + 1;

                endcase
            end
            else
                count <= count + 1;
        end
    end

    // decimal digits
    logic [3:0] x0,x1,x2,x3;
    logic [3:0] y0,y1,y2,y3;
    
    bin14_to_bcd xbcd(
        .bin(xpos),
        .thousands(x3),
        .hundreds(x2),
        .tens(x1),
        .ones(x0)
    );
    
    bin14_to_bcd ybcd(
        .bin(ypos),
        .thousands(y3),
        .hundreds(y2),
        .tens(y1),
        .ones(y0)
    );

    sevenseg s0(x0, ss0);
    sevenseg s1(x1, ss1);
    sevenseg s2(x2, ss2);
    sevenseg s3(x3, ss3);

    sevenseg s4(y0, ss4);
    sevenseg s5(y1, ss5);
    sevenseg s6(y2, ss6);
    sevenseg s7(y3, ss7);

endmodule


// 7 segment decoder
module sevenseg(
    input  logic [3:0] digit,
    output logic [7:0] seg
);

always_comb begin
    case(digit)
        4'd0: seg = 8'b00111111;
        4'd1: seg = 8'b00000110;
        4'd2: seg = 8'b01011011;
        4'd3: seg = 8'b01001111;
        4'd4: seg = 8'b01100110;
        4'd5: seg = 8'b01101101;
        4'd6: seg = 8'b01111101;
        4'd7: seg = 8'b00000111;
        4'd8: seg = 8'b01111111;
        4'd9: seg = 8'b01101111;
        default: seg = 8'b11111111;
    endcase
end

endmodule

// ai generated decimal display

module bin14_to_bcd(
    input  logic [13:0] bin,
    output logic [3:0] thousands,
    output logic [3:0] hundreds,
    output logic [3:0] tens,
    output logic [3:0] ones
);

    integer i;
    logic [29:0] shift;

    always_comb begin
        shift = 30'd0;
        shift[13:0] = bin;

        for (i = 0; i < 14; i++) begin

            if (shift[17:14] >= 5)
                shift[17:14] += 3;

            if (shift[21:18] >= 5)
                shift[21:18] += 3;

            if (shift[25:22] >= 5)
                shift[25:22] += 3;

            if (shift[29:26] >= 5)
                shift[29:26] += 3;

            shift = shift << 1;
        end

        ones      = shift[17:14];
        tens      = shift[21:18];
        hundreds  = shift[25:22];
        thousands = shift[29:26];
    end

endmodule

`default_nettype wire