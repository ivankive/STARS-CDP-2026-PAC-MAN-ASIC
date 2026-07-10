module pacman_movement (
    input logic clk,
    input logic reset,
    input logic [3:0] pb,
    output logic [4:0] xpos, 
    output logic [5:0] ypos
);

    logic [27:0] maze [0:35];

    initial begin
        $readmemb("maze.mem", maze);
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
    logic [5:0] next_ypos;

    // counter for clock divider
    logic [4:0] count;

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
            if (count == 19) begin
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

endmodule

`default_nettype wire
