// maze_wall_pellet_rom
//
// Static, purely combinational maze description. Replaces initial_maze_rom
// and the writable maze_bram. One lookup port; sharing between requesters
// is handled by maze_query_arbiter.
//
// For any (x, y) it returns:
//   tile         - 2'b00 path, 2'b01 wall, 2'b10 pellet, 2'b11 power pellet
//                  (the tile as originally laid out; eaten state lives in
//                   pellet_state, not here)
//   collectible  - tile is a pellet or power pellet (== tile[1])
//   pellet_index - 0..287, unique per collectible tile. Computed as
//                  ROW_BASE[y] + popcount(collectibles in row y left of x).
//   can_move_pac / can_move_ghost - wall check plus the ghost-house door
//                  rules carried over from initial_maze_rom.
//
// No initial blocks: row data is a case-statement function so the ROM
// survives commercial synthesis (DC/Genus ignore initial blocks).

module maze_wall_pellet_rom (
    input  logic [4:0] x,
    input  logic [4:0] y,
    output logic [1:0] tile,
    output logic       collectible,
    output logic [8:0] pellet_index,
    output logic       can_move_pac,
    output logic       can_move_ghost
);

    localparam logic [1:0] PATH_TILE  = 2'b00;
    localparam logic [1:0] WALL_TILE  = 2'b01;

    // 28 tiles x 2 bits per row; x = 0 is the leftmost tile (bits [55:54]).
    function automatic logic [55:0] row_data(input logic [4:0] yy);
        case (yy)
            5'd0:  row_data = {28{2'b01}};
            5'd1:  row_data = 56'b01_10_10_10_10_10_10_10_10_10_10_10_10_01_01_10_10_10_10_10_10_10_10_10_10_10_10_01;
            5'd2:  row_data = 56'b01_10_01_01_01_01_10_01_01_01_01_01_10_01_01_10_01_01_01_01_01_10_01_01_01_01_10_01;
            5'd3:  row_data = 56'b01_10_01_01_01_01_10_01_01_01_01_01_10_01_01_10_01_01_01_01_01_10_01_01_01_01_10_01;
            5'd4:  row_data = 56'b01_11_01_01_01_01_10_01_01_01_01_01_10_01_01_10_01_01_01_01_01_10_01_01_01_01_11_01;
            5'd5:  row_data = 56'b01_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_01;
            5'd6:  row_data = 56'b01_10_01_01_01_01_10_01_01_10_01_01_01_01_01_01_01_01_10_01_01_10_01_01_01_01_10_01;
            5'd7:  row_data = 56'b01_10_01_01_01_01_10_01_01_10_01_01_01_01_01_01_01_01_10_01_01_10_01_01_01_01_10_01;
            5'd8:  row_data = 56'b01_10_10_10_10_10_10_01_01_10_10_10_10_01_01_10_10_10_10_01_01_10_10_10_10_10_10_01;
            5'd9:  row_data = 56'b01_01_01_01_01_01_10_01_01_01_01_01_10_01_01_10_01_01_01_01_01_10_01_01_01_01_01_01;
            5'd10: row_data = 56'b01_01_01_01_01_01_10_01_01_01_01_01_10_01_01_10_01_01_01_01_01_10_01_01_01_01_01_01;
            5'd11: row_data = 56'b01_01_01_01_01_01_10_01_01_10_10_10_10_10_10_10_10_10_10_01_01_10_01_01_01_01_01_01;
            5'd12: row_data = 56'b01_01_01_01_01_01_10_01_01_10_01_01_01_00_00_01_01_01_10_01_01_10_01_01_01_01_01_01;
            5'd13: row_data = 56'b01_01_01_01_01_01_10_01_01_10_01_00_00_00_00_00_00_01_10_01_01_10_01_01_01_01_01_01;
            5'd14: row_data = 56'b00_00_00_00_00_00_10_10_10_10_01_00_00_00_00_00_00_01_10_10_10_10_00_00_00_00_00_00;
            5'd15: row_data = 56'b01_01_01_01_01_01_10_01_01_10_01_00_00_00_00_00_00_01_10_01_01_10_01_01_01_01_01_01;
            5'd16: row_data = 56'b01_01_01_01_01_01_10_01_01_10_01_01_01_01_01_01_01_01_10_01_01_10_01_01_01_01_01_01;
            5'd17: row_data = 56'b01_01_01_01_01_01_10_01_01_10_10_10_10_10_10_10_10_10_10_01_01_10_01_01_01_01_01_01;
            5'd18: row_data = 56'b01_01_01_01_01_01_10_01_01_10_01_01_01_01_01_01_01_01_10_01_01_10_01_01_01_01_01_01;
            5'd19: row_data = 56'b01_01_01_01_01_01_10_01_01_10_01_01_01_01_01_01_01_01_10_01_01_10_01_01_01_01_01_01;
            5'd20: row_data = 56'b01_10_10_10_10_10_10_10_10_10_10_10_10_01_01_10_10_10_10_10_10_10_10_10_10_10_10_01;
            5'd21: row_data = 56'b01_10_01_01_01_01_10_01_01_01_01_01_10_01_01_10_01_01_01_01_01_10_01_01_01_01_10_01;
            5'd22: row_data = 56'b01_10_01_01_01_01_10_01_01_01_01_01_10_01_01_10_01_01_01_01_01_10_01_01_01_01_10_01;
            5'd23: row_data = 56'b01_11_10_10_01_01_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_01_01_10_10_11_01;
            5'd24: row_data = 56'b01_01_01_10_01_01_10_01_01_10_01_01_01_01_01_01_01_01_10_01_01_10_01_01_10_01_01_01;
            5'd25: row_data = 56'b01_01_01_10_01_01_10_01_01_10_01_01_01_01_01_01_01_01_10_01_01_10_01_01_10_01_01_01;
            5'd26: row_data = 56'b01_10_10_10_10_10_10_01_01_10_10_10_10_01_01_10_10_10_10_01_01_10_10_10_10_10_10_01;
            5'd27: row_data = 56'b01_10_01_01_01_01_01_01_01_01_01_01_10_01_01_10_01_01_01_01_01_01_01_01_01_01_10_01;
            5'd28: row_data = 56'b01_10_01_01_01_01_01_01_01_01_01_01_10_01_01_10_01_01_01_01_01_01_01_01_01_01_10_01;
            5'd29: row_data = 56'b01_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_01;
            5'd30: row_data = {28{2'b01}};
            default: row_data = {28{2'b01}};
        endcase
    endfunction

    // Number of collectibles in all rows above row y (generated from the
    // map data by gen_rom_data.py; total is 288).
    function automatic logic [8:0] row_base(input logic [4:0] yy);
        case (yy)
            5'd0:  row_base = 9'd0;
            5'd1:  row_base = 9'd0;
            5'd2:  row_base = 9'd24;
            5'd3:  row_base = 9'd30;
            5'd4:  row_base = 9'd36;
            5'd5:  row_base = 9'd42;
            5'd6:  row_base = 9'd68;
            5'd7:  row_base = 9'd74;
            5'd8:  row_base = 9'd80;
            5'd9:  row_base = 9'd100;
            5'd10: row_base = 9'd104;
            5'd11: row_base = 9'd108;
            5'd12: row_base = 9'd120;
            5'd13: row_base = 9'd124;
            5'd14: row_base = 9'd128;
            5'd15: row_base = 9'd136;
            5'd16: row_base = 9'd140;
            5'd17: row_base = 9'd144;
            5'd18: row_base = 9'd156;
            5'd19: row_base = 9'd160;
            5'd20: row_base = 9'd164;
            5'd21: row_base = 9'd188;
            5'd22: row_base = 9'd194;
            5'd23: row_base = 9'd200;
            5'd24: row_base = 9'd222;
            5'd25: row_base = 9'd228;
            5'd26: row_base = 9'd234;
            5'd27: row_base = 9'd254;
            5'd28: row_base = 9'd258;
            5'd29: row_base = 9'd262;
            5'd30: row_base = 9'd288;
            default: row_base = 9'd0;
        endcase
    endfunction

    function automatic logic in_bounds(input logic [4:0] xx, input logic [4:0] yy);
        in_bounds = (xx < 5'd28) && (yy < 5'd31);
    endfunction

    logic [55:0] row;
    logic [27:0] collect_mask;   // bit i = column i of this row is a collectible
    logic [27:0] prefix_mask;    // collectibles strictly left of column x
    logic [4:0]  prefix_count;

    always_comb begin
        row = row_data(y);

        // Collectible tiles are 2'b10 and 2'b11 -> MSB of each tile pair.
        for (int i = 0; i < 28; i++)
            collect_mask[i] = row[55 - 2*i];

        // Mask off column x and everything to its right, then popcount.
        prefix_mask = collect_mask & ~(28'hFFFFFFF << x);
        prefix_count = 5'd0;
        for (int i = 0; i < 28; i++)
            prefix_count += 5'(prefix_mask[i]);

        if (in_bounds(x, y)) begin
            tile         = row[(6'd55 - x*2) -: 2];
            pellet_index = row_base(y) + 9'(prefix_count);
        end else begin
            tile         = WALL_TILE;
            pellet_index = 9'd0;
        end

        collectible = tile[1];

        // Movement rules (unchanged from initial_maze_rom):
        // Pac-Man may not enter the ghost-house door tiles.
        can_move_pac = (tile != WALL_TILE) &&
                       !((x == 5'd13) && (y == 5'd12)) &&
                       !((x == 5'd14) && (y == 5'd12));

        // Ghosts may not cross the house side walls.
        can_move_ghost = (tile != WALL_TILE) &&
                         !((x == 5'd12) && (y >= 5'd12) && (y <= 5'd16)) &&
                         !((x == 5'd15) && (y >= 5'd12) && (y <= 5'd16));
    end

endmodule
