module initial_maze_rom #(
    parameter int GRID_W = 28,
    parameter int GRID_H = 36,
    parameter int X_W = 6,
    parameter int Y_W = 6,
    parameter string INIT_FILE = "maze.mem",
    parameter logic WALL_BIT = 1'b1

)(
    input  logic clk,
    input  logic reset,

    // Port A: Pac-Man movement checker

    input  logic [X_W-1:0] pac_x,
    input  logic [Y_W-1:0] pac_y,
    output logic           pac_is_wall,
    output logic           pac_can_move,
 
    // Port B: Ghost movement checker

    input  logic [X_W-1:0] ghost_x,
    input  logic [Y_W-1:0] ghost_y,
    output logic           ghost_is_wall,
    output logic           ghost_can_move
);

    logic [GRID_W-1:0] maze_rows [0:GRID_H-1];
    initial begin
        $readmemb(INIT_FILE, maze_rows);
    end

    function automatic logic get_tile_bit;
        input logic [X_W-1:0] x;
        input logic [Y_W-1:0] y;
        begin
            if ((x >= GRID_W) || (y >= GRID_H)) begin
                get_tile_bit = WALL_BIT;
            end else begin
                get_tile_bit = maze_rows[y][GRID_W - 1 - x];
            end
        end
    endfunction

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pac_is_wall   <= 1'b1;
            pac_can_move  <= 1'b0;
            ghost_is_wall <= 1'b1;
            ghost_can_move <= 1'b0;

        end else begin
            pac_is_wall   <= (get_tile_bit(pac_x, pac_y) == WALL_BIT);
            pac_can_move  <= (get_tile_bit(pac_x, pac_y) != WALL_BIT);
            ghost_is_wall <= (get_tile_bit(ghost_x, ghost_y) == WALL_BIT);
            ghost_can_move <= (get_tile_bit(ghost_x, ghost_y) != WALL_BIT);
        end
    end
endmodule