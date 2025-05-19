module alu (
    input [3:0]A,
    input [3:0]B,
    input [2:0]sel,
    output reg [3:0]y,
    output reg c_out
);
wire carry_out,borrow_out;
wire [3:0] and_out,or_out,xor_out,not_out,shift_right_out,shift_left_out,sum_out,diff_out;
wire [1:0] shift_by;
assign shift_by = B[1:0];
add add_inst (.A(A),.B(B),.sum(sum_out),.c_out(carry_out));
sub sub_inst (.A(A),.B(B),.Diff(diff_out),.b_out(borrow_out));
and_g and_inst (.A(A),.B(B),.y(and_out));
or_g or_inst (.A(A),.B(B),.y(or_out));
xor_g xor_inst (.A(A),.B(B),.y(xor_out));
not_g not_inst (.A(A),.y(not_out));
shift_left shift_left_inst (.A(A),.B(shift_by),.y(shift_left_out));
shift_right shift_right_inst (.A(A),.B(shift_by),.y(shift_right_out));
always @(*) begin
    case (sel)
        3'b000: begin   // Addition
            y = sum_out;
            c_out = carry_out;
        end
        3'b001: begin   // Subtraction
            y = diff_out;
            c_out = borrow_out;
        end
        3'b010: begin   // AND
            y = and_out;
            c_out = 1'b0;
        end
        3'b011: begin   // OR
            y = or_out;
            c_out = 1'b0;
        end
        3'b100: begin   // XOR
            y = xor_out;
            c_out = 1'b0;
        end
        3'b101: begin   // NOT (on A only)
            y = not_out;
            c_out = 1'b0;
        end
        3'b110: begin   // Shift Left
            y = shift_left_out;
            c_out = 1'b0;
        end
        3'b111: begin   // Shift Right
            y = shift_right_out;
            c_out = 1'b0;
        end
        default: begin
            y = 4'b0000;
            c_out = 1'b0;
        end
    endcase
end

endmodule