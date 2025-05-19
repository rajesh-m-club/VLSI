module sub (
    input [3:0]A,
    input [3:0]B,
    output [3:0]Diff,
    output b_out
);
    wire [4:0]result;
    assign result = {1'b0,A} - {1'b0,B};
    assign Diff = result[3:0];
    assign b_out = result[4];
endmodule