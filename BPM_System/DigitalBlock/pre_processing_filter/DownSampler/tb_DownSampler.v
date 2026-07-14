`timescale 1us/1ns

module tb_DownSampler;

    parameter Width = 10;

    reg clk;
    reg rst_n;
    reg en;
    reg signed [Width-1:0] data_in;
    wire signed [Width-1:0] data_out;
    wire valid_out;

    // Instantiate downsampler
    DownSampler #(.Width(Width)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),                 // Added enable connection
        .data_in(data_in),
        .data_out(data_out),
        .valid_out(valid_out)
    );

    // Clock: 1 kHz (period 1000 us)
    initial clk = 0;
    always #500 clk = ~clk;

    integer i;
    integer fd;

    initial begin
        // Open CSV file for writing
        fd = $fopen("C:/Users/rajes/OneDrive/Desktop/VLSI/BPM_counter/pre_processing_filter/DownSampler/downsampled_output.csv", "w");
        $fwrite(fd, "time_us,data_in,data_out,valid_out\n");

        rst_n = 0;
        en = 0;
        data_in = 0;

        // Reset pulse
        #1500;
        rst_n = 1;

        // Enable after reset
        en = 1;

        // Feed known input sequence for 20 cycles
        for (i = 0; i < 20; i = i + 1) begin
            @(negedge clk);
            data_in = i;
            @(posedge clk);
            if (valid_out) begin
                $display("Time %0t: data_in = %0d, data_out = %0d, valid_out = %b",
                         $time, data_in, data_out, valid_out);
                $fwrite(fd, "%0t,%0d,%0d,%0b\n", $time, data_in, data_out, valid_out);
            end
        end

        // Disable mid-way to test idle behavior
        en = 0;
        repeat (5) @(posedge clk);

        $fclose(fd);
        $stop;
    end

endmodule
