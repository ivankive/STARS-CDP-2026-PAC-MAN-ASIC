// pellet_state
//
// The only writable maze memory in the design: one bit per collectible
// (288 total), set when Pac-Man eats it. Replaces the 2048-bit writable
// maze_bram. New game = synchronous clear of the whole array in one cycle;
// there is no ROM-to-RAM reload any more.
//
// Two combinational read ports:
//   port A - collision logic (has the pellet at this index been eaten?)
//   port B - VGA (suppress drawing of eaten pellets)
// Both ports forward a same-cycle write so a freshly eaten pellet
// disappears without any stale-frame window.

module pellet_state (
    input  logic       clk,
    input  logic       reset,

    input  logic       clear,        // synchronous clear-all (new game)

    input  logic       set_en,       // mark pellet as eaten
    input  logic [8:0] set_index,

    input  logic [8:0] rd_index_a,   // collision
    output logic       rd_bit_a,

    input  logic [8:0] rd_index_b,   // VGA
    output logic       rd_bit_b
);

    localparam int NUM_PELLETS = 288;

    logic [NUM_PELLETS-1:0] eaten;

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            eaten <= '0;
        else if (clear)
            eaten <= '0;
        else if (set_en && (set_index < 9'(NUM_PELLETS)))
            eaten[set_index] <= 1'b1;
    end

    // Reads with write forwarding.
    always_comb begin
        rd_bit_a = (rd_index_a < 9'(NUM_PELLETS)) ? eaten[rd_index_a] : 1'b0;
        if (set_en && (set_index == rd_index_a))
            rd_bit_a = 1'b1;

        rd_bit_b = (rd_index_b < 9'(NUM_PELLETS)) ? eaten[rd_index_b] : 1'b0;
        if (set_en && (set_index == rd_index_b))
            rd_bit_b = 1'b1;
    end

endmodule
