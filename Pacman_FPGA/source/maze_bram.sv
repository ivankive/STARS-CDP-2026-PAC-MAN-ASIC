module maze_bram (
    input  logic       clk,
    input  logic       reset,

    input  logic       map_rst,
    output logic       map_loaded,

    // VGA read port
    input  logic [4:0] x_vga,
    input  logic [4:0] y_vga,
    output logic [1:0] rdata_vga,

    // Central/game read-write port
    input  logic [4:0] x_central,
    input  logic [4:0] y_central,
    input  logic       write_en,
    output logic [1:0] rdata_central,

    // Reload source ROM interface
    output logic [4:0] rom_x,
    output logic [4:0] rom_y,
    input  logic [1:0] rom_data
);

    // Tile encodings
    localparam logic [1:0] PATH_TILE  = 2'b00;
    localparam logic [1:0] WALL_TILE  = 2'b01;
    localparam logic [1:0] PELLET     = 2'b10;
    localparam logic [1:0] POWER_TILE = 2'b11;

    localparam logic [7:0] WALL_WORD = {4{WALL_TILE}};
    logic [7:0] mem [0:255];

    logic [4:0] load_x;
    logic [4:0] load_y;

    logic [7:0] load_word_addr;
    logic [1:0] load_tile_sel;

    logic [7:0] pack_word;
    logic [7:0] next_pack_word;

    assign rom_x = load_x;
    assign rom_y = load_y;

    always_comb begin
        next_pack_word = pack_word;

        case (load_tile_sel)
            2'd0:
                next_pack_word[1:0] = rom_data;

            2'd1:
                next_pack_word[3:2] = rom_data;

            2'd2:
                next_pack_word[5:4] = rom_data;

            2'd3:
                next_pack_word[7:6] = rom_data;

            default:
                next_pack_word = pack_word;
        endcase
    end

    logic       vga_in_bounds;
    logic [9:0] vga_tile_index;
    logic [7:0] vga_word_addr;
    logic [1:0] vga_tile_sel;

    assign vga_in_bounds =
        (x_vga < 5'd28) &&
        (y_vga < 5'd31);

    assign vga_tile_index =
        ({5'd0, y_vga} * 10'd28) +
        {5'd0, x_vga};

    assign vga_word_addr = vga_tile_index[9:2];
    assign vga_tile_sel  = vga_tile_index[1:0];

    logic [7:0] vga_word_q;
    logic [1:0] vga_sel_q;
    logic       vga_valid_q;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            vga_word_q  <= WALL_WORD;
            vga_sel_q   <= 2'd0;
            vga_valid_q <= 1'b0;
        end else begin
            if (map_loaded && vga_in_bounds) begin
                vga_word_q  <= mem[vga_word_addr];
                vga_sel_q   <= vga_tile_sel;
                vga_valid_q <= 1'b1;
            end else begin
                vga_word_q  <= WALL_WORD;
                vga_sel_q   <= 2'd0;
                vga_valid_q <= 1'b0;
            end
        end
    end

    always_comb begin
        if (!vga_valid_q) begin
            rdata_vga = WALL_TILE;
        end else begin
            case (vga_sel_q)
                2'd0:
                    rdata_vga = vga_word_q[1:0];

                2'd1:
                    rdata_vga = vga_word_q[3:2];

                2'd2:
                    rdata_vga = vga_word_q[5:4];

                2'd3:
                    rdata_vga = vga_word_q[7:6];

                default:
                    rdata_vga = WALL_TILE;
            endcase
        end
    end

    logic       central_in_bounds;
    logic [9:0] central_tile_index;
    logic [7:0] central_word_addr;
    logic [1:0] central_tile_sel;

    assign central_in_bounds =
        (x_central < 5'd28) &&
        (y_central < 5'd31);

    assign central_tile_index =
        ({5'd0, y_central} * 10'd28) +
        {5'd0, x_central};

    assign central_word_addr = central_tile_index[9:2];
    assign central_tile_sel  = central_tile_index[1:0];

    logic [7:0] central_word_q;
    logic [7:0] central_addr_q;
    logic [1:0] central_sel_q;
    logic       central_valid_q;
    logic [7:0] central_cleared_word;

    always_comb begin
        central_cleared_word = central_word_q;

        case (central_sel_q)
            2'd0:
                central_cleared_word[1:0] = PATH_TILE;

            2'd1:
                central_cleared_word[3:2] = PATH_TILE;

            2'd2:
                central_cleared_word[5:4] = PATH_TILE;

            2'd3:
                central_cleared_word[7:6] = PATH_TILE;

            default:
                central_cleared_word = central_word_q;
        endcase
    end

    always_comb begin
        if (!central_valid_q) begin
            rdata_central = WALL_TILE;
        end else begin
            case (central_sel_q)
                2'd0:
                    rdata_central = central_word_q[1:0];

                2'd1:
                    rdata_central = central_word_q[3:2];

                2'd2:
                    rdata_central = central_word_q[5:4];

                2'd3:
                    rdata_central = central_word_q[7:6];

                default:
                    rdata_central = WALL_TILE;
            endcase
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            map_loaded <= 1'b0;

            load_x         <= 5'd0;
            load_y         <= 5'd0;
            load_word_addr <= 8'd0;
            load_tile_sel  <= 2'd0;
            pack_word      <= 8'd0;

            central_word_q  <= WALL_WORD;
            central_addr_q  <= 8'd0;
            central_sel_q   <= 2'd0;
            central_valid_q <= 1'b0;
        end else begin

            // Reload the complete maze from ROM.
            if (map_rst) begin
                map_loaded <= 1'b0;

                load_x         <= 5'd0;
                load_y         <= 5'd0;
                load_word_addr <= 8'd0;
                load_tile_sel  <= 2'd0;
                pack_word      <= 8'd0;

                central_word_q  <= WALL_WORD;
                central_addr_q  <= 8'd0;
                central_sel_q   <= 2'd0;
                central_valid_q <= 1'b0;
            end

            // Initial maze loading
            else if (!map_loaded) begin
                central_word_q  <= WALL_WORD;
                central_addr_q  <= 8'd0;
                central_sel_q   <= 2'd0;
                central_valid_q <= 1'b0;

                if (load_tile_sel == 2'd3) begin
                    mem[load_word_addr] <= next_pack_word;

                    pack_word     <= 8'd0;
                    load_tile_sel <= 2'd0;

                    if (load_word_addr == 8'd216) begin
                        map_loaded <= 1'b1;
                    end else begin
                        load_word_addr <= load_word_addr + 8'd1;
                    end
                end else begin
                    pack_word <= next_pack_word;

                    load_tile_sel <= load_tile_sel + 2'd1;
                end

                if (load_x == 5'd27) begin
                    load_x <= 5'd0;

                    if (load_y != 5'd30) begin
                        load_y <= load_y + 5'd1;
                    end
                end else begin
                    load_x <= load_x + 5'd1;
                end
            end

            // Normal gameplay
            else begin
                if (central_in_bounds) begin
                    central_word_q  <= mem[central_word_addr];
                    central_addr_q  <= central_word_addr;
                    central_sel_q   <= central_tile_sel;
                    central_valid_q <= 1'b1;
                end else begin
                    central_word_q  <= WALL_WORD;
                    central_addr_q  <= 8'd0;
                    central_sel_q   <= 2'd0;
                    central_valid_q <= 1'b0;
                end
                
                if (write_en && central_valid_q) begin
                    mem[central_addr_q] <= central_cleared_word;
                end
            end
        end
    end

endmodule