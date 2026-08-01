`timescale 1ns/1ps

module ghost_controller_tb;

    logic       clk;
    logic       reset;
    logic [1:0] game_state;
    logic       spawn_reset;
    logic       power_pellet_active;
    logic       global_ghost_mode;

    logic [4:0] pacman_x, pacman_y;
    logic [1:0] pacman_dir;
    logic       pacman_hit;
    logic [1:0] ghost_eaten;

    logic [4:0] ghost_rom_x, ghost_rom_y;
    logic       ghost_rom_valid;
    logic       ghost_rom_can_move;

    logic [4:0] blinky_x, blinky_y;
    logic [1:0] blinky_dir;
    logic [4:0] pinky_x, pinky_y;
    logic [1:0] pinky_dir;
    logic [1:0] dangerous_to_pacman;
    logic [1:0] vulnerable_to_pacman;

    int pass_count;
    int fail_count;

    localparam logic [1:0] GAME_STARTING = 2'd0;
    localparam logic [1:0] GAME_PLAYING  = 2'd1;

    // Open maze: every queried tile is walkable and immediately valid.
    assign ghost_rom_valid    = 1'b1;
    assign ghost_rom_can_move = 1'b1;

    ghost_controller dut (
        .clk(clk),
        .reset(reset),
        .game_state(game_state),
        .spawn_reset(spawn_reset),
        .power_pellet_active(power_pellet_active),
        .global_ghost_mode(global_ghost_mode),
        .pacman_x(pacman_x),
        .pacman_y(pacman_y),
        .pacman_dir(pacman_dir),
        .pacman_hit(pacman_hit),
        .ghost_eaten(ghost_eaten),
        .ghost_rom_x(ghost_rom_x),
        .ghost_rom_y(ghost_rom_y),
        .ghost_rom_valid(ghost_rom_valid),
        .ghost_rom_can_move(ghost_rom_can_move),
        .blinky_x(blinky_x),
        .blinky_y(blinky_y),
        .blinky_dir(blinky_dir),
        .pinky_x(pinky_x),
        .pinky_y(pinky_y),
        .pinky_dir(pinky_dir),
        .dangerous_to_pacman(dangerous_to_pacman),
        .vulnerable_to_pacman(vulnerable_to_pacman)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic check(input string name, input logic cond);
        if (cond) begin
            pass_count++;
            $display("PASS: %s", name);
        end else begin
            fail_count++;
            $display("FAIL: %s (B=%0d,%0d P=%0d,%0d)",
                     name, blinky_x, blinky_y, pinky_x, pinky_y);
        end
    endtask

    task automatic tick(input int n = 1);
        repeat (n) @(posedge clk);
    endtask

    initial begin
        pass_count           = 0;
        fail_count           = 0;
        reset                = 1'b1;
        game_state           = GAME_STARTING;
        spawn_reset          = 1'b0;
        power_pellet_active  = 1'b0;
        global_ghost_mode    = 1'b0;
        pacman_x             = 5'd11;
        pacman_y             = 5'd19;
        pacman_dir           = 2'd3;
        pacman_hit           = 1'b0;
        ghost_eaten          = 2'b00;

        $dumpfile("waves/ghost_controller.vcd");
        $dumpvars(0, ghost_controller_tb);

        tick(2);
        reset = 1'b0;
        tick(1);
        check("reset Blinky start", (blinky_x === 5'd11) && (blinky_y === 5'd13));
        check("reset Pinky start",  (pinky_x  === 5'd12) && (pinky_y  === 5'd13));
        check("reset facing left",  (blinky_dir === 2'd1) && (pinky_dir === 2'd1));

        // Leave STARTING and play; ghosts should leave cage and move.
        game_state = GAME_PLAYING;
        tick(40);
        check("Blinky left start while playing",
              (blinky_x !== 5'd11) || (blinky_y !== 5'd13));
        check("dangerous while scatter", dangerous_to_pacman !== 2'b00);

        // spawn_reset snaps both ghosts home.
        spawn_reset = 1'b1;
        tick(1);
        spawn_reset = 1'b0;
        check("spawn_reset Blinky", (blinky_x === 5'd11) && (blinky_y === 5'd13));
        check("spawn_reset Pinky",  (pinky_x  === 5'd12) && (pinky_y  === 5'd13));

        // Move again, then pacman_hit restores spawn.
        tick(40);
        pacman_hit = 1'b1;
        tick(1);
        pacman_hit = 1'b0;
        check("pacman_hit Blinky home", (blinky_x === 5'd11) && (blinky_y === 5'd13));
        check("pacman_hit Pinky home",  (pinky_x  === 5'd12) && (pinky_y  === 5'd13));

        // Power pellet makes ghosts vulnerable.
        tick(20);
        power_pellet_active = 1'b1;
        tick(2);
        check("vulnerable under power", vulnerable_to_pacman !== 2'b00);

        $display("\nghost_controller_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count != 0) $fatal(1);
        $finish;
    end

endmodule
