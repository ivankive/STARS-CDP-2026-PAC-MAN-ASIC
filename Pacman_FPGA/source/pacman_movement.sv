module pacman_movement (
    input logic clk,
    input logic reset,
    input logic [3:0] pb,
    output logic [4:0] xpos, 
    output logic [4:0] ypos,
    output logic [1:0] direction
);

    logic [27:0] maze [0:30];

    initial begin
        maze[0]  = 28'b0000000000000000000000000000;
        maze[1]  = 28'b0111111111111001111111111110;
        maze[2]  = 28'b0100001000001001000001000010;
        maze[3]  = 28'b0100001000001001000001000010;
        maze[4]  = 28'b0100001000001001000001000010;
        maze[5]  = 28'b0111111111111111111111111110;
        maze[6]  = 28'b0100001001000000001001000010;
        maze[7]  = 28'b0100001001000000001001000010;
        maze[8]  = 28'b0111111001111001111001111110;
        maze[9]  = 28'b0000001000001001000001000000;
        maze[10] = 28'b0000001000001001000001000000;
        maze[11] = 28'b0000001001111111111001000000;
        maze[12] = 28'b0000001001000000001001000000;
        maze[13] = 28'b0000001001011111101001000000;
        maze[14] = 28'b1111111111011111101111111111;
        maze[15] = 28'b0000001001011111101001000000;
        maze[16] = 28'b0000001001000000001001000000;
        maze[17] = 28'b0000001001111111111001000000;
        maze[18] = 28'b0000001001000000001001000000;
        maze[19] = 28'b0000001001000000001001000000;
        maze[20] = 28'b0111111111111001111111111110;
        maze[21] = 28'b0100001000001001000001000010;
        maze[22] = 28'b0100001000001001000001000010;
        maze[23] = 28'b0111001111111111111111001110;
        maze[24] = 28'b0001001001000000001001001000;
        maze[25] = 28'b0001001001000000001001001000;
        maze[26] = 28'b0111111001111001111001111110;
        maze[27] = 28'b0100000000001001000000000010;
        maze[28] = 28'b0100000000001001000000000010;
        maze[29] = 28'b0111111111111111111111111110;
        maze[30] = 28'b0000000000000000000000000000;
    end
      
    // direction enums
    typedef enum logic [1:0] {
        UP,
        LEFT,
        DOWN,
        RIGHT
    } dir_t;
    

    dir_t dir;
    dir_t next_dir;
    dir_t store_dir;

    logic [4:0] next_xpos;
    logic [4:0] next_ypos;

    // counter for clock divider
    logic [23:0] count;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            xpos  <= 1;
            ypos  <= 4;
            dir   <= RIGHT;
            count <= 0;
            store_dir <= RIGHT;
        end
        else begin
            if (pb[0])
                store_dir <= UP;
            else if (pb[1])
                store_dir <= RIGHT;
            else if (pb[2])
                store_dir <= DOWN;
            else if (pb[3])
                store_dir <= LEFT;
            if (count == 24'd3360000) begin
                count <= 0;
                dir <= next_dir;
                xpos <= next_xpos;
                ypos <= next_ypos;
            end
            else begin
                count <= count + 1;
            end
        end
    end

    always_comb begin
        next_dir = dir;
        case (store_dir)

            UP:
                if (maze[ypos-1][xpos] == 1)
                    next_dir = store_dir;

            DOWN:
                if (maze[ypos+1][xpos] == 1)
                    next_dir = store_dir;

            LEFT:
                if (maze[ypos][xpos-1] == 1)
                    next_dir = store_dir;

            RIGHT:
                if (maze[ypos][xpos+1] == 1)
                    next_dir = store_dir;

            default: ;

        endcase
    end
    
    always_comb begin
        next_ypos = ypos;
        next_xpos = xpos;
        case (next_dir)

            UP:
                if (maze[ypos-1][xpos] == 1)
                    next_ypos = ypos - 1;

            DOWN:
                if (maze[ypos+1][xpos] == 1)
                    next_ypos = ypos + 1;

            LEFT:
                if (maze[ypos][xpos-1] == 1)
                    next_xpos = xpos - 1;

            RIGHT:
                if (maze[ypos][xpos+1] == 1)
                    next_xpos = xpos + 1;
            
            default: ;
        endcase
    end

    assign direction = store_dir;

endmodule