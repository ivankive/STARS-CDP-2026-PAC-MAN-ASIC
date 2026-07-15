module maze_rom (
    // Port A: reload or Pac-Man movement
    input  logic [4:0] x_a,
    input  logic [4:0] y_a,
    output logic [1:0] tile_a,
    output logic       pac_can_move_right, pac_can_move_left, pac_can_move_up, pac_can_move_down,
    
    // Port B: ghost movement
    input  logic [4:0] x_b,
    input  logic [4:0] y_b,
    output logic [1:0] tile_b,
    output logic       ghost_can_move_right, ghost_can_move_left, ghost_can_move_up, ghost_can_move_down,

    // Port C: RAM Reload
    input  logic [4:0] x_c,
    input  logic [4:0] y_c,
    output logic [1:0] tile_c);

    localparam logic [1:0] PATH_TILE  = 2'b00;
    localparam logic [1:0] WALL_TILE  = 2'b01;
    localparam logic [1:0] PELLET     = 2'b10;
    localparam logic [1:0] POWER_TILE = 2'b11;

    function automatic logic [55:0] maze_row;
        input logic [4:0] y;
        begin
            case (y)
                5'd0:  maze_row = {28{2'b01}};
                5'd1:  maze_row = 56'b01_10_10_10_10_10_10_10_10_10_10_10_10_01_01_10_10_10_10_10_10_10_10_10_10_10_10_01;
                5'd2:  maze_row = 56'b01_10_01_01_01_01_10_01_01_01_01_01_10_01_01_10_01_01_01_01_01_10_01_01_01_01_10_01;
                5'd3:  maze_row = 56'b01_11_01_01_01_01_10_01_01_01_01_01_10_01_01_10_01_01_01_01_01_10_01_01_01_01_11_01;
                5'd4:  maze_row = 56'b01_10_01_01_01_01_10_01_01_01_01_01_10_01_01_10_01_01_01_01_01_10_01_01_01_01_10_01;
                5'd5:  maze_row = 56'b01_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_01;
                5'd6:  maze_row = 56'b01_10_01_01_01_01_10_01_01_10_01_01_01_01_01_01_01_01_10_01_01_10_01_01_01_01_10_01;
                5'd7:  maze_row = 56'b01_10_01_01_01_01_10_01_01_10_01_01_01_01_01_01_01_01_10_01_01_10_01_01_01_01_10_01;
                5'd8:  maze_row = 56'b01_10_10_10_10_10_10_01_01_10_10_10_10_01_01_10_10_10_10_01_01_10_10_10_10_10_10_01;
                5'd9:  maze_row = 56'b01_01_01_01_01_01_10_01_01_01_01_01_10_01_01_10_01_01_01_01_01_10_01_01_01_01_01_01;
                5'd10: maze_row = 56'b01_01_01_01_01_01_10_01_01_01_01_01_10_01_01_10_01_01_01_01_01_10_01_01_01_01_01_01;
                5'd11: maze_row = 56'b01_01_01_01_01_01_10_01_01_10_10_10_10_10_10_10_10_10_10_01_01_10_01_01_01_01_01_01;
                5'd12: maze_row = 56'b01_01_01_01_01_01_10_01_01_10_01_01_01_00_00_01_01_01_10_01_01_10_01_01_01_01_01_01;
                5'd13: maze_row = 56'b01_01_01_01_01_01_10_01_01_10_01_00_00_00_00_00_00_01_10_01_01_10_01_01_01_01_01_01;
                5'd14: maze_row = 56'b00_00_00_00_00_00_10_10_10_10_01_00_00_00_00_00_00_01_10_10_10_10_00_00_00_00_00_00;
                5'd15: maze_row = 56'b01_01_01_01_01_01_10_01_01_10_01_00_00_00_00_00_00_01_10_01_01_10_01_01_01_01_01_01;
                5'd16: maze_row = 56'b01_01_01_01_01_01_10_01_01_10_01_01_01_01_01_01_01_01_10_01_01_10_01_01_01_01_01_01;
                5'd17: maze_row = 56'b01_01_01_01_01_01_10_01_01_10_10_10_10_10_10_10_10_10_10_01_01_10_01_01_01_01_01_01;
                5'd18: maze_row = 56'b01_01_01_01_01_01_10_01_01_10_01_01_01_01_01_01_01_01_10_01_01_10_01_01_01_01_01_01;
                5'd19: maze_row = 56'b01_01_01_01_01_01_10_01_01_10_01_01_01_01_01_01_01_01_10_01_01_10_01_01_01_01_01_01;
                5'd20: maze_row = 56'b01_10_10_10_10_10_10_10_10_10_10_10_10_01_01_10_10_10_10_10_10_10_10_10_10_10_10_01;
                5'd21: maze_row = 56'b01_10_01_01_01_01_10_01_01_01_01_01_10_01_01_10_01_01_01_01_01_10_01_01_01_01_10_01;
                5'd22: maze_row = 56'b01_10_01_01_01_01_10_01_01_01_01_01_10_01_01_10_01_01_01_01_01_10_01_01_01_01_10_01;
                5'd23: maze_row = 56'b01_11_10_10_01_01_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_01_01_10_10_11_01;
                5'd24: maze_row = 56'b01_01_01_10_01_01_10_01_01_10_01_01_01_01_01_01_01_01_10_01_01_10_01_01_10_01_01_01;
                5'd25: maze_row = 56'b01_01_01_10_01_01_10_01_01_10_01_01_01_01_01_01_01_01_10_01_01_10_01_01_10_01_01_01;
                5'd26: maze_row = 56'b01_10_10_10_10_10_10_01_01_10_10_10_10_01_01_10_10_10_10_01_01_10_10_10_10_10_10_01;
                5'd27: maze_row = 56'b01_10_01_01_01_01_01_01_01_01_01_01_10_01_01_10_01_01_01_01_01_01_01_01_01_01_10_01;
                5'd28: maze_row = 56'b01_10_01_01_01_01_01_01_01_01_01_01_10_01_01_10_01_01_01_01_01_01_01_01_01_01_10_01;
                5'd29: maze_row = 56'b01_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_01;
                5'd30: maze_row = {28{2'b01}};
                default: maze_row = {28{2'b01}};
            endcase
        end
    endfunction


    function automatic logic in_bounds;
        input logic [4:0] x;
        input logic [4:0] y;
        begin
            in_bounds = (x < 5'd28) && (y < 5'd31);
        end
    endfunction
      

    function automatic logic [1:0] tile_from_xy;
        input logic [4:0] x;
        input logic [4:0] y;
        logic [55:0] row; 
        begin
            if (in_bounds(x, y)) begin
                row = maze_row(y);
                tile_from_xy = row[(6'd55 - x*2) -: 2];
            end else
                tile_from_xy = WALL_TILE;
        end
    endfunction

    always_comb begin
        tile_a = tile_from_xy(x_a, y_a);
        tile_b = tile_from_xy(x_b, y_b);
        tile_c = tile_from_xy(x_c, y_c);

    end


    function automatic logic can_move_left;
        input logic [4:0]x;
        input logic [4:0]y; 

        if (x == 5'd0 && y == 5'd14 ) // to wrap around tunnel

        can_move_left = 1'b1;

        else

        can_move_left = (tile_from_xy((x - 5'b1), y) != WALL_TILE); 

    endfunction


    function automatic logic can_move_right;
        input logic [4:0]x;
        input logic [4:0]y; 

        if(x == 5'd27 && y == 5'd14 )// to wrap around tunnel

        can_move_right = 1'b1;

        else

        can_move_right = (tile_from_xy((x + 5'b1), y) != WALL_TILE); 

    endfunction


    function automatic logic can_move_up;
        input logic [4:0]x;
        input logic [4:0]y; 

        can_move_up = (tile_from_xy(x, y - 5'b1) != WALL_TILE); 

    endfunction


    function automatic logic can_move_down;
        input logic [4:0]x;
        input logic [4:0]y; 

        can_move_down = (tile_from_xy(x, y + 5'b1) != WALL_TILE)
             && !((y == 5'd11) && (x == 5'd13 || x == 5'd14));  // to not be able to move inside th ghost cage 

    endfunction

always_comb begin

pac_can_move_down      = can_move_down(x_a, y_a);
pac_can_move_up        = can_move_up(x_a, y_a);
pac_can_move_left      = can_move_left(x_a, y_a);
pac_can_move_right     = can_move_right(x_a, y_a);

ghost_can_move_down    = can_move_down(x_b, y_b);
ghost_can_move_up      = can_move_up(x_b, y_b);
ghost_can_move_left    = can_move_left(x_b, y_b);
ghost_can_move_right   = can_move_right(x_b, y_b);         



end



endmodule