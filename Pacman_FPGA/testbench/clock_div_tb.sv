`timescale 1ns/1ps

module clock_div_tb;

    logic clk;
    logic rst;
    logic clk_div;

    int pass_count;
    int fail_count;
    int high_count;
    int i;

    // Matches DUT threshold: pulse when count == 418749
    localparam int DIV_PERIOD = 418750;

    clock_div dut (
        .clk(clk),
        .rst(rst),
        .clk_div(clk_div)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic check(input string name, input logic cond);
        if (cond) begin
            pass_count++;
            $display("PASS: %s", name);
        end else begin
            fail_count++;
            $display("FAIL: %s (clk_div=%b)", name, clk_div);
        end
    endtask

    task automatic tick(input int n = 1);
        repeat (n) @(posedge clk);
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst        = 1'b1;

        // Skip full VCD: ~840k cycles would create a huge dump
        $dumpfile("waves/clock_div.vcd");

        tick(2);
        #1;
        check("async reset clears clk_div", clk_div === 1'b0);

        rst = 1'b0;
        tick(1);
        #1;
        check("idle before first pulse", clk_div === 1'b0);

        // One pulse every DIV_PERIOD cycles; sample mid-period then at edge
        tick(DIV_PERIOD - 2);
        #1;
        check("still low just before pulse", clk_div === 1'b0);

        tick(1);
        #1;
        check("pulse on divider wrap", clk_div === 1'b1);

        tick(1);
        #1;
        check("pulse is single-cycle", clk_div === 1'b0);

        // Second period
        tick(DIV_PERIOD - 1);
        #1;
        check("second pulse", clk_div === 1'b1);

        tick(1);
        #1;
        check("second pulse clears", clk_div === 1'b0);

        // Async reset mid-count
        tick(1000);
        rst = 1'b1;
        #1;
        check("async reset mid-count", clk_div === 1'b0);
        rst = 1'b0;

        // After reset, must wait full period again
        high_count = 0;
        for (i = 0; i < DIV_PERIOD; i++) begin
            tick(1);
            #1;
            if (clk_div)
                high_count++;
        end
        check("exactly one pulse in next full period", high_count == 1);

        $display("\nclock_div_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        $finish;
    end

endmodule
