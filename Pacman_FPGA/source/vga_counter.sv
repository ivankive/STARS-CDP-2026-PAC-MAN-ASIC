module vga_counter (
    input  logic clk,          // 25 MHz pixel clock
    input  logic rst,

    output logic hsync,
    output logic vsync,
    output logic [9:0] hcount,
    output logic [9:0] vcount,
    output logic video_on
);
    localparam H_VISIBLE = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = 800;

    localparam V_VISIBLE = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = 525;

    // Horizontal & Vertical Counters
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            hcount <= 0;
            vcount <= 0;
        end
        else begin
            if (hcount == H_TOTAL-1) begin
                hcount <= 0;

                if (vcount == V_TOTAL-1)
                    vcount <= 0;
                else
                    vcount <= vcount + 1;
            end
            else begin
                hcount <= hcount + 1;
            end

        end
    end

    // HSYNC (Active Low)
    always_comb begin
        if ((hcount >= H_VISIBLE + H_FRONT) &&
            (hcount < H_VISIBLE + H_FRONT + H_SYNC))
            hsync = 0;
        else
            hsync = 1;
    end

    // VSYNC (Active Low)
    always_comb begin
        if ((vcount >= V_VISIBLE + V_FRONT) &&
            (vcount < V_VISIBLE + V_FRONT + V_SYNC))
            vsync = 0;
        else
            vsync = 1;
    end

    assign video_on = (hcount < H_VISIBLE) && (vcount < V_VISIBLE);

endmodule
