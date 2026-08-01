`timescale 1ns/1ps

module vga_draw_border_tb;

    logic [9:0] h_count;
    logic [9:0] v_count;
    logic       video_on;
    logic [2:0] input_rgb;
    logic [2:0] output_rgb;

    int pass_count;
    int fail_count;

    vga_draw_border dut (
        .h_count(h_count),
        .v_count(v_count),
        .video_on(video_on),
        .input_rgb(input_rgb),
        .output_rgb(output_rgb)
    );

    task automatic check(input string name, input logic cond);
        if (cond) begin
            pass_count++;
            $display("PASS: %s", name);
        end else begin
            fail_count++;
            $display("FAIL: %s (out=%b)", name, output_rgb);
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        h_count    = 10'd100;
        v_count    = 10'd100;
        video_on   = 1'b1;
        input_rgb  = 3'b101;

        $dumpfile("waves/vga_draw_border.vcd");
        $dumpvars(0, vga_draw_border_tb);

        #1;
        check("pass-through in playfield", output_rgb === 3'b101);

        video_on = 1'b0;
        #1;
        check("blank when video_off", output_rgb === 3'b000);

        video_on = 1'b1;
        h_count  = 10'd224;
        v_count  = 10'd100;
        #1;
        check("black right margin", output_rgb === 3'b000);

        h_count = 10'd100;
        v_count = 10'd320; // >= 288+24+8 = 320
        #1;
        check("black bottom margin", output_rgb === 3'b000);

        v_count = 10'd32; // between 8 and 64
        #1;
        check("black top band", output_rgb === 3'b000);

        // Score row gaps: v<8 and h in gap regions
        v_count = 10'd3;
        h_count = 10'd0;
        #1;
        check("black between score glyphs h=0", output_rgb === 3'b000);

        h_count = 10'd45;
        #1;
        check("black between score glyphs gap", output_rgb === 3'b000);

        h_count = 10'd80;
        #1;
        check("black right of score row", output_rgb === 3'b000);

        // Inside SCORE letter strip should pass through (h=4, v=3)
        h_count = 10'd4;
        v_count = 10'd3;
        input_rgb = 3'b111;
        #1;
        check("score letter strip pass-through", output_rgb === 3'b111);

        $display("\nvga_draw_border_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        $finish;
    end

endmodule
