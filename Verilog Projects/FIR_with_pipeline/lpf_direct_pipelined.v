`timescale 1ns/1ps

module lpf_direct_pipelined #(
    parameter TAPS = 101
)(
    input clk,
    input rst,
    input signed [16:0] x_in,
    output reg signed [40:0] y_out
);

// PARAMETERS
localparam S1 = (TAPS+1)/2;
localparam S2 = (S1+1)/2;
localparam S3 = (S2+1)/2;
localparam S4 = (S3+1)/2;
localparam S5 = (S4+1)/2;
localparam S6 = (S5+1)/2;
localparam S7 = (S6+1)/2;

// STORAGE
reg signed [16:0] mem_x_in [0:TAPS-1];
reg signed [33:0] mult [0:TAPS-1];

// LUT coefficients
reg signed [16:0] coeff [0:TAPS-1];

// stages
reg signed [40:0] stage1 [0:S1-1];
reg signed [40:0] stage2 [0:S2-1];
reg signed [40:0] stage3 [0:S3-1];
reg signed [40:0] stage4 [0:S4-1];
reg signed [40:0] stage5 [0:S5-1];
reg signed [40:0] stage6 [0:S6-1];
reg signed [40:0] stage7 [0:S7-1];

integer i;


initial begin
    $readmemb("fir_taps_Q3_14.mem", coeff);
end

always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < TAPS; i = i + 1)
            mem_x_in[i] <= 0;
    end else begin
        for (i = TAPS-1; i > 0; i = i - 1)
            mem_x_in[i] <= mem_x_in[i-1];
        mem_x_in[0] <= x_in;
    end
end

//MULTIPLY
always @(posedge clk) begin
    for (i = 0; i < TAPS; i = i + 1)
        mult[i] <= mem_x_in[i] * coeff[i];
end

//PIPELINE STAGES

// Stage 1
always @(posedge clk) begin
    for (i = 0; i < S1; i = i + 1)
        stage1[i] <= (2*i+1 < TAPS) ? (mult[2*i] + mult[2*i+1]) : mult[2*i];
end

// Stage 2
always @(posedge clk) begin
    for (i = 0; i < S2; i = i + 1)
        stage2[i] <= (2*i+1 < S1) ? (stage1[2*i] + stage1[2*i+1]) : stage1[2*i];
end

// Stage 3
always @(posedge clk) begin
    for (i = 0; i < S3; i = i + 1)
        stage3[i] <= (2*i+1 < S2) ? (stage2[2*i] + stage2[2*i+1]) : stage2[2*i];
end

// Stage 4
always @(posedge clk) begin
    for (i = 0; i < S4; i = i + 1)
        stage4[i] <= (2*i+1 < S3) ? (stage3[2*i] + stage3[2*i+1]) : stage3[2*i];
end

// Stage 5
always @(posedge clk) begin
    for (i = 0; i < S5; i = i + 1)
        stage5[i] <= (2*i+1 < S4) ? (stage4[2*i] + stage4[2*i+1]) : stage4[2*i];
end

// Stage 6
always @(posedge clk) begin
    for (i = 0; i < S6; i = i + 1)
        stage6[i] <= (2*i+1 < S5) ? (stage5[2*i] + stage5[2*i+1]) : stage5[2*i];
end

// Stage 7 (final)
always @(posedge clk) begin
    for (i = 0; i < S7; i = i + 1)
        stage7[i] <= (2*i+1 < S6) ? (stage6[2*i] + stage6[2*i+1]) : stage6[2*i];
end

//OUTPUT
always @(posedge clk) begin
    if (rst)
        y_out <= 0;
    else
        y_out <= stage7[0];
end

endmodule
