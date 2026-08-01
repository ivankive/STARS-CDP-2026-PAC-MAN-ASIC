`timescale 1ns/1ps

module vga_counter_tb;

    logic       clk;
    logic       rst;
    logic       hsync;
    logic       vsync;
    logic [9:0] hcount;
    logic [9:0] vcount;
    logic       video_on;

    int pass_count;
    int fail_count;

    localparam int H_VISIBLE = 640;
    localparam int H_FRONT   = 16;
    localparam int H_SYNC    = 96;
    localparam int H_TOTAL   = 800;
    localparam int V_VISIBLE = 480;
    localparam int V_FRONT   = 10;
    localparam int V_SYNC    = 2;

    vga_counter dut (
        .clk(clk),
        .rst(rst),
        .hsync(hsync),
        .vsync(vsync),
        .hcount(hcount),
        .vcount(vcount),
        .video_on(video_on)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic check(input string name, input logic cond);
        if (cond) begin
            pass_count++;
            $display("PASS: %s", name);
        end else begin
            fail_count++;
            $display("FAIL: %s (h=%0d v=%0d hs=%b vs=%b von=%b)",
                     name, hcount, vcount, hsync, vsync, video_on);
        end
    endtask

    task automatic tick(input int n = 1);
        repeat (n) @(posedge clk);
        #1;
    endtask

    // Wait until counters match after NBA settles
    task automatic wait_hv(input int h, input int v);
        while (!((hcount == h[9:0]) && (vcount == v[9:0]))) begin
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst        = 1'b1;

        $dumpfile("waves/vga_counter.vcd");
        $dumpvars(0, vga_counter_tb);

        tick(2);
        check("reset h/v zero", (hcount === 0) && (vcount === 0));
        check("reset video_on", video_on === 1'b1);
        check("reset hsync high", hsync === 1'b1);
        check("reset vsync high", vsync === 1'b1);

        rst = 1'b0;
        tick(100);
        check("mid visible video_on", video_on === 1'b1);
        check("hcount advanced", hcount == 10'd100);

        wait_hv(H_VISIBLE - 1, 0);
        check("last visible pixel video_on", video_on === 1'b1);

        tick(1);
        check("h=640 video off", (hcount === 10'(H_VISIBLE)) && (video_on === 1'b0));

        wait_hv(H_VISIBLE + H_FRONT, 0);
        check("hsync assert start", hsync === 1'b0);

        wait_hv(H_VISIBLE + H_FRONT + H_SYNC, 0);
        check("hsync deassert", hsync === 1'b1);

        wait_hv(0, 1);
        check("line wrap to v=1", (hcount === 0) && (vcount === 1));

        wait_hv(0, V_VISIBLE);
        check("enter v=480 blank", (vcount === 10'(V_VISIBLE)) && (video_on === 1'b0));

        wait_hv(0, V_VISIBLE + V_FRONT);
        check("vsync assert", vsync === 1'b0);

        wait_hv(0, V_VISIBLE + V_FRONT + V_SYNC);
        check("vsync deassert", vsync === 1'b1);

        wait_hv(0, 0);
        check("frame wrap to 0,0", (hcount === 0) && (vcount === 0));

        $display("\nvga_counter_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        $finish;
    end

endmodule
