`timescale 1ns/1ps

module game_fsm_tb;

    logic       clk;
    logic       reset;
    logic [1:0] lives;
    logic [7:0] pellets;
    logic [3:0] inputs;
    logic [1:0] game_state;

    int pass_count;
    int fail_count;

    localparam logic [1:0] GAME_STARTING = 2'd0;
    localparam logic [1:0] GAME_PLAYING  = 2'd1;
    localparam logic [1:0] GAME_OVER     = 2'd2;
    localparam logic [1:0] GAME_WIN      = 2'd3;

    game_fsm dut (
        .clk(clk),
        .reset(reset),
        .lives(lives),
        .pellets(pellets),
        .inputs(inputs),
        .game_state(game_state)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic check(input string name, input logic cond);
        if (cond) begin
            pass_count++;
            $display("PASS: %s", name);
        end else begin
            fail_count++;
            $display("FAIL: %s (game_state=%0d)", name, game_state);
        end
    endtask

    task automatic sample;
        @(posedge clk);
        #1;
    endtask

    // Hold inputs low long enough for start_armed (~5 cycles).
    task automatic wait_armed;
        inputs = 4'b0000;
        repeat (8) sample();
    endtask

    task automatic press_once;
        @(negedge clk);
        inputs = 4'b0001;
        sample();
        @(negedge clk);
        inputs = 4'b0000;
        sample();
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        reset      = 1'b1;
        lives      = 2'd3;
        pellets    = 8'd186;
        inputs     = 4'b0000;

        $dumpfile("waves/game_fsm.vcd");
        $dumpvars(0, game_fsm_tb);

        sample();
        sample();
        @(negedge clk);
        reset = 1'b0;
        sample();
        check("reset -> STARTING", game_state === GAME_STARTING);

        // Press before arming must be ignored.
        @(negedge clk);
        inputs = 4'b0001;
        sample();
        check("press before arm ignored", game_state === GAME_STARTING);
        wait_armed();
        check("still STARTING after release", game_state === GAME_STARTING);

        press_once();
        check("armed press -> PLAYING", game_state === GAME_PLAYING);

        @(negedge clk);
        lives = 2'd0;
        sample();
        check("lives==0 -> OVER", game_state === GAME_OVER);

        // Same held press must not chain OVER -> STARTING -> PLAYING.
        @(negedge clk);
        inputs = 4'b0010;
        sample();
        check("OVER press -> STARTING", game_state === GAME_STARTING);
        sample();
        sample();
        check("held press stays STARTING", game_state === GAME_STARTING);

        wait_armed();
        lives   = 2'd3;
        pellets = 8'd10;
        press_once();
        check("restart -> PLAYING", game_state === GAME_PLAYING);

        @(negedge clk);
        pellets = 8'd0;
        sample();
        check("pellets==0 -> WIN", game_state === GAME_WIN);

        press_once();
        check("WIN press -> STARTING", game_state === GAME_STARTING);
        sample();
        check("no bounce into PLAYING", game_state === GAME_STARTING);

        wait_armed();
        pellets = 8'd5;
        press_once();
        check("play again after WIN", game_state === GAME_PLAYING);

        @(negedge clk);
        reset = 1'b1;
        sample();
        @(negedge clk);
        reset = 1'b0;
        sample();
        check("sync reset -> STARTING", game_state === GAME_STARTING);

        $display("\ngame_fsm_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count != 0) $fatal(1);
        $finish;
    end

endmodule
