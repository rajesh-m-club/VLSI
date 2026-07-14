`timescale 1ns/1ps
module tb_fft8_stage123_pairwise;

reg clk;
reg rst;
reg signed [7:0] xr, xi;
reg valid_in;

// ============================
// Stage-1 outputs
// ============================
wire signed [8:0] s1_sum_r, s1_sum_i;
wire signed [8:0] s1_diff_r, s1_diff_i;
wire s1_valid;

// ============================
// Stage-2 outputs (pairwise)
// ============================
wire signed [10:0] s2_sum1_r, s2_sum1_i;
wire signed [10:0] s2_sum2_r, s2_sum2_i;
wire signed [10:0] s2_diff1_r, s2_diff1_i;
wire signed [10:0] s2_diff2_r, s2_diff2_i;
wire s2_valid;

// ============================
// Stage-3 outputs (FINAL FFT)
// ============================
wire signed [12:0] X0_r, X0_i;
wire signed [12:0] X4_r, X4_i;
wire signed [12:0] X2_r, X2_i;
wire signed [12:0] X6_r, X6_i;
wire s3_valid;

// ============================
// Instantiate Stage-1
// ============================
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
// Instantiate Stage-2 (pairwise)
// ============================
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
// Instantiate Stage-3 (pairwise)
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
    .valid_out(s3_valid)
);

// ============================
// Clock
// ============================
always #5 clk = ~clk;

// ============================
// File I/O
// ============================
integer fr_real, fr_imag;
integer fout;
integer status_r, status_i;
integer i;

// ============================
// VCD dump
// ============================
initial begin
    $dumpfile("fft8_full_pairwise.vcd");
    $dumpvars(0, tb_fft8_stage123_pairwise);
end

// ============================
// Stimulus
// ============================
initial begin
    clk = 0;
    rst = 1;
    valid_in = 0;
    xr = 0;
    xi = 0;

    fout = $fopen("fft8_output_pairwise.mem", "w");

    fr_real = $fopen("input_real.mem", "r");
    fr_imag = $fopen("input_imag.mem", "r");

    if (fr_real == 0 || fr_imag == 0) begin
        $display("ERROR opening input files");
        $finish;
    end

    // Reset
    #20;
    rst = 0;

    // Start input
    #10;
    valid_in = 1;

    // Feed 8 samples
    for (i = 0; i < 8; i = i + 1) begin
        status_r = $fscanf(fr_real, "%d\n", xr);
        status_i = $fscanf(fr_imag, "%d\n", xi);

        if (status_r != 1 || status_i != 1)
            $display("ERROR reading input at %0d", i);

        #10;
    end

    // Stop input
    valid_in = 0;
    xr = 0;
    xi = 0;

    // Wait for pipeline flush
    #300;

    $fclose(fr_real);
    $fclose(fr_imag);
    $fclose(fout);

    $finish;
end

// ============================
// Capture FINAL FFT outputs
// ============================
integer out_count = 0;

always @(posedge clk) begin
    if (s3_valid) begin
        $display("OUT %0d: X0=(%d,%d)  X4=(%d,%d)  X2=(%d,%d)  X6=(%d,%d)",
                  out_count,
                  X0_r, X0_i,
                  X4_r, X4_i,
                  X2_r, X2_i,
                  X6_r, X6_i);

        $fwrite(fout, "%d %d\n", X0_r, X0_i);
        $fwrite(fout, "%d %d\n", X4_r, X4_i);
        $fwrite(fout, "%d %d\n", X2_r, X2_i);
        $fwrite(fout, "%d %d\n", X6_r, X6_i);

        out_count = out_count + 4;
    end
end

endmodule