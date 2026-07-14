`timescale 1ns/1ps

module tb_lpf_genvar;

parameter TAPS_OPP = 50;
parameter FIR_LEN  = 2*TAPS_OPP + 1;
parameter DATA_LEN = 1000;

reg clk;
reg rst;

reg  signed [16:0] x_in1, x_in2, x_in3;
wire signed [40:0] y_out1, y_out2, y_out3;

// DUT instances (NO coeff ports now)
lpf_genvar #(.TAPS_OPP(TAPS_OPP)) dut1 (
    .clk(clk),
    .rst(rst),
    .x_in(x_in1),
    .y_out(y_out1)
);

lpf_genvar #(.TAPS_OPP(TAPS_OPP)) dut2 (
    .clk(clk),
    .rst(rst),
    .x_in(x_in2),
    .y_out(y_out2)
);

lpf_genvar #(.TAPS_OPP(TAPS_OPP)) dut3 (
    .clk(clk),
    .rst(rst),
    .x_in(x_in3),
    .y_out(y_out3)
);

integer infile;
integer outfile1, outfile2, outfile3;
integer r;
integer i;

reg signed [16:0] temp1, temp2, temp3;

// Clock
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    infile   = $fopen("multi_sine_Q3_14_columns.mem","r");
    outfile1 = $fopen("output_genvar_1.mem","w");
    outfile2 = $fopen("output_genvar_2.mem","w");
    outfile3 = $fopen("output_genvar_3.mem","w");

    if (infile == 0) begin
        $display("ERROR: Cannot open input file.");
        $stop;
    end

    // Reset
    rst = 1;
    x_in1 = 0;
    x_in2 = 0;
    x_in3 = 0;

    repeat(5) @(posedge clk);
    rst = 0;

    // Feed input
    for (i = 0; i < DATA_LEN; i = i + 1) begin

        r = $fscanf(infile,"%b %b %b\n", temp1, temp2, temp3);

        @(posedge clk);

        x_in1 <= temp1;
        x_in2 <= temp2;
        x_in3 <= temp3;

        $fwrite(outfile1,"%b\n", y_out1);
        $fwrite(outfile2,"%b\n", y_out2);
        $fwrite(outfile3,"%b\n", y_out3);
    end

    // Flush filter
    for (i = 0; i < FIR_LEN; i = i + 1) begin
        @(posedge clk);

        x_in1 <= 0;
        x_in2 <= 0;
        x_in3 <= 0;

        $fwrite(outfile1,"%b\n", y_out1);
        $fwrite(outfile2,"%b\n", y_out2);
        $fwrite(outfile3,"%b\n", y_out3);
    end

    $fclose(infile);
    $fclose(outfile1);
    $fclose(outfile2);
    $fclose(outfile3);

    $display("Genvar LPF verification completed.");
    $finish;
end

endmodule