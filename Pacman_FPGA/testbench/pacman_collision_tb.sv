`timescale 1ns/1ps

module pacman_collision_tb;

    logic       clk;
    logic       reset;
    logic       game_tick;
    logic       game_running;

    logic [4:0] pacman_x;
    logic [4:0] pacman_y;
    logic [4:0] blinky_x;
    logic [4:0] blinky_y;
    logic [4:0] pinky_x;
    logic [4:0] pinky_y;

    logic [1:0] dangerous_to_pacman;
    logic [1:0] vulnerable_to_pacman;
    logic       power_pellet_active;

    logic [4:0] x_central;
    logic [4:0] y_central;
    logic       write_en;
    logic [1:0] rdata_central;

    logic       pellet_eaten;
    logic       power_pellet_eaten;
    logic       pacman_hit;
    logic [9:0] score;
    logic [1:0] ghost_eaten;
    logic [1:0] lives;
    logic [8:0] pellets;

    int pass_count;
    int fail_count;
    int guard;

    localparam logic [1:0] TILE_BLANK        = 2'b00;
    localparam logic [1:0] TILE_PELLET       = 2'b10;
    localparam logic [1:0] TILE_POWER_PELLET = 2'b11;

    logic [1:0] stub_tile;

    assign rdata_central = stub_tile;

    pacman_collision dut (
        .clk(clk),
        .reset(reset),
        .game_tick(game_tick),
        .game_running(game_running),
        .pacman_x(pacman_x),
        .pacman_y(pacman_y),
        .blinky_x(blinky_x),
        .blinky_y(blinky_y),
        .pinky_x(pinky_x),
        .pinky_y(pinky_y),
        .dangerous_to_pacman(dangerous_to_pacman),
        .vulnerable_to_pacman(vulnerable_to_pacman),
        .power_pellet_active(power_pellet_active),
        .x_central(x_central),
        .y_central(y_central),
        .write_en(write_en),
        .rdata_central(rdata_central),
        .pellet_eaten(pellet_eaten),
        .power_pellet_eaten(power_pellet_eaten),
        .pacman_hit(pacman_hit),
        .score(score),
        .ghost_eaten(ghost_eaten),
        .lives(lives),
        .pellets(pellets)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic check(input string name, input logic cond);
        if (cond) begin
            pass_count++;
            $display("PASS: %s", name);
        end else begin
            fail_count++;
            $display("FAIL: %s (score=%0d lives=%0d hit=%b ge=%b we=%b pe=%b ppe=%b)",
                     name, score, lives, pacman_hit, ghost_eaten, write_en,
                     pellet_eaten, power_pellet_eaten);
        end
    endtask

    task automatic sample;
        @(posedge clk);
        #1;
    endtask

    task automatic wait_write_en;
        guard = 0;
        while ((write_en !== 1'b1) && (guard < 20)) begin
            sample();
            guard++;
        end
    endtask

    // Pulse game_tick for one cycle; sample while it is high so clears are visible
    // before gameplay can re-assert the same flags.
    task automatic pulse_game_tick_and_sample;
        @(negedge clk);
        game_tick = 1'b1;
        @(posedge clk);
        #1;
    endtask

    task automatic release_game_tick;
        @(negedge clk);
        game_tick = 1'b0;
        sample();
    endtask

    task automatic clear_ghosts;
        blinky_x             = 5'd0;
        blinky_y             = 5'd0;
        pinky_x              = 5'd1;
        pinky_y              = 5'd1;
        dangerous_to_pacman  = 2'b00;
        vulnerable_to_pacman = 2'b00;
        power_pellet_active  = 1'b0;
    endtask

    initial begin
        pass_count            = 0;
        fail_count            = 0;
        reset                 = 1'b1;
        game_tick             = 1'b0;
        game_running          = 1'b0;
        pacman_x              = 5'd5;
        pacman_y              = 5'd5;
        clear_ghosts();
        stub_tile             = TILE_BLANK;

        $dumpfile("waves/pacman_collision.vcd");
        $dumpvars(0, pacman_collision_tb);

        sample();
        sample();
        @(negedge clk);
        reset = 1'b0;
        sample();
        check("reset lives=3", lives === 2'd3);
        check("reset pellets=288", pellets === 9'd288);
        check("reset score=0", score === 10'd0);
        check("central addr tracks pacman", (x_central === pacman_x) && (y_central === pacman_y));

        stub_tile    = TILE_PELLET;
        game_running = 1'b0;
        repeat (4) sample();
        check("idle no write_en", write_en === 1'b0);
        check("idle pellets unchanged", pellets === 9'd288);

        @(negedge clk);
        game_running = 1'b1;
        stub_tile    = TILE_PELLET;
        wait_write_en();
        check("pellet write_en", write_en === 1'b1);
        check("pellet_eaten pulse", pellet_eaten === 1'b1);
        check("pellets decremented", pellets === 9'd287);
        check("score +2", score === 10'd2);
        sample();
        check("pellet_eaten clears", pellet_eaten === 1'b0);

        @(negedge clk);
        stub_tile = TILE_POWER_PELLET;
        wait_write_en();
        check("power write_en", write_en === 1'b1);
        check("power_pellet_eaten set", power_pellet_eaten === 1'b1);
        check("pellets after power", pellets === 9'd286);
        check("score +15", score === 10'd17);

        // Leave pellet tile blank so later checks are not disturbed
        @(negedge clk);
        stub_tile = TILE_BLANK;
        clear_ghosts();
        pulse_game_tick_and_sample();
        check("game_tick clears power flag", power_pellet_eaten === 1'b0);
        release_game_tick();

        @(negedge clk);
        blinky_x            = pacman_x;
        blinky_y            = pacman_y;
        dangerous_to_pacman = 2'b01;
        sample();
        check("dangerous blinky hits", pacman_hit === 1'b1);
        check("life lost", lives === 2'd2);
        sample();
        sample();
        check("hit held until game_tick", pacman_hit === 1'b1);

        // Move Blinky away before clear so hit cannot re-assert
        @(negedge clk);
        clear_ghosts();
        pulse_game_tick_and_sample();
        check("game_tick clears hit", pacman_hit === 1'b0);
        release_game_tick();

        @(negedge clk);
        pinky_x              = pacman_x;
        pinky_y              = pacman_y;
        vulnerable_to_pacman = 2'b10;
        sample();
        check("pinky eaten flag", ghost_eaten === 2'b10);
        check("score +50 for ghost", score === 10'd67);
        sample();
        sample();
        check("no double ghost score", score === 10'd67);

        @(negedge clk);
        clear_ghosts();
        pulse_game_tick_and_sample();
        check("game_tick clears ghost_eaten", ghost_eaten === 2'b00);
        release_game_tick();

        @(negedge clk);
        blinky_x            = pacman_x;
        blinky_y            = pacman_y;
        power_pellet_active = 1'b1;
        sample();
        check("eat blinky under power", ghost_eaten[0] === 1'b1);
        check("score +50 blinky", score === 10'd117);

        $display("\npacman_collision_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        $finish;
    end

endmodule
