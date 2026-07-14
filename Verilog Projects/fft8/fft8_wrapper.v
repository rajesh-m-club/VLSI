`timescale 1ns/1ps
module fft8_wrapper(
    input clk,
    input rst,
    input signed [7:0] xr,
    input signed [7:0] xi,
    input valid_in,

    output signed [12:0] X0_r, X0_i,
    output signed [12:0] X4_r, X4_i,
    output signed [12:0] X2_r, X2_i,
    output signed [12:0] X6_r, X6_i,
    output valid_out
);

    // ============================
    // Stage-1 outputs
    // ============================
    wire signed [8:0] s1_sum_r, s1_sum_i;
    wire signed [8:0] s1_diff_r, s1_diff_i;
    wire s1_valid;

    fft8_stage1 stage1 (
        .clk(clk),
        .rst(rst),
        .xr(xr),
        .xi(xi),
        .valid_in(valid_in),
        .sum_r(s1_sum_r),
        .sum_i(s1_sum_i),
        .diff_r(s1_diff_r),
        .diff_i(s1_diff_i),
        .valid_out(s1_valid)
    );

    // ============================
    // Stage-2 outputs (pairwise)
    // ============================
    wire signed [10:0] s2_sum1_r, s2_sum1_i;
    wire signed [10:0] s2_sum2_r, s2_sum2_i;
    wire signed [10:0] s2_diff1_r, s2_diff1_i;
    wire signed [10:0] s2_diff2_r, s2_diff2_i;
    wire s2_valid;

    fft8_stage2 stage2 (
        .clk(clk),
        .rst(rst),
        .sum_in_r(s1_sum_r),
        .sum_in_i(s1_sum_i),
        .diff_in_r(s1_diff_r),
        .diff_in_i(s1_diff_i),
        .valid_in(s1_valid),
        .sum1_r(s2_sum1_r),
        .sum1_i(s2_sum1_i),
        .sum2_r(s2_sum2_r),
        .sum2_i(s2_sum2_i),
        .diff1_r(s2_diff1_r),
        .diff1_i(s2_diff1_i),
        .diff2_r(s2_diff2_r),
        .diff2_i(s2_diff2_i),
        .valid_out(s2_valid)
    );

    // ============================
    // Stage-3 outputs
    // ============================
    fft8_stage3 stage3 (
        .clk(clk),
        .rst(rst),
        .sum_in1_r(s2_sum1_r),
        .sum_in1_i(s2_sum1_i),
        .sum_in2_r(s2_sum2_r),
        .sum_in2_i(s2_sum2_i),
        .diff_in1_r(s2_diff1_r),
        .diff_in1_i(s2_diff1_i),
        .diff_in2_r(s2_diff2_r),
        .diff_in2_i(s2_diff2_i),
        .valid_in(s2_valid),
        .X0_r(X0_r),
        .X0_i(X0_i),
        .X4_r(X4_r),
        .X4_i(X4_i),
        .X2_r(X2_r),
        .X2_i(X2_i),
        .X6_r(X6_r),
        .X6_i(X6_i),
        .valid_out(valid_out)
    );

endmodule