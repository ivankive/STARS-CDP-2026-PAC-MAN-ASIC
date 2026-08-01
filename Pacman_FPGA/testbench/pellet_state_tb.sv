`timescale 1ns/1ps

module pellet_state_tb;

    logic       clk;
    logic       reset;
    logic       clear;
    logic       set_en;
    logic [7:0] set_index;
    logic [7:0] rd_index_a;
    logic       rd_bit_a;
    logic [7:0] rd_index_b;
    logic       rd_bit_b;

    int pass_count;
    int fail_count;

    pellet_state dut (
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .set_en(set_en),
        .set_index(set_index),
        .rd_index_a(rd_index_a),
        .rd_bit_a(rd_bit_a),
        .rd_index_b(rd_index_b),
        .rd_bit_b(rd_bit_b)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic check(input string name, input logic cond);
        if (cond) begin
            pass_count++;
            $display("PASS: %s", name);
        end else begin
            fail_count++;
            $display("FAIL: %s (a=%b b=%b)", name, rd_bit_a, rd_bit_b);
        end
    endtask

    task automatic sample;
        @(posedge clk);
        #1;
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        reset      = 1'b1;
        clear      = 1'b0;
        set_en     = 1'b0;
        set_index  = 8'd0;
        rd_index_a = 8'd0;
        rd_index_b = 8'd1;

        $dumpfile("waves/pellet_state.vcd");
        $dumpvars(0, pellet_state_tb);

        sample();
        @(negedge clk);
        reset = 1'b0;
        sample();
        check("reset clears bits", (rd_bit_a === 1'b0) && (rd_bit_b === 1'b0));

        @(negedge clk);
        set_en     = 1'b1;
        set_index  = 8'd10;
        rd_index_a = 8'd10;
        sample();
        check("same-cycle bypass sets rd_a", rd_bit_a === 1'b1);
        @(negedge clk);
        set_en = 1'b0;
        sample();
        check("bit stays eaten", rd_bit_a === 1'b1);

        rd_index_b = 8'd10;
        #1;
        check("port b sees eaten", rd_bit_b === 1'b1);

        rd_index_a = 8'd11;
        #1;
        check("other index still clear", rd_bit_a === 1'b0);

        @(negedge clk);
        set_en    = 1'b1;
        set_index = 8'd200; // out of range
        sample();
        @(negedge clk);
        set_en = 1'b0;
        rd_index_a = 8'd200;
        #1;
        check("oob write ignored / read 0", rd_bit_a === 1'b0);

        @(negedge clk);
        clear = 1'b1;
        sample();
        rd_index_a = 8'd10;
        #1;
        check("clear restores uneaten", rd_bit_a === 1'b0);
        @(negedge clk);
        clear = 1'b0;

        $display("\npellet_state_tb: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count != 0) $fatal(1);
        $finish;
    end

endmodule
