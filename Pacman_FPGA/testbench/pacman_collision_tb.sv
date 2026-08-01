`timescale 1ns/1ps

module pacman_collision_tb;

    logic       clk;
    logic       reset;
    logic       game_tick;
    logic       game_running;
    logic       game_starting;

    logic [4:0] pacman_x, pacman_y;
    logic [4:0] blinky_x, blinky_y;
    logic [4:0] pinky_x, pinky_y;

    logic [1:0] dangerous_to_pacman;
    logic [1:0] vulnerable_to_pacman;
    logic       power_pellet_active;

    logic [4:0] col_x, col_y;
    logic       col_valid;
    logic       col_collectible;
    logic       col_is_power;
    logic [7:0] col_pellet_index;

    logic       pellet_already_eaten;
    logic       pellet_set_en;
    logic [7:0] pellet_set_index;

    logic       pellet_eaten;
    logic       power_pellet_eaten;
    logic       pacman_hit;
    logic [1:0] ghost_eaten;
    logic [1:0] lives;
    logic [7:0] pellets;

    int pass_count;
    int fail_count;
    int guard;

    // Simple eaten-bit model for the DUT's write/read handshake.
    logic [255:0] eaten_bits;

    always_ff @(posedge clk or posedge reset) begin
        if (reset || game_starting)
            eaten_bits <= '0;
        else if (pellet_set_en)
            eaten_bits[pellet_set_index] <= 1'b1;
    end

    always_comb begin
        pellet_already_eaten = eaten_bits[col_pellet_index];
        if (pellet_set_en && (pellet_set_index == col_pellet_index))
            pellet_already_eaten = 1'b1;
    end

    pacman_collision dut (
        .clk(clk),
        .reset(reset),
        .game_tick(game_tick),
        .game_running(game_running),
        .game_starting(game_starting),
        .pacman_x(pacman_x),
        .pacman_y(pacman_y),
        .blinky_x(blinky_x),
        .blinky_y(blinky_y),
        .pinky_x(pinky_x),
        .pinky_y(pinky_y),
        .dangerous_to_pacman(dangerous_to_pacman),
        .vulnerable_to_pacman(vulnerable_to_pacman),
        .power_pellet_active(power_pellet_active),
        .col_x(col_x),
        .col_y(col_y),
        .col_valid(col_valid),
        .col_collectible(col_collectible),
        .col_is_power(col_is_power),
        .col_pellet_index(col_pellet_index),
        .pellet_already_eaten(pellet_already_eaten),
        .pellet_set_en(pellet_set_en),
        .pellet_set_index(pellet_set_index),
        .pellet_eaten(pellet_eaten),
        .power_pellet_eaten(power_pellet_eaten),
        .pacman_hit(pacman_hit),
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
            $display("FAIL: %s (lives=%0d hit=%b ge=%b se=%b pe=%b ppe=%b pellets=%0d)",
                     name, lives, pacman_hit, ghost_eaten, pellet_set_en,
                     pellet_eaten, power_pellet_eaten, pellets);
        end
    endtask

    task automatic sample;
        @(posedge clk);
        #1;
    endtask

    task automatic wait_set_en;
        guard = 0;
        while ((pellet_set_en !== 1'b1) && (guard < 20)) begin
            sample();
            guard++;
        end
    endtask

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
        game_starting         = 1'b0;
        pacman_x              = 5'd5;
        pacman_y              = 5'd5;
        clear_ghosts();
        col_valid             = 1'b0;
        col_collectible       = 1'b0;
        col_is_power          = 1'b0;
        col_pellet_index      = 8'd0;

        $dumpfile("waves/pacman_collision.vcd");
        $dumpvars(0, pacman_collision_tb);

        sample();
        sample();
        @(negedge clk);
        reset = 1'b0;
        sample();
        check("reset lives=3", lives === 2'd3);
        check("reset pellets=186", pellets === 8'd186);
        check("col addr tracks pacman", (col_x === pacman_x) && (col_y === pacman_y));

        col_valid       = 1'b1;
        col_collectible = 1'b1;
        col_is_power    = 1'b0;
        col_pellet_index = 8'd7;
        game_running    = 1'b0;
        repeat (4) sample();
        check("idle no set_en", pellet_set_en === 1'b0);
        check("idle pellets unchanged", pellets === 8'd186);

        @(negedge clk);
        game_running = 1'b1;
        wait_set_en();
        check("pellet set_en", pellet_set_en === 1'b1);
        check("pellet set_index", pellet_set_index === 8'd7);
        check("pellet_eaten pulse", pellet_eaten === 1'b1);
        check("pellets decremented", pellets === 8'd185);
        sample();
        check("pellet_eaten clears", pellet_eaten === 1'b0);
        check("already eaten blocks re-eat", pellet_set_en === 1'b0);

        @(negedge clk);
        col_pellet_index = 8'd8;
        col_is_power     = 1'b1;
        wait_set_en();
        check("power set_en", pellet_set_en === 1'b1);
        check("power_pellet_eaten set", power_pellet_eaten === 1'b1);
        check("pellets after power", pellets === 8'd184);

        @(negedge clk);
        col_collectible = 1'b0;
        col_is_power    = 1'b0;
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

        @(negedge clk);
        clear_ghosts();
        game_starting = 1'b1;
        sample();
        check("game_starting restores pellets", pellets === 8'd186);
        check("game_starting restores lives", lives === 2'd3);
        game_starting = 1'b0;

        $display("\npacman_collision_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count != 0) $fatal(1);
        $finish;
    end

endmodule
