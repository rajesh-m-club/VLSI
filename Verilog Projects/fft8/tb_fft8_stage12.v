`timescale 1ns/1ps

module tb_fft8_stage12_pairwise;

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
// Stage-2 outputs (PAIRWISE)
// ============================
wire signed [10:0] s2_sum1_r, s2_sum1_i;
wire signed [10:0] s2_sum2_r, s2_sum2_i;
wire signed [10:0] s2_diff1_r, s2_diff1_i;
wire signed [10:0] s2_diff2_r, s2_diff2_i;
wire s2_valid_out;

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
// Instantiate Stage-2 (PAIRWISE VERSION)
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
    .valid_out(s2_valid_out)
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
// VCD
// ============================
initial begin
    $dumpfile("stage12_wave.vcd");
    $dumpvars(0, tb_fft8_stage12_pairwise);
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

    fout = $fopen("stage12_output.mem", "w");

    fr_real = $fopen("input_real.mem", "r");
    fr_imag = $fopen("input_imag.mem", "r");

    if (fr_real == 0 || fr_imag == 0) begin
        $display("ERROR opening input files");
        $finish;
    end

    #20;
    rst = 0;
    #10;
    valid_in = 1;

    // feed 8 samples
    for (i = 0; i < 8; i = i + 1) begin
        status_r = $fscanf(fr_real, "%d\n", xr);
        status_i = $fscanf(fr_imag, "%d\n", xi);

        if (status_r != 1 || status_i != 1)
            $display("ERROR reading input at %0d", i);

        #10;
    end

    valid_in = 0;
    xr = 0;
    xi = 0;

    #200;

    $fclose(fr_real);
    $fclose(fr_imag);
    $fclose(fout);

    $finish;
end

// ============================
// Capture Stage-2 outputs
// ============================
integer out_count = 0;

always @(posedge clk) begin
    if (s2_valid_out) begin
        $display("OUT %0d: SUM1=(%d,%d) SUM2=(%d,%d) DIFF1=(%d,%d) DIFF2=(%d,%d)",
                  out_count,
                  s2_sum1_r, s2_sum1_i,
                  s2_sum2_r, s2_sum2_i,
                  s2_diff1_r, s2_diff1_i,
                  s2_diff2_r, s2_diff2_i);

        $fwrite(fout, "%d %d %d %d %d %d %d %d\n",
                  s2_sum1_r, s2_sum1_i,
                  s2_sum2_r, s2_sum2_i,
                  s2_diff1_r, s2_diff1_i,
                  s2_diff2_r, s2_diff2_i);

        out_count = out_count + 1;
    end
end

endmodule