module maze_ram_temp (
    input  logic       clk,
    input  logic       reset,

    input  logic       map_rst,
    output logic       map_loaded,

    // Port A: VGA synchronous read
    input  logic [4:0] x_vga,
    input  logic [4:0] y_vga,
    output logic [1:0] rdata_vga,

    // Port B: Central synchronous read/write
    input  logic [4:0] x_central,
    input  logic [4:0] y_central,
    input  logic       write_en,
    output logic [1:0] rdata_central,

    // Async initial ROM reload source
    output logic [4:0] rom_x,
    output logic [4:0] rom_y,
    input  logic [1:0] rom_data
);

    localparam logic [1:0] PATH_TILE = 2'b00;
    localparam logic [1:0] WALL_TILE = 2'b01;

    logic [55:0] maze_rows [0:30];

    typedef enum logic [1:0] {
        R_IDLE,
        R_WRITE_TILE,
        R_DONE
    } reload_state_t;

    reload_state_t state;

    logic [4:0] load_x;
    logic [4:0] load_y;

    logic reload_write;

    assign rom_x = load_x;
    assign rom_y = load_y;

    assign reload_write = (state == R_WRITE_TILE);

    function automatic logic in_bounds(input logic [4:0] x, input logic [4:0] y);
        in_bounds = (x < 5'd28) && (y < 5'd31);
    endfunction

    // Reload FSM, writes one tile per clk
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state      <= R_WRITE_TILE;
            load_x     <= 5'd0;
            load_y     <= 5'd0;
            map_loaded <= 1'b0;
        end else begin
            if (map_rst) begin
                state      <= R_WRITE_TILE;
                load_x     <= 5'd0;
                load_y     <= 5'd0;
                map_loaded <= 1'b0;
            end else begin
                case (state)

                    R_IDLE: begin
                    end

                    R_WRITE_TILE: begin
                        if ((load_x == 5'd27) && (load_y == 5'd30)) begin
                            state <= R_DONE;
                        end else if (load_x == 5'd27) begin
                            load_x <= 5'd0;
                            load_y <= load_y + 5'd1;
                        end else begin
                            load_x <= load_x + 5'd1;
                        end
                    end

                    R_DONE: begin
                        map_loaded <= 1'b1;
                        state      <= R_IDLE;
                    end

                    default: begin
                        state      <= R_IDLE;
                        map_loaded <= 1'b0;
                    end

                endcase
            end
        end
    end

    // Port A: VGA synchronous read for VGA; delay VGA display by 1 clk since read is synchronous
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            rdata_vga <= WALL_TILE;
        end else begin
            if (!map_loaded) begin
                rdata_vga <= WALL_TILE;
            end else if (map_loaded && write_en && in_bounds(x_vga, y_vga) && (x_vga == x_central) && (y_vga == y_central)) begin
                rdata_vga <= PATH_TILE; //bypass
            end else if (in_bounds(x_vga, y_vga)) begin
                rdata_vga <= maze_rows[y_vga][(6'd55 - x_vga*2) -: 2];
            end else begin
                rdata_vga <= WALL_TILE;
            end
        end
    end

    // Port B: reload write OR central sync read/write.
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            rdata_central <= WALL_TILE;
        end else begin
            if (reload_write) begin
                maze_rows[load_y][(6'd55 - load_x*2) -: 2] <= rom_data;
                rdata_central <= WALL_TILE;
            end else if (map_loaded) begin
                if (write_en && in_bounds(x_central, y_central)) begin
                    maze_rows[y_central][(6'd55 - x_central*2) -: 2] <= PATH_TILE;
                    rdata_central <= PATH_TILE;
                end else if (in_bounds(x_central, y_central)) begin
                    rdata_central <= maze_rows[y_central][(6'd55 - x_central*2) -: 2];
                end else begin
                    rdata_central <= WALL_TILE;
                end
            end else begin
                rdata_central <= WALL_TILE;
            end
        end
    end

endmodule