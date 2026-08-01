`timescale 1ns/1ps

module game_fsm_tb;

    logic       clk;
    logic       reset;
    logic       map_rst;
    logic       reload_done;
    logic [1:0] lives;
    logic [8:0] pellets;
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
        .map_rst(map_rst),
        .reload_done(reload_done),
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

    task automatic cycle;
        @(negedge clk);
    endtask

    task automatic sample;
        @(posedge clk);
        #1;
    endtask

    initial begin
        pass_count  = 0;
        fail_count  = 0;
        reset       = 1'b1;
        map_rst     = 1'b0;
        reload_done = 1'b0;
        lives       = 2'd3;
        pellets     = 9'd288;
        inputs      = 4'b0000;

        $dumpfile("waves/game_fsm.vcd");
        $dumpvars(0, game_fsm_tb);

        sample();
        sample();
        cycle();
        reset = 1'b0;
        sample();
        check("reset -> STARTING", game_state === GAME_STARTING);

        cycle();
        reload_done = 1'b1;
        sample();
        check("reload without input stays STARTING", game_state === GAME_STARTING);

        cycle();
        inputs = 4'b0001;
        sample();
        check("reload+input -> PLAYING", game_state === GAME_PLAYING);
        cycle();
        reload_done = 1'b0;
        inputs      = 4'b0000;

        cycle();
        lives = 2'd0;
        sample();
        check("lives==0 -> OVER", game_state === GAME_OVER);

        cycle();
        inputs = 4'b1000;
        sample();
        cycle();
        inputs = 4'b0000;
        check("input from OVER -> STARTING", game_state === GAME_STARTING);

        cycle();
        lives       = 2'd3;
        pellets     = 9'd10;
        reload_done = 1'b1;
        inputs      = 4'b0010;
        sample();
        cycle();
        reload_done = 1'b0;
        inputs      = 4'b0000;
        check("reload again -> PLAYING", game_state === GAME_PLAYING);

        cycle();
        pellets = 9'd0;
        sample();
        check("pellets==0 -> WIN", game_state === GAME_WIN);

        cycle();
        map_rst = 1'b1;
        sample();
        cycle();
        map_rst = 1'b0;
        check("map_rst from WIN -> STARTING", game_state === GAME_STARTING);

        cycle();
        pellets     = 9'd5;
        lives       = 2'd2;
        reload_done = 1'b1;
        inputs      = 4'b0100;
        sample();
        cycle();
        reload_done = 1'b0;
        inputs      = 4'b0000;
        check("playing again", game_state === GAME_PLAYING);

        cycle();
        map_rst = 1'b1;
        sample();
        cycle();
        map_rst = 1'b0;
        check("map_rst from PLAYING -> STARTING", game_state === GAME_STARTING);

        cycle();
        reload_done = 1'b1;
        inputs      = 4'b0001;
        sample();
        cycle();
        reload_done = 1'b0;
        inputs      = 4'b0000;
        cycle();
        reset = 1'b1;
        sample();
        cycle();
        reset = 1'b0;
        sample();
        check("sync reset -> STARTING", game_state === GAME_STARTING);

        $display("\ngame_fsm_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        $finish;
    end

endmodule
