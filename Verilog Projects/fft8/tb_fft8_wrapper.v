`timescale 1ns/1ps
module tb_fft8_wrapper;

    reg clk;
    reg rst;
    reg signed [7:0] xr, xi;
    reg valid_in;

    // ============================
    // Wrapper outputs
    // ============================
    wire signed [12:0] X0_r, X0_i;
    wire signed [12:0] X4_r, X4_i;
    wire signed [12:0] X2_r, X2_i;
    wire signed [12:0] X6_r, X6_i;
    wire valid_out;

    // ============================
    // Instantiate Wrapper
    // ============================
    fft8_wrapper fft_wrap (
        .clk(clk),
        .rst(rst),
        .xr(xr),
        .xi(xi),
        .valid_in(valid_in),
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
    // Output storage
    // ============================
    reg signed [12:0] out_r [0:7];
    reg signed [12:0] out_i [0:7];
    reg valid_cycle_count; // 0 → first, 1 → second

    // ============================
    // VCD
    // ============================
    initial begin
        $dumpfile("fft8_wrapper.vcd");
        $dumpvars(0, tb_fft8_wrapper);
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
        valid_cycle_count = 0;

        fout = $fopen("fft8_output_ordered.mem", "w");

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

        valid_in = 0;
        xr = 0;
        xi = 0;

        // wait for pipeline
        #300;

        $display("TIMEOUT - No complete FFT captured");
        $finish;
    end

    // ============================
    // Capture outputs (CORRECTED)
    // ============================
    always @(posedge clk) begin
        if (valid_out) begin

            if (valid_cycle_count == 0) begin
                // FIRST valid → X0,X2,X4,X6
                out_r[0] <= X0_r; out_i[0] <= X0_i;
                out_r[2] <= X2_r; out_i[2] <= X2_i;
                out_r[4] <= X4_r; out_i[4] <= X4_i;
                out_r[6] <= X6_r; out_i[6] <= X6_i;

                valid_cycle_count <= 1;
            end
            else begin
                // SECOND valid → X1,X3,X5,X7
                out_r[1] <= X0_r; out_i[1] <= X0_i;
                out_r[3] <= X2_r; out_i[3] <= X2_i;
                out_r[5] <= X4_r; out_i[5] <= X4_i;
                out_r[7] <= X6_r; out_i[7] <= X6_i;

                // small delay to ensure values settle
                #1;

                // write outputs
                for (i = 0; i < 8; i = i + 1) begin
                    $fwrite(fout, "%d %d\n", out_r[i], out_i[i]);
                    $display("X[%0d] = (%d,%d)", i, out_r[i], out_i[i]);
                end

                valid_cycle_count <= 0;

                $fclose(fout);
                $finish;
            end
        end
    end

endmodule