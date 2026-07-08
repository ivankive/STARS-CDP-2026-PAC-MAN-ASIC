`default_nettype none

module pacman_movement (
    input logic clk,
    input logic reset,
    input logic [3:0] pb,
    output logic [4:0] xpos, 
    output logic [5:0] ypos
);

    logic [0:35][0:27] maze;

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

    // counter for clock divider
    logic [4:0] count;

    always_ff @(posedge clk) begin
        if (reset) begin
            xpos <= 0;
            ypos <= 0;
            dir <= RIGHT;
            count <= 0;
        end
        else begin

            // last button pressed determines direction
            if (pb[3])
                dir <= UP;
            else if (pb[2])
                dir <= RIGHT;
            else if (pb[1])
                dir <= DOWN;
            else if (pb[0])
                dir <= LEFT;

            // move every 19 cycles
            if (count == 19) begin
                count <= 0;

                case (dir)

                    UP:
                        if (maze[ypos-1][xpos] == 1)
                            ypos <= ypos - 1;

                    DOWN:
                        if (maze[ypos+1][xpos] == 1)
                            ypos <= ypos + 1;

                    LEFT:
                        if (maze[ypos][xpos-1] == 1)
                            xpos <= xpos - 1;

                    RIGHT:
                        if (maze[ypos][xpos+1] == 1)
                            xpos <= xpos + 1;

                endcase
            end
            else
                count <= count + 1;
        end
    end

endmodule

endmodule

`default_nettype wire