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
    localparam logic [1:0] PELLET     = 2'b10;
    localparam logic [1:0] POWER_TILE = 2'b11;

    // 24 tiles × 2 bits = 48 bits per row.
    // x = 0 is stored in bits [47:46].
    function automatic logic [47:0] row_data (
        input logic [4:0] yy
    );
        begin
            case (yy)
                5'd0:  row_data = 48'b01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01;
                5'd1:  row_data = 48'b01_10_10_10_10_10_10_10_10_10_10_01_01_10_10_10_10_10_10_10_10_10_10_01;
                5'd2:  row_data = 48'b01_10_01_01_10_01_01_01_01_01_10_01_01_10_01_01_01_01_01_10_01_01_10_01;
                5'd3:  row_data = 48'b01_10_01_01_10_01_01_01_01_01_10_01_01_10_01_01_01_01_01_10_01_01_10_01;
                5'd4:  row_data = 48'b01_11_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_11_01;
                5'd5:  row_data = 48'b01_10_01_01_10_01_01_10_01_01_01_01_01_01_01_01_10_01_01_10_01_01_10_01;
                5'd6:  row_data = 48'b01_10_01_01_10_01_01_10_01_01_01_01_01_01_01_01_10_01_01_10_01_01_10_01;
                5'd7:  row_data = 48'b01_10_10_10_10_01_01_10_10_10_10_01_01_10_10_10_10_01_01_10_10_10_10_01;
                5'd8:  row_data = 48'b01_01_01_01_10_01_01_01_01_01_10_01_01_10_01_01_01_01_01_10_01_01_01_01;
                5'd9:  row_data = 48'b01_01_01_01_10_01_01_01_01_01_10_01_01_10_01_01_01_01_01_10_01_01_01_01;
                5'd10: row_data = 48'b01_01_01_01_10_01_01_00_00_00_00_00_00_00_00_00_00_01_01_10_01_01_01_01;
                5'd11: row_data = 48'b01_01_01_01_10_01_01_00_01_01_01_00_00_01_01_01_00_01_01_10_01_01_01_01;
                5'd12: row_data = 48'b01_01_01_01_10_01_01_00_01_00_00_00_00_00_00_01_00_01_01_10_01_01_01_01;
                5'd13: row_data = 48'b00_00_00_00_10_00_00_00_01_00_00_00_00_00_00_01_00_00_00_10_00_00_00_00;
                5'd14: row_data = 48'b01_01_01_01_10_01_01_00_01_00_00_00_00_00_00_01_00_01_01_10_01_01_01_01;
                5'd15: row_data = 48'b01_01_01_01_10_01_01_00_01_01_01_01_01_01_01_01_00_01_01_10_01_01_01_01;
                5'd16: row_data = 48'b01_10_10_10_10_10_10_10_10_10_10_01_01_10_10_10_10_10_10_10_10_10_10_01;
                5'd17: row_data = 48'b01_10_01_01_10_01_01_01_01_01_10_01_01_10_01_01_01_01_01_10_01_01_10_01;
                5'd18: row_data = 48'b01_10_01_01_10_01_01_01_01_01_10_01_01_10_01_01_01_01_01_10_01_01_10_01;
                5'd19: row_data = 48'b01_11_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_11_01;
                5'd20: row_data = 48'b01_10_01_01_01_01_01_01_01_01_10_01_01_10_01_01_01_01_01_01_01_01_10_01;
                5'd21: row_data = 48'b01_10_01_01_01_01_01_01_01_01_10_01_01_10_01_01_01_01_01_01_01_01_10_01;
                5'd22: row_data = 48'b01_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_01;
                5'd23: row_data = 48'b01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01;
                default: row_data = {24{WALL_TILE}};
            endcase
        end
    endfunction

    // Number of collectibles in all rows before the selected row.
    // Total number of collectibles = 186.
    function automatic logic [8:0] row_base (
        input logic [4:0] yy
    );
        begin
            case (yy)
                5'd0:  row_base = 9'd0;
                5'd1:  row_base = 9'd0;
                5'd2:  row_base = 9'd20;
                5'd3:  row_base = 9'd26;
                5'd4:  row_base = 9'd32;
                5'd5:  row_base = 9'd54;
                5'd6:  row_base = 9'd60;
                5'd7:  row_base = 9'd66;
                5'd8:  row_base = 9'd82;
                5'd9:  row_base = 9'd86;
                5'd10: row_base = 9'd90;
                5'd11: row_base = 9'd92;
                5'd12: row_base = 9'd94;
                5'd13: row_base = 9'd96;
                5'd14: row_base = 9'd98;
                5'd15: row_base = 9'd100;
                5'd16: row_base = 9'd102;
                5'd17: row_base = 9'd122;
                5'd18: row_base = 9'd128;
                5'd19: row_base = 9'd134;
                5'd20: row_base = 9'd156;
                5'd21: row_base = 9'd160;
                5'd22: row_base = 9'd164;
                5'd23: row_base = 9'd186;
                default: row_base = 9'd0;
            endcase
        end
    endfunction

    function automatic logic in_bounds (
        input logic [4:0] xx,
        input logic [4:0] yy
    );
        begin
            in_bounds = (xx < 5'd24) && (yy < 5'd24);
        end
    endfunction

    logic [47:0] row;

    // One bit per column:
    // 1 means the column contains a pellet or power pellet.
    logic [23:0] collect_mask;

    // Contains only collectibles strictly left of x.
    logic [23:0] prefix_mask;

    logic [4:0] prefix_count;

    always_comb begin
        row = row_data(y);

        collect_mask = 24'd0;
        prefix_mask  = 24'd0;
        prefix_count = 5'd0;

        // The MSB of each tile is 1 for both 10 and 11.
        for (int i = 0; i < 24; i++) begin
            collect_mask[i] = row[47 - 2*i];
        end

        // Keep only collectible columns to the left of x.
        for (int i = 0; i < 24; i++) begin
            if (i < x)
                prefix_mask[i] = collect_mask[i];
            else
                prefix_mask[i] = 1'b0;
        end

        // Count collectibles to the left.
        for (int i = 0; i < 24; i++) begin
            prefix_count = prefix_count + prefix_mask[i];
        end

        if (in_bounds(x, y)) begin
            tile = row[(6'd47 - x*2) -: 2];

            pellet_index =
                row_base(y) +
                {{4{1'b0}}, prefix_count};
        end else begin
            tile         = WALL_TILE;
            pellet_index = 9'd0;
        end

        collectible = tile[1];

        // Pac-Man cannot enter the two center ghost-house door tiles.
        can_move_pac =
            (tile != WALL_TILE) &&
            !((y == 5'd11) &&
              ((x == 5'd11) || (x == 5'd12)));

        // Ghosts cannot pass through the side walls of the ghost house.
        can_move_ghost =
            (tile != WALL_TILE) &&
            !((x == 5'd8) &&
              (y >= 5'd11) &&
              (y <= 5'd15)) &&
            !((x == 5'd15) &&
              (y >= 5'd11) &&
              (y <= 5'd15));
    end
endmodule