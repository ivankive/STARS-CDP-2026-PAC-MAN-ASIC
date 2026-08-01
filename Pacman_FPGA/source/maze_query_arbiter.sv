// maze_query_arbiter
//
// All maze lookups now go through one shared maze_wall_pellet_rom instance
// (previously the ROM mux tree existed three times: two initial_maze_rom
// ports plus the maze_bram read logic).
//
// Requesters:
//   VGA       - absolute priority. Served combinationally on every cycle
//               that vga_active is high; the response is registered, giving
//               the same 1-cycle read latency the old maze_bram VGA port
//               had, so the VGA pixel pipeline is unchanged. Eaten pellets
//               are downgraded to PATH here, so downstream draw logic
//               still just sees a 2-bit tile.
//   collision, pacman, ghost - polled round-robin on cycles the VGA does
//               not need (>25% of every scanline, plus all of blanking, so
//               each requester is refreshed every few hundred ns - far
//               faster than the 60 Hz game tick that consumes the results).
//
// Handshake: each game requester's response registers remember the address
// they were computed for. valid = (served address == current address), so
// validity drops automatically the moment a requester moves to a new
// lookup and rises once the arbiter has re-served it. Requesters never
// need a request strobe.

module maze_query_arbiter (
    input  logic       clk,
    input  logic       reset,

    // ---- VGA port (priority) ----
    input  logic       vga_active,     // in-map, video on
    input  logic [4:0] vga_x,
    input  logic [4:0] vga_y,
    output logic [1:0] rdata_vga,      // registered display tile (eaten -> PATH)

    // ---- Collision port ----
    input  logic [4:0] col_x,
    input  logic [4:0] col_y,
    output logic       col_valid,
    output logic       col_collectible,   // original tile is pellet/power
    output logic       col_is_power,      // original tile is power pellet
    output logic [8:0] col_pellet_index,

    // ---- Pac-Man movement port ----
    input  logic [4:0] pac_x,
    input  logic [4:0] pac_y,
    output logic       pac_valid,
    output logic       pac_can_move,

    // ---- Ghost controller port ----
    input  logic [4:0] ghost_x,
    input  logic [4:0] ghost_y,
    output logic       ghost_valid,
    output logic       ghost_can_move,

    // ---- Shared ROM instance ----
    output logic [4:0] rom_x,
    output logic [4:0] rom_y,
    input  logic [1:0] rom_tile,
    input  logic       rom_collectible,
    input  logic [8:0] rom_pellet_index,
    input  logic       rom_can_move_pac,
    input  logic       rom_can_move_ghost,

    // ---- pellet_state VGA read port ----
    output logic [8:0] pellet_rd_index,
    input  logic       pellet_rd_bit
);

    localparam logic [1:0] PATH_TILE = 2'b00;
    localparam logic [1:0] WALL_TILE = 2'b01;

    // Round-robin pointer over the three game requesters.
    localparam logic [1:0] RR_COL = 2'd0,
                           RR_PAC = 2'd1,
                           RR_GHO = 2'd2;

    logic [1:0] rr;

    // Address the ROM: VGA wins, otherwise current round-robin requester.
    always_comb begin
        if (vga_active) begin
            rom_x = vga_x;
            rom_y = vga_y;
        end else begin
            case (rr)
                RR_COL:  begin rom_x = col_x;   rom_y = col_y;   end
                RR_PAC:  begin rom_x = pac_x;   rom_y = pac_y;   end
                default: begin rom_x = ghost_x; rom_y = ghost_y; end
            endcase
        end
    end

    // VGA also reads the eaten bit for the tile it is fetching.
    assign pellet_rd_index = rom_pellet_index;

    // Served-address bookkeeping for the game requesters.
    logic [9:0] col_served_addr, pac_served_addr, ghost_served_addr;

    assign col_valid   = (col_served_addr   == {col_x,   col_y});
    assign pac_valid   = (pac_served_addr   == {pac_x,   pac_y});
    assign ghost_valid = (ghost_served_addr == {ghost_x, ghost_y});

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            rr                <= RR_COL;
            rdata_vga         <= WALL_TILE;
            col_served_addr   <= 10'h3FF;   // impossible address -> valid low
            pac_served_addr   <= 10'h3FF;
            ghost_served_addr <= 10'h3FF;
            col_collectible   <= 1'b0;
            col_is_power      <= 1'b0;
            col_pellet_index  <= 9'd0;
            pac_can_move      <= 1'b0;
            ghost_can_move    <= 1'b0;
        end else begin
            if (vga_active) begin
                // Display tile: eaten collectibles render as empty path.
                rdata_vga <= (rom_collectible && pellet_rd_bit) ? PATH_TILE
                                                                : rom_tile;
            end else begin
                rdata_vga <= WALL_TILE;

                case (rr)
                    RR_COL: begin
                        col_collectible  <= rom_collectible;
                        col_is_power     <= (rom_tile == 2'b11);
                        col_pellet_index <= rom_pellet_index;
                        col_served_addr  <= {col_x, col_y};
                        rr               <= RR_PAC;
                    end
                    RR_PAC: begin
                        pac_can_move    <= rom_can_move_pac;
                        pac_served_addr <= {pac_x, pac_y};
                        rr              <= RR_GHO;
                    end
                    default: begin
                        ghost_can_move    <= rom_can_move_ghost;
                        ghost_served_addr <= {ghost_x, ghost_y};
                        rr                <= RR_COL;
                    end
                endcase
            end
        end
    end

endmodule
