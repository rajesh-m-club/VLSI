`timescale 1ns/1ps

module lpf_optimised_pipelined #(
    parameter TAPS_OPP = 50
)(
    input  wire clk,
    input  wire rst,
    input  wire signed [16:0] x_in,
    output reg  signed [40:0] y_out
);

// PARAMETERS
localparam TOTAL_TAPS = 2*TAPS_OPP + 1;
localparam TREE_SIZE  = 64;

integer i, k;

//SHIFT REGISTER
reg signed [16:0] x_mem [0:TOTAL_TAPS-1];

always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < TOTAL_TAPS; i = i + 1)
            x_mem[i] <= 0;
    end else begin
        for (i = TOTAL_TAPS-1; i > 0; i = i - 1)
            x_mem[i] <= x_mem[i-1];
        x_mem[0] <= x_in;
    end
end

// LUT COEFFICIENTS 
reg signed [16:0] coeff_full [0:TOTAL_TAPS-1];
reg signed [16:0] coeff [0:TAPS_OPP-1];
reg signed [16:0] coeff_center;

initial begin
    $readmemb("fir_taps_Q3_14.mem", coeff_full);

    for (k = 0; k < TAPS_OPP; k = k + 1)
        coeff[k] = coeff_full[k];

    coeff_center = coeff_full[TAPS_OPP];
end

// 0TAGE 0
reg signed [17:0] sum_pair [0:TAPS_OPP-1];
reg signed [40:0] stage0   [0:TREE_SIZE-1];
reg signed [40:0] center_mult;

always @(posedge clk) begin
    for (i = 0; i < TAPS_OPP; i = i + 1) begin
        sum_pair[i] <= x_mem[i] + x_mem[2*TAPS_OPP - i];
        stage0[i]   <= coeff[i] * sum_pair[i];
    end

    for (i = TAPS_OPP; i < TREE_SIZE; i = i + 1)
        stage0[i] <= 0;

    center_mult <= coeff_center * x_mem[TAPS_OPP];
end

// ADDER TREE
reg signed [40:0] stage1 [0:TREE_SIZE/2-1];
reg signed [40:0] stage2 [0:TREE_SIZE/4-1];
reg signed [40:0] stage3 [0:TREE_SIZE/8-1];
reg signed [40:0] stage4 [0:TREE_SIZE/16-1];
reg signed [40:0] stage5 [0:TREE_SIZE/32-1];
reg signed [40:0] stage6 [0:TREE_SIZE/64-1];

always @(posedge clk)
    for (i = 0; i < TREE_SIZE/2; i = i + 1)
        stage1[i] <= stage0[2*i] + stage0[2*i+1];

always @(posedge clk)
    for (i = 0; i < TREE_SIZE/4; i = i + 1)
        stage2[i] <= stage1[2*i] + stage1[2*i+1];

always @(posedge clk)
    for (i = 0; i < TREE_SIZE/8; i = i + 1)
        stage3[i] <= stage2[2*i] + stage2[2*i+1];

always @(posedge clk)
    for (i = 0; i < TREE_SIZE/16; i = i + 1)
        stage4[i] <= stage3[2*i] + stage3[2*i+1];

always @(posedge clk)
    for (i = 0; i < TREE_SIZE/32; i = i + 1)
        stage5[i] <= stage4[2*i] + stage4[2*i+1];

always @(posedge clk)
    for (i = 0; i < TREE_SIZE/64; i = i + 1)
        stage6[i] <= stage5[2*i] + stage5[2*i+1];

// CENTER ALIGN
reg signed [40:0] center_pipe [0:6];

always @(posedge clk) begin
    center_pipe[0] <= center_mult;
    for (k = 1; k < 7; k = k + 1)
        center_pipe[k] <= center_pipe[k-1];
end

// OUTPUT
always @(posedge clk) begin
    if (rst)
        y_out <= 0;
    else
        y_out <= stage6[0] + center_pipe[6];
end

endmodule
