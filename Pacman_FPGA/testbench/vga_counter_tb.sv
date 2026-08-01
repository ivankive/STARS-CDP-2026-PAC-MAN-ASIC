`timescale 1ns/1ps

module vga_counter_tb;

    logic       clk;
    logic       rst;
    logic       hsync;
    logic       vsync;
    logic [9:0] hcount;
    logic [9:0] vcount;
    logic       video_on;

    // Non-automatic temps for force statements (Icarus restriction).
    logic [9:0] force_h;
    logic [9:0] force_v;

    int pass_count;
    int fail_count;

    localparam int H_VISIBLE = 640;
    localparam int H_FRONT   = 16;
    localparam int H_TOTAL   = 800;
    localparam int V_VISIBLE = 480;
    localparam int V_FRONT   = 10;
    localparam int V_TOTAL   = 525;

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
            $display("FAIL: %s (h=%0d v=%0d hs=%b vs=%b vo=%b)",
                     name, hcount, vcount, hsync, vsync, video_on);
        end
    endtask

    task automatic tick(input int n = 1);
        repeat (n) @(posedge clk);
    endtask

    task automatic load_hv;
        @(negedge clk);
        force dut.hcount = force_h;
        force dut.vcount = force_v;
        @(posedge clk);
        release dut.hcount;
        release dut.vcount;
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst        = 1'b1;
        force_h    = '0;
        force_v    = '0;

        $dumpfile("waves/vga_counter.vcd");
        $dumpvars(0, vga_counter_tb);

        tick(2);
        check("reset h=0", hcount === 10'd0);
        check("reset v=0", vcount === 10'd0);
        check("reset video_on", video_on === 1'b1);
        check("reset hsync high", hsync === 1'b1);
        check("reset vsync high", vsync === 1'b1);

        rst = 1'b0;
        tick(1);
        check("advance h", hcount === 10'd1);

        force_h = 10'(H_VISIBLE - 2);
        force_v = 10'd0;
        load_hv();
        #1;
        check("near end still visible", video_on === 1'b1 && hcount === 10'(H_VISIBLE - 1));
        tick(1);
        #1;
        check("past visible video_off", video_on === 1'b0 && hcount === 10'(H_VISIBLE));

        force_h = 10'(H_VISIBLE + H_FRONT - 1);
        force_v = 10'd0;
        load_hv();
        #1;
        check("hsync low in sync", hsync === 1'b0);

        force_h = 10'(H_TOTAL - 2);
        force_v = 10'd5;
        load_hv();
        #1;
        check("pre-wrap h", hcount === 10'(H_TOTAL - 1));
        tick(1);
        #1;
        check("line wrap h->0", hcount === 10'd0);
        check("line wrap v+1", vcount === 10'd6);

        force_h = 10'd0;
        force_v = 10'(V_VISIBLE + V_FRONT);
        load_hv();
        #1;
        check("vsync low in sync", vsync === 1'b0);

        force_h = 10'(H_TOTAL - 2);
        force_v = 10'(V_TOTAL - 1);
        load_hv();
        #1;
        check("pre-frame-wrap", hcount === 10'(H_TOTAL - 1) && vcount === 10'(V_TOTAL - 1));
        tick(1);
        #1;
        check("frame wrap h->0", hcount === 10'd0);
        check("frame wrap v->0", vcount === 10'd0);

        $display("\nvga_counter_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count != 0) $fatal(1);
        $finish;
    end

endmodule
