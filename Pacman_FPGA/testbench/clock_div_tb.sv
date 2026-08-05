`timescale 1ns/1ps

module clock_div_tb;

    logic clk;
    logic rst;
    logic clk_div;

    int pass_count;
    int fail_count;

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

    // Plant count just before the terminal value, then let the DUT advance.
    task automatic arm_near_terminal;
        @(negedge clk);
        force dut.count = 19'd416665;
        @(posedge clk);
        release dut.count;
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst        = 1'b1;

        $dumpfile("waves/clock_div.vcd");
        $dumpvars(0, clock_div_tb);

        tick(2);
        check("async reset clears pulse", clk_div === 1'b0);
        rst = 1'b0;
        tick(5);
        check("idle stays low", clk_div === 1'b0);

        arm_near_terminal();
        #1;
        check("count now 416666, pulse still low", clk_div === 1'b0);
        tick(1);
        #1;
        check("terminal count pulses high", clk_div === 1'b1);
        tick(1);
        #1;
        check("pulse is single-cycle", clk_div === 1'b0);

        arm_near_terminal();
        tick(1);
        #1;
        check("second pulse high", clk_div === 1'b1);
        tick(1);
        #1;
        check("second pulse clears", clk_div === 1'b0);

        rst = 1'b1;
        #1;
        check("async reset mid-run", clk_div === 1'b0);

        $display("\nclock_div_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count != 0) $fatal(1);
        $finish;
    end

endmodule
