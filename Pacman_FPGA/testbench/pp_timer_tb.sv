`timescale 1ns/1ps

module pp_timer_tb;

    logic pp_collision;
    logic clk;
    logic rst;
    logic pp_active;

    int pass_count;
    int fail_count;

    pp_timer dut (
        .pp_collision(pp_collision),
        .clk(clk),
        .rst(rst),
        .pp_active(pp_active)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic check(input string name, input logic cond);
        if (cond) begin
            pass_count++;
            $display("PASS: %s", name);
        end else begin
            fail_count++;
            $display("FAIL: %s", name);
        end
    endtask

    task automatic tick(input int n = 1);
        repeat (n) @(posedge clk);
    endtask

    initial begin
        pass_count   = 0;
        fail_count   = 0;
        pp_collision = 1'b0;
        rst          = 1'b1;

        $dumpfile("waves/pp_timer.vcd");
        $dumpvars(0, pp_timer_tb);

        tick(2);
        rst = 1'b0;
        tick(1);
        check("reset clears pp_active", pp_active === 1'b0);

        // Start power-pellet window
        pp_collision = 1'b1;
        tick(1);
        pp_collision = 1'b0;
        check("pp_collision asserts pp_active", pp_active === 1'b1);

        // Active for 179 more idle cycles after the start cycle, then clears
        tick(179);
        check("still active at timer==179", pp_active === 1'b1);
        tick(1);
        check("clears after 180 active cycles", pp_active === 1'b0);

        // Retrigger while active restarts timer
        pp_collision = 1'b1;
        tick(1);
        pp_collision = 1'b0;
        tick(50);
        check("mid-window still active", pp_active === 1'b1);
        pp_collision = 1'b1;
        tick(1);
        pp_collision = 1'b0;
        tick(179);
        check("retrig still active near end", pp_active === 1'b1);
        tick(1);
        check("retrig expires after full window", pp_active === 1'b0);

        // Async reset while active
        pp_collision = 1'b1;
        tick(1);
        pp_collision = 1'b0;
        check("active before async reset", pp_active === 1'b1);
        rst = 1'b1;
        #1;
        check("async reset clears pp_active", pp_active === 1'b0);
        rst = 1'b0;
        tick(1);

        $display("\npp_timer_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count != 0) $fatal(1);
        $finish;
    end

endmodule
