`timescale 1ns/1ps

module tb_lpf_direct;

parameter TAPS = 101;
parameter DATA_LEN = 1000;

reg clk;
reg rst;

reg signed [16:0] x_in1, x_in2, x_in3;
wire signed [40:0] y_out1, y_out2, y_out3;

// DUT instances (NO coff port now)
lpf_direct #(.TAPS(TAPS)) dut1 (
    .clk(clk),
    .rst(rst),
    .x_in(x_in1),
    .y_out(y_out1)
);

lpf_direct #(.TAPS(TAPS)) dut2 (
    .clk(clk),
    .rst(rst),
    .x_in(x_in2),
    .y_out(y_out2)
);

lpf_direct #(.TAPS(TAPS)) dut3 (
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

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    // Open sine input file
    infile = $fopen("multi_sine_Q3_14_columns.mem","r");

    // Open output files
    outfile1 = $fopen("output_direct_1.mem","w");
    outfile2 = $fopen("output_direct_2.mem","w");
    outfile3 = $fopen("output_direct_3.mem","w");

    // Reset
    rst = 1;
    x_in1 = 0;
    x_in2 = 0;
    x_in3 = 0;
    #20;
    rst = 0;

    // Feed input samples
    for(i=0; i<DATA_LEN; i=i+1) begin

        r = $fscanf(infile,"%b %b %b\n", temp1, temp2, temp3);

        @(posedge clk);
        x_in1 = temp1;
        x_in2 = temp2;
        x_in3 = temp3;

        $fwrite(outfile1,"%b\n", y_out1);
        $fwrite(outfile2,"%b\n", y_out2);
        $fwrite(outfile3,"%b\n", y_out3);
    end

    // Flush filter pipeline (important)
    for(i=0; i<TAPS; i=i+1) begin
        @(posedge clk);
        x_in1 = 0;
        x_in2 = 0;
        x_in3 = 0;

        $fwrite(outfile1,"%b\n", y_out1);
        $fwrite(outfile2,"%b\n", y_out2);
        $fwrite(outfile3,"%b\n", y_out3);
    end

    $fclose(infile);
    $fclose(outfile1);
    $fclose(outfile2);
    $fclose(outfile3);
    $finish;

end
endmodule