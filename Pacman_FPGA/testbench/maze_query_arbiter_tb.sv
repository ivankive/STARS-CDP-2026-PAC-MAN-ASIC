`timescale 1ns/1ps

module maze_query_arbiter_tb;

    logic       clk;
    logic       reset;

    logic       vga_active;
    logic [4:0] vga_x, vga_y;
    logic [1:0] rdata_vga;

    logic [4:0] col_x, col_y;
    logic       col_valid;
    logic       col_collectible;
    logic       col_is_power;
    logic [7:0] col_pellet_index;

    logic [4:0] pac_x, pac_y;
    logic       pac_valid;
    logic       pac_can_move;

    logic [4:0] ghost_x, ghost_y;
    logic       ghost_valid;
    logic       ghost_can_move;

    logic [4:0] rom_x, rom_y;
    logic [1:0] rom_tile;
    logic       rom_collectible;
    logic [7:0] rom_pellet_index;
    logic       rom_can_move_pac;
    logic       rom_can_move_ghost;

    logic [7:0] pellet_rd_index;
    logic       pellet_rd_bit;

    int pass_count;
    int fail_count;

    // Tiny stub ROM: (5,5)=pellet idx 3, (6,6)=power idx 4, else path/wall.
    always_comb begin
        rom_tile           = 2'b00;
        rom_collectible    = 1'b0;
        rom_pellet_index   = 8'd0;
        rom_can_move_pac   = 1'b1;
        rom_can_move_ghost = 1'b1;

        if ((rom_x == 5'd5) && (rom_y == 5'd5)) begin
            rom_tile         = 2'b10;
            rom_collectible  = 1'b1;
            rom_pellet_index = 8'd3;
        end else if ((rom_x == 5'd6) && (rom_y == 5'd6)) begin
            rom_tile         = 2'b11;
            rom_collectible  = 1'b1;
            rom_pellet_index = 8'd4;
        end else if (rom_x == 5'd0) begin
            rom_tile           = 2'b01;
            rom_can_move_pac   = 1'b0;
            rom_can_move_ghost = 1'b0;
        end
    end

    assign pellet_rd_bit = (pellet_rd_index == 8'd3); // treat idx 3 as eaten

    maze_query_arbiter dut (
        .clk(clk),
        .reset(reset),
        .vga_active(vga_active),
        .vga_x(vga_x),
        .vga_y(vga_y),
        .rdata_vga(rdata_vga),
        .col_x(col_x),
        .col_y(col_y),
        .col_valid(col_valid),
        .col_collectible(col_collectible),
        .col_is_power(col_is_power),
        .col_pellet_index(col_pellet_index),
        .pac_x(pac_x),
        .pac_y(pac_y),
        .pac_valid(pac_valid),
        .pac_can_move(pac_can_move),
        .ghost_x(ghost_x),
        .ghost_y(ghost_y),
        .ghost_valid(ghost_valid),
        .ghost_can_move(ghost_can_move),
        .rom_x(rom_x),
        .rom_y(rom_y),
        .rom_tile(rom_tile),
        .rom_collectible(rom_collectible),
        .rom_pellet_index(rom_pellet_index),
        .rom_can_move_pac(rom_can_move_pac),
        .rom_can_move_ghost(rom_can_move_ghost),
        .pellet_rd_index(pellet_rd_index),
        .pellet_rd_bit(pellet_rd_bit)
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

    task automatic sample;
        @(posedge clk);
        #1;
    endtask

    initial begin
        pass_count  = 0;
        fail_count  = 0;
        reset       = 1'b1;
        vga_active  = 1'b0;
        vga_x       = 5'd5;
        vga_y       = 5'd5;
        col_x       = 5'd6;
        col_y       = 5'd6;
        pac_x       = 5'd1;
        pac_y       = 5'd1;
        ghost_x     = 5'd0;
        ghost_y     = 5'd1;

        $dumpfile("waves/maze_query_arbiter.vcd");
        $dumpvars(0, maze_query_arbiter_tb);

        sample();
        @(negedge clk);
        reset = 1'b0;

        // With VGA idle, round-robin should serve col/pac/ghost.
        sample(); // RR_COL
        check("col served", col_valid === 1'b1);
        check("col is power", col_is_power === 1'b1);
        check("col pellet idx", col_pellet_index === 8'd4);

        sample(); // RR_PAC
        check("pac served", pac_valid === 1'b1);
        check("pac can move", pac_can_move === 1'b1);

        sample(); // RR_GHO
        check("ghost served", ghost_valid === 1'b1);
        check("ghost blocked on wall", ghost_can_move === 1'b0);

        // VGA priority: eaten pellet displays as path.
        @(negedge clk);
        vga_active = 1'b1;
        sample();
        check("vga suppresses eaten pellet", rdata_vga === 2'b00);
        check("vga drives pellet rd index", pellet_rd_index === 8'd3);

        @(negedge clk);
        vga_x = 5'd6;
        vga_y = 5'd6;
        sample();
        check("vga shows uneaten power", rdata_vga === 2'b11);

        // Moving a requester address drops valid until re-served.
        @(negedge clk);
        vga_active = 1'b0;
        pac_x = 5'd2;
        #1;
        check("pac invalid after move", pac_valid === 1'b0);
        repeat (4) sample();
        check("pac valid after re-serve", pac_valid === 1'b1);

        $display("\nmaze_query_arbiter_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count != 0) $fatal(1);
        $finish;
    end

endmodule
