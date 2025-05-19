module shift_left (
    input [3:0]A,
    input [1:0]B,
    output [3:0]y
);
    assign y = A<<B;
endmodule