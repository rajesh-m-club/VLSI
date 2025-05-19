module not_g (
    input [3:0]A,
    output [3:0]y
);
    assign y = ~A;
endmodule