// Port layout:
//   Port A: VGA read-only
//   Port B: Central Control read/write during gameplay
//           Reload FSM write during map reset
`timescale 1ns/1ps

module maze_ram #(
    parameter int NUM_TILES = 868,
    parameter int ADDR_W    = 10,
    parameter int DATA_W    = 2,

    parameter logic [DATA_W-1:0] WALL_TILE = 2'b01
)(
    input  logic                  clk,
    input  logic                  reset,

    // Reload live maze from initial ROM
    input  logic                  map_rst,
    output logic                  reload_busy,
    output logic                  reload_done,

    // Port A: VGA read-only
    input  logic [ADDR_W-1:0]     addr_vga,
    output logic [DATA_W-1:0]     rdata_vga,

    input  logic [ADDR_W-1:0]     addr_central,
    input  logic                  write_en,
    input  logic [DATA_W-1:0]     wdata_central,
    output logic [DATA_W-1:0]     rdata_central,

    // Initial maze ROM interface
    output logic [ADDR_W-1:0]     rom_addr,
    input  logic [DATA_W-1:0]     rom_data
);

    localparam logic [ADDR_W-1:0] LAST_ADDR = NUM_TILES - 1;

    logic [DATA_W-1:0] mem [0:NUM_TILES-1];

    typedef enum logic [1:0] {
        R_IDLE,
        R_WAIT_ROM,
        R_WRITE_TILE,
        R_DONE
    } reload_state_t;

    reload_state_t state;

    logic [ADDR_W-1:0] load_addr;
    logic [ADDR_W-1:0] rom_addr_reg;

    logic reload_write;

    assign rom_addr     = rom_addr_reg;
    assign reload_busy  = (state != R_IDLE);
    assign reload_write = (state == R_WRITE_TILE);

    // Reload FSM
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= R_IDLE;
            load_addr    <= '0;
            rom_addr_reg <= '0;
            reload_done  <= 1'b0;
        end else begin
            reload_done <= 1'b0;

            if (map_rst) begin
                load_addr    <= '0;
                rom_addr_reg <= '0;
                state        <= R_WAIT_ROM;
            end else begin
                case (state)

                    R_IDLE: begin
                        // Wait for map_rst
                    end

                    R_WAIT_ROM: begin
                        // Give initial_maze_rom one clock for rom_data.
                        state <= R_WRITE_TILE;
                    end

                    R_WRITE_TILE: begin
                        if (load_addr == LAST_ADDR) begin
                            state <= R_DONE;
                        end else begin
                            load_addr    <= load_addr + 1'b1;
                            rom_addr_reg <= load_addr + 1'b1;
                            state        <= R_WAIT_ROM;
                        end
                    end

                    R_DONE: begin
                        reload_done <= 1'b1;
                        state       <= R_IDLE;
                    end

                    default: begin
                        state <= R_IDLE;
                    end

                endcase
            end
        end
    end

    // Port A: VGA read-only continuous reading
    always_ff @(posedge clk) begin
        if (reload_write && (addr_vga == load_addr)) begin
            rdata_vga <= rom_data;
        end else if (!reload_busy && write_en && (addr_vga == addr_central)) begin
            rdata_vga <= wdata_central;
        end else if (addr_vga < NUM_TILES) begin
            rdata_vga <= mem[addr_vga];
        end else begin
            rdata_vga <= WALL_TILE;
        end
    end

    // Port B: Central Control read/write or reload write
    always_ff @(posedge clk) begin
        if (reload_write) begin
            mem[load_addr] <= rom_data;
            rdata_central  <= rom_data;
        end else if (!reload_busy) begin
            if (write_en && (addr_central < NUM_TILES)) begin
                mem[addr_central] <= wdata_central;
                rdata_central     <= wdata_central; // write-through behavior
            end else if (addr_central < NUM_TILES) begin
                rdata_central <= mem[addr_central];
            end else begin
                rdata_central <= WALL_TILE;
            end
        end
    end

endmodule