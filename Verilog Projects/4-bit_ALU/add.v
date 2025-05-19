module add (
    input [3:0]A,
    input [3:0]B,
    output [3:0]sum,
    output c_out
);
wire [4:0] result;
assign result = A+B;
assign sum = result[3:0];
assign c_out = result[4]; 
    
endmodule