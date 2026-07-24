`timescale 1ns/1ps

module ghost_mode_controller_tb;

    logic clk;
    logic reset;
    logic game_active;
    logic ghost_mode;

    int pass_count;
    int fail_count;

    localparam int SCATTER_COUNT = 419;
    localparam int CHASE_COUNT   = 1023;

    ghost_mode_controller dut (
        .clk(clk),
        .reset(reset),
        .game_active(game_active),
        .ghost_mode(ghost_mode)
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
        pass_count  = 0;
        fail_count  = 0;
        reset       = 1'b1;
        game_active = 1'b0;

        $dumpfile("waves/ghost_mode_controller.vcd");
        $dumpvars(0, ghost_mode_controller_tb);

        tick(2);
        reset = 1'b0;
        tick(1);
        check("reset leaves scatter", ghost_mode === 1'b0);

        // Inactive game forces scatter
        game_active = 1'b0;
        tick(5);
        check("inactive stays scatter", ghost_mode === 1'b0);

        // Scatter -> Chase after SCATTER_COUNT active cycles
        game_active = 1'b1;
        tick(SCATTER_COUNT - 1);
        check("still scatter just before switch", ghost_mode === 1'b0);
        tick(1);
        check("scatter->chase after 419 cycles", ghost_mode === 1'b1);

        // Chase -> Scatter after CHASE_COUNT active cycles
        tick(CHASE_COUNT - 1);
        check("still chase just before switch", ghost_mode === 1'b1);
        tick(1);
        check("chase->scatter after 1023 cycles", ghost_mode === 1'b0);

        // Mid-count pause resets to scatter
        tick(100);
        check("scatter again mid-count", ghost_mode === 1'b0);
        game_active = 1'b0;
        tick(1);
        check("pause forces scatter", ghost_mode === 1'b0);
        game_active = 1'b1;
        tick(SCATTER_COUNT);
        check("full scatter after resume", ghost_mode === 1'b1);

        // Async reset
        reset = 1'b1;
        #1;
        check("async reset to scatter", ghost_mode === 1'b0);
        reset = 1'b0;

        $display("\nghost_mode_controller_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        $finish;
    end

endmodule
