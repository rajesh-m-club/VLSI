`timescale 1ns/1ps

module fixed_point_operations (
    input  signed [16:0] q_314,        
    input  signed [16:0] q_512,        
    input  [1:0]         operation,
    input                clk,
    output reg signed [16:0] out_q_512 
);

    reg signed [16:0] q314_r;
    reg signed [16:0] q512_r;
    reg [1:0]         op_r;

    always @(posedge clk) begin
        q314_r <= q_314;
        q512_r <= q_512;
        op_r   <= operation;
    end

    
    wire signed [18:0] q314_ext;
    assign q314_ext = { {2{q314_r[16]}}, q314_r };

    wire signed [16:0] q314_to_q512;
    assign q314_to_q512 = (q314_ext + 19'sd2) >>> 2;

    
    wire signed [17:0] add_wide;
    wire signed [17:0] sub_wide;
    wire signed [33:0] mult_full;

    assign add_wide = q512_r + q314_to_q512;
    assign sub_wide = q512_r - q314_to_q512;
    assign mult_full = q314_r * q512_r;

    // Round before shifting
    wire signed [33:0] mult_rounded;
    assign mult_rounded = mult_full + (34'sd1 << 13);

    wire signed [16:0] mult_q512;
    assign mult_q512 = mult_rounded >>> 14;

    
    always @(posedge clk) begin
        case (op_r)
            2'b00: out_q_512 <= add_wide[16:0];          
            2'b01: out_q_512 <= sub_wide[17:1];          
            2'b10: out_q_512 <= mult_q512;               
            default: out_q_512 <= 17'sd0;
        endcase
    end

endmodule
