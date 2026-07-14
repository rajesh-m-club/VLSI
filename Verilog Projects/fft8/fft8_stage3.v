`timescale 1ns/1ps
module fft8_stage3 (
    input clk,
    input rst,

    // inputs from Stage-2
    input signed [10:0] sum_in1_r, sum_in1_i,
    input signed [10:0] sum_in2_r, sum_in2_i,
    input signed [10:0] diff_in1_r, diff_in1_i,
    input signed [10:0] diff_in2_r, diff_in2_i,
    input valid_in,

    // outputs
    output reg signed [12:0] X0_r, X0_i,
    output reg signed [12:0] X4_r, X4_i,
    output reg signed [12:0] X2_r, X2_i,
    output reg signed [12:0] X6_r, X6_i,
    output reg valid_out
);

    // ============================
    // Pair selector
    // ============================
    reg pair_cnt;

    // ============================
    // Twiddle factors (Q1.7)
    // ============================
    reg signed [7:0] wr1, wi1;
    reg signed [7:0] wr2, wi2;

    always @(*) begin
        case(pair_cnt)
            1'b0: begin
                wr1 = 8'sd127;  wi1 = 8'sd0;     // W0
                wr2 = 8'sd0;    wi2 = -8'sd127;  // W2
            end
            1'b1: begin
                wr1 = 8'sd91;   wi1 = -8'sd91;   // W1
                wr2 = -8'sd91;  wi2 = -8'sd91;   // W3
            end
        endcase
    end

    // ============================
    // Complex Multiply (scaled once)
    // ============================
    wire signed [18:0] mult1_r, mult1_i;
    wire signed [18:0] mult2_r, mult2_i;

    assign mult1_r = (diff_in1_r * wr1 - diff_in1_i * wi1) >>> 7;
    assign mult1_i = (diff_in1_r * wi1 + diff_in1_i * wr1) >>> 7;

    assign mult2_r = (diff_in2_r * wr2 - diff_in2_i * wi2) >>> 7;
    assign mult2_i = (diff_in2_r * wi2 + diff_in2_i * wr2) >>> 7;

    // ============================
    // Trim to 13-bit (NO extra scaling)
    // ============================
    wire signed [12:0] m1_r_s, m1_i_s;
    wire signed [12:0] m2_r_s, m2_i_s;

    assign m1_r_s = mult1_r[12:0];
    assign m1_i_s = mult1_i[12:0];
    assign m2_r_s = mult2_r[12:0];
    assign m2_i_s = mult2_i[12:0];

    // ============================
    // Sign Extension of inputs
    // ============================
    wire signed [12:0] s1_r, s1_i;
    wire signed [12:0] s2_r, s2_i;

    assign s1_r = { {2{sum_in1_r[10]}}, sum_in1_r };
    assign s1_i = { {2{sum_in1_i[10]}}, sum_in1_i };

    assign s2_r = { {2{sum_in2_r[10]}}, sum_in2_r };
    assign s2_i = { {2{sum_in2_i[10]}}, sum_in2_i };

    // ============================
    // Output logic
    // ============================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            X0_r <= 0; X0_i <= 0;
            X4_r <= 0; X4_i <= 0;
            X2_r <= 0; X2_i <= 0;
            X6_r <= 0; X6_i <= 0;
            valid_out <= 0;
            pair_cnt <= 0;
        end else begin
            valid_out <= 0;

            if (valid_in) begin

                // FFT butterfly
                X0_r <= s1_r + m1_r_s;
                X0_i <= s1_i + m1_i_s;

                X4_r <= s1_r - m1_r_s;
                X4_i <= s1_i - m1_i_s;

                X2_r <= s2_r + m2_r_s;
                X2_i <= s2_i + m2_i_s;

                X6_r <= s2_r - m2_r_s;
                X6_i <= s2_i - m2_i_s;

                valid_out <= 1;

                // Toggle pair
                pair_cnt <= ~pair_cnt;
            end
        end
    end

endmodule