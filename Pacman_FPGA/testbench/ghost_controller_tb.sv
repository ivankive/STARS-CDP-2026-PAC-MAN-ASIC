`timescale 1ns/1ps

module ghost_controller_tb;

    logic       clk;
    logic       reset;
    logic [1:0] game_state;
    logic       power_pellet_active;
    logic       global_ghost_mode;
    logic [4:0] pacman_x, pacman_y;
    logic [1:0] pacman_dir;
    logic       pacman_hit;
    logic [1:0] ghost_eaten;

    logic [4:0] ghost_rom_x, ghost_rom_y;
    logic       ghost_rom_can_move;

    logic [4:0] blinky_x, blinky_y;
    logic [1:0] blinky_dir;
    logic [4:0] pinky_x, pinky_y;
    logic [1:0] pinky_dir;
    logic [1:0] dangerous_to_pacman;
    logic [1:0] vulnerable_to_pacman;
    logic [9:0] score;

    int pass_count;
    int fail_count;
    int timeout;

    localparam logic [1:0] GAME_STARTING = 2'd0;
    localparam logic [1:0] GAME_PLAYING  = 2'd1;

    localparam logic [1:0] DIR_LEFT  = 2'd1;

    localparam logic [4:0] BLINKY_START_X = 5'd13;
    localparam logic [4:0] BLINKY_START_Y = 5'd14;
    localparam logic [4:0] PINKY_START_X  = 5'd14;
    localparam logic [4:0] PINKY_START_Y  = 5'd14;

    // Open maze stub: anything in-bounds is walkable
    always_comb begin
        ghost_rom_can_move = (ghost_rom_x < 5'd28) && (ghost_rom_y < 5'd31);
    end

    ghost_controller dut (
        .clk(clk),
        .reset(reset),
        .game_state(game_state),
        .power_pellet_active(power_pellet_active),
        .global_ghost_mode(global_ghost_mode),
        .pacman_x(pacman_x),
        .pacman_y(pacman_y),
        .pacman_dir(pacman_dir),
        .pacman_hit(pacman_hit),
        .ghost_eaten(ghost_eaten),
        .ghost_rom_x(ghost_rom_x),
        .ghost_rom_y(ghost_rom_y),
        .ghost_rom_can_move(ghost_rom_can_move),
        .blinky_x(blinky_x),
        .blinky_y(blinky_y),
        .blinky_dir(blinky_dir),
        .pinky_x(pinky_x),
        .pinky_y(pinky_y),
        .pinky_dir(pinky_dir),
        .dangerous_to_pacman(dangerous_to_pacman),
        .vulnerable_to_pacman(vulnerable_to_pacman),
        .score(score)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic check(input string name, input logic cond);
        if (cond) begin
            pass_count++;
            $display("PASS: %s", name);
        end else begin
            fail_count++;
            $display("FAIL: %s (bx=%0d by=%0d px=%0d py=%0d dang=%b vuln=%b)",
                     name, blinky_x, blinky_y, pinky_x, pinky_y,
                     dangerous_to_pacman, vulnerable_to_pacman);
        end
    endtask

    task automatic tick(input int n = 1);
        repeat (n) @(posedge clk);
    endtask

    // One full dual-ghost move: counter arm + 4 dir checks + write per ghost
    task automatic wait_move_cycle;
        tick(12);
    endtask

    initial begin
        pass_count           = 0;
        fail_count           = 0;
        reset                = 1'b1;
        game_state           = GAME_STARTING;
        power_pellet_active  = 1'b0;
        global_ghost_mode    = 1'b0;
        pacman_x             = 5'd6;
        pacman_y             = 5'd23;
        pacman_dir           = 2'd3;
        pacman_hit           = 1'b0;
        ghost_eaten          = 2'b00;

        $dumpfile("waves/ghost_controller.vcd");
        $dumpvars(0, ghost_controller_tb);

        tick(2);
        #1;
        check("reset blinky spawn",
              (blinky_x === BLINKY_START_X) && (blinky_y === BLINKY_START_Y) &&
              (blinky_dir === DIR_LEFT));
        check("reset pinky spawn",
              (pinky_x === PINKY_START_X) && (pinky_y === PINKY_START_Y) &&
              (pinky_dir === DIR_LEFT));
        check("caged not dangerous", dangerous_to_pacman === 2'b00);

        reset = 1'b0;
        tick(2);

        // Still starting: stay caged at spawn through a move cycle
        wait_move_cycle();
        #1;
        check("starting keeps blinky caged",
              (blinky_x === BLINKY_START_X) && (blinky_y === BLINKY_START_Y));
        check("starting keeps pinky caged",
              (pinky_x === PINKY_START_X) && (pinky_y === PINKY_START_Y));

        // Enter play: FSMs leave cage on next edge
        game_state = GAME_PLAYING;
        tick(2);
        #1;
        check("playing makes ghosts dangerous", dangerous_to_pacman === 2'b11);
        check("not vulnerable yet", vulnerable_to_pacman === 2'b00);

        // Allow a few move cycles; positions should leave the cage
        tick(40);
        #1;
        check("blinky left cage",
              (blinky_x !== BLINKY_START_X) || (blinky_y !== BLINKY_START_Y));
        check("pinky left cage",
              (pinky_x !== PINKY_START_X) || (pinky_y !== PINKY_START_Y));

        // ROM address is driven during capture
        check("rom addr in range",
              (ghost_rom_x < 5'd28) && (ghost_rom_y < 5'd31));

        // Frightened mode
        power_pellet_active = 1'b1;
        tick(2);
        #1;
        check("frightened vulnerable", vulnerable_to_pacman === 2'b11);
        check("frightened not dangerous", dangerous_to_pacman === 2'b00);

        // Eat blinky -> returns to cage on subsequent write while caged
        ghost_eaten = 2'b01;
        tick(1);
        ghost_eaten = 2'b00;
        tick(20);
        #1;
        check("eaten blinky respawns",
              (blinky_x === BLINKY_START_X) && (blinky_y === BLINKY_START_Y));

        power_pellet_active = 1'b0;
        tick(2);

        // Pac-Man hit resets both ghosts
        pacman_x = 5'd1;
        pacman_y = 5'd1;
        tick(30);
        pacman_hit = 1'b1;
        tick(1);
        #1;
        check("hit resets blinky",
              (blinky_x === BLINKY_START_X) && (blinky_y === BLINKY_START_Y));
        check("hit resets pinky",
              (pinky_x === PINKY_START_X) && (pinky_y === PINKY_START_Y));
        pacman_hit = 1'b0;

        $display("\nghost_controller_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        $finish;
    end

endmodule
