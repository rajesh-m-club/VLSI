module or_g (
    input [3:0] A,
    input [3:0] B,
    output [3:0] y
);
assign y = A | B;
    
endmodule