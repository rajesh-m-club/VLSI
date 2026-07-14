`timescale 1ns/1ps

module tb_fft8_stage1;

reg clk;
reg rst;
reg signed [7:0] xr, xi;
reg valid_in;

// ============================
// DUT outputs (UPDATED)
// ============================
wire signed [8:0] sum_r, sum_i;
wire signed [8:0] diff_r, diff_i;
wire valid_out;

// ============================
// Instantiate DUT
// ============================
fft8_stage1 dut (
    .clk(clk),
    .rst(rst),
    .xr(xr),
    .xi(xi),
    .valid_in(valid_in),
    .sum_r(sum_r),
    .sum_i(sum_i),
    .diff_r(diff_r),
    .diff_i(diff_i),
    .valid_out(valid_out)
);

// ============================
// Clock
// ============================
always #5 clk = ~clk;

// ============================
// File handles
// ============================
integer fr_real, fr_imag;
integer status_r, status_i;

// ============================
// Output file
// ============================
integer fout;

// ============================
// VCD dump
// ============================
initial begin
    $dumpfile("stage1_wave.vcd");
    $dumpvars(0, tb_fft8_stage1);
end

// ============================
// Test sequence
// ============================
integer i;

initial begin
    clk = 0;
    rst = 1;
    valid_in = 0;
    xr = 0;
    xi = 0;

    fout = $fopen("stage1_output.mem", "w");

    // ============================
    // Open input files
    // ============================
    fr_real = $fopen("input_real.mem", "r");
    fr_imag = $fopen("input_imag.mem", "r");

    if (fr_real == 0 || fr_imag == 0) begin
        $display("ERROR: Cannot open input files");
        $finish;
    end

    // Reset
    #20;
    rst = 0;

    // Start input
    #10;
    valid_in = 1;

    // ============================
    // Feed 8 samples
    // ============================
    for (i = 0; i < 8; i = i + 1) begin
        status_r = $fscanf(fr_real, "%d\n", xr);
        status_i = $fscanf(fr_imag, "%d\n", xi);

        if (status_r != 1 || status_i != 1) begin
            $display("ERROR reading input at i=%0d", i);
        end

        #10;
    end

    // Stop input
    valid_in = 0;
    xr = 0;
    xi = 0;

    // Wait for pipeline to flush
    #100;

    $fclose(fr_real);
    $fclose(fr_imag);
    $fclose(fout);

    $finish;
end

// ============================
// Capture outputs
// ============================
integer out_count = 0;

always @(posedge clk) begin
    if (valid_out) begin
        $display("OUT %0d: SUM=(%d,%d) DIFF=(%d,%d)", 
                  out_count, sum_r, sum_i, diff_r, diff_i);

        // store in file
        $fwrite(fout, "%d %d %d %d\n", sum_r, sum_i, diff_r, diff_i);

        out_count = out_count + 1;
    end
end

endmodule