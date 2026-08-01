module ghost_movement (
    input  logic           ghost_can_move,

    input  logic [4:0] ghost_x,
    input  logic [4:0] ghost_y,
    input  logic [1:0] ghost_dir,

    input  logic [4:0] target_x,
    input  logic [4:0] target_y,

    input  logic       can_up,
    input  logic       can_down,
    input  logic       can_left,
    input  logic       can_right,

    input  logic       do_reverse,

    output logic [4:0] next_x,
    output logic [4:0] next_y,
    output logic [1:0] next_dir
);

    localparam logic [1:0] DIR_UP    = 2'd0;
    localparam logic [1:0] DIR_LEFT  = 2'd1;
    localparam logic [1:0] DIR_DOWN  = 2'd2;
    localparam logic [1:0] DIR_RIGHT = 2'd3;

    logic [1:0] reverse_dir;

    function automatic logic legal(
        input logic [1:0] direction
    );
        begin
            case (direction)
                DIR_UP:    legal = can_up;
                DIR_DOWN:  legal = can_down;
                DIR_LEFT:  legal = can_left;
                DIR_RIGHT: legal = can_right;
                default:   legal = 1'b0;
            endcase
        end
    endfunction

    assign reverse_dir = ghost_dir ^ 2'b10;

    always_comb begin
        next_dir = ghost_dir;

        if (ghost_can_move) begin
            // Reverse once when frightened mode begins.
            if (do_reverse && legal(reverse_dir)) begin
                next_dir = reverse_dir;
            end

            // Move toward the target without reversing.
            else if ((target_y > ghost_y) && can_down && (reverse_dir != DIR_DOWN)) begin
                next_dir = DIR_DOWN;
            end

            else if ((target_y < ghost_y) && can_up && (reverse_dir != DIR_UP)) begin
                next_dir = DIR_UP;
            end

            else if ((target_x > ghost_x) && can_right && (reverse_dir != DIR_RIGHT)) begin
                next_dir = DIR_RIGHT;
            end

            else if ((target_x < ghost_x) && can_left && (reverse_dir != DIR_LEFT)) begin
                next_dir = DIR_LEFT;
            end

            // Continue straight when possible.
            else if (legal(ghost_dir)) begin
                next_dir = ghost_dir;
            end

            // Select another legal non-reverse direction.
            else if (can_up && (reverse_dir != DIR_UP)) begin
                next_dir = DIR_UP;
            end

            else if (can_left && (reverse_dir != DIR_LEFT)) begin
                next_dir = DIR_LEFT;
            end

            else if (can_down && (reverse_dir != DIR_DOWN)) begin
                next_dir = DIR_DOWN;
            end

            else if (can_right && (reverse_dir != DIR_RIGHT)) begin
                next_dir = DIR_RIGHT;
            end

            // Reverse only when no other direction is available.
            else if (legal(reverse_dir)) begin
                next_dir = reverse_dir;
            end
        end

        next_x = ghost_x;
        next_y = ghost_y;

        // Move only when the selected direction is confirmed legal.
        if (ghost_can_move && legal(next_dir)) begin
            case (next_dir)
                DIR_UP:
                    next_y = ghost_y - 1'b1;

                DIR_DOWN:
                    next_y = ghost_y + 1'b1;

                DIR_LEFT:
                    next_x = ghost_x - 1'b1;

                DIR_RIGHT:
                    next_x = ghost_x + 1'b1;

                default: begin
                    next_x = ghost_x;
                    next_y = ghost_y;
                end
            endcase
        end
    end

endmodule