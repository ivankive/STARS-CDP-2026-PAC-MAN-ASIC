`timescale 1ns/1ps

module ghost_fsm_tb;

    logic       clk;
    logic       reset;
    logic [1:0] game_state;
    logic       power_pellet_active;
    logic       ghost_eaten;
    logic       global_ghost_mode;

    logic [1:0] ghost_state;
    logic       ghost_can_move;
    logic       dangerous_to_pacman;
    logic       vulnerable_to_pacman;
    logic       frightened_start;

    int pass_count;
    int fail_count;

    localparam logic [1:0] GAME_STARTING = 2'd0;
    localparam logic [1:0] GAME_PLAYING  = 2'd1;
    localparam logic [1:0] GAME_OVER     = 2'd2;

    localparam logic [1:0] G_CAGED      = 2'd0;
    localparam logic [1:0] G_SCATTER    = 2'd1;
    localparam logic [1:0] G_CHASE      = 2'd2;
    localparam logic [1:0] G_FRIGHTENED = 2'd3;

    ghost_fsm dut (
        .clk(clk),
        .reset(reset),
        .game_state(game_state),
        .power_pellet_active(power_pellet_active),
        .ghost_eaten(ghost_eaten),
        .global_ghost_mode(global_ghost_mode),
        .ghost_state(ghost_state),
        .ghost_can_move(ghost_can_move),
        .dangerous_to_pacman(dangerous_to_pacman),
        .vulnerable_to_pacman(vulnerable_to_pacman),
        .frightened_start(frightened_start)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic check(input string name, input logic cond);
        if (cond) begin
            pass_count++;
            $display("PASS: %s", name);
        end else begin
            fail_count++;
            $display("FAIL: %s (ghost_state=%0d fs=%b)", name, ghost_state, frightened_start);
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
        pass_count           = 0;
        fail_count           = 0;
        reset                = 1'b1;
        game_state           = GAME_STARTING;
        power_pellet_active  = 1'b0;
        ghost_eaten          = 1'b0;
        global_ghost_mode    = 1'b0;

        $dumpfile("waves/ghost_fsm.vcd");
        $dumpvars(0, ghost_fsm_tb);

        sample();
        sample();
        cycle();
        reset = 1'b0;
        sample();
        check("reset -> CAGED", ghost_state === G_CAGED);
        check("caged cannot move", ghost_can_move === 1'b0);
        check("caged not dangerous", dangerous_to_pacman === 1'b0);

        cycle();
        game_state        = GAME_OVER;
        global_ghost_mode = 1'b1;
        sample();
        sample();
        check("non-playing stays CAGED", ghost_state === G_CAGED);

        cycle();
        game_state        = GAME_PLAYING;
        global_ghost_mode = 1'b0;
        power_pellet_active = 1'b0;
        sample();
        check("caged -> SCATTER", ghost_state === G_SCATTER);
        check("scatter can move", ghost_can_move === 1'b1);
        check("scatter dangerous", dangerous_to_pacman === 1'b1);
        check("scatter not vulnerable", vulnerable_to_pacman === 1'b0);

        cycle();
        global_ghost_mode = 1'b1;
        sample();
        check("scatter -> CHASE", ghost_state === G_CHASE);
        check("chase dangerous", dangerous_to_pacman === 1'b1);

        cycle();
        power_pellet_active = 1'b1;
        sample();
        check("chase -> FRIGHTENED", ghost_state === G_FRIGHTENED);
        check("frightened_start pulse", frightened_start === 1'b1);
        check("frightened can move", ghost_can_move === 1'b1);
        check("frightened vulnerable", vulnerable_to_pacman === 1'b1);
        check("frightened not dangerous", dangerous_to_pacman === 1'b0);
        sample();
        check("frightened_start clears", frightened_start === 1'b0);

        sample();
        sample();
        sample();
        check("stay FRIGHTENED", ghost_state === G_FRIGHTENED);

        cycle();
        power_pellet_active = 1'b0;
        sample();
        check("frightened -> CHASE", ghost_state === G_CHASE);

        cycle();
        power_pellet_active = 1'b1;
        sample();
        check("again FRIGHTENED", ghost_state === G_FRIGHTENED);
        cycle();
        ghost_eaten = 1'b1;
        sample();
        cycle();
        ghost_eaten = 1'b0;
        check("eaten -> CAGED", ghost_state === G_CAGED);

        sample();
        sample();
        check("caged while pellet active", ghost_state === G_CAGED);

        cycle();
        power_pellet_active = 1'b0;
        global_ghost_mode   = 1'b0;
        sample();
        check("leave cage to SCATTER", ghost_state === G_SCATTER);

        cycle();
        power_pellet_active = 1'b1;
        sample();
        cycle();
        power_pellet_active = 1'b0;
        sample();
        check("frightened -> SCATTER", ghost_state === G_SCATTER);

        cycle();
        game_state = GAME_STARTING;
        sample();
        check("starting forces CAGED", ghost_state === G_CAGED);

        $display("\nghost_fsm_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count != 0) $fatal(1);
        $finish;
    end

endmodule
