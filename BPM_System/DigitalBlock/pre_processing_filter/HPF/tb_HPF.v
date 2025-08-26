`timescale 1ns/1ps

module tb_HPF;

    parameter CLK_PERIOD = 20;   // 50 MHz
    parameter Width = 10;

    reg clk;
    reg rst_n;
    reg en;  // NEW enable pin
    reg signed [Width-1:0] x_in;
    wire signed [Width-1:0] y_out;

    integer f;  // File handle
    integer i;

    // Instantiate the HPF
    HPF uut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .x_in(x_in),
        .y_out(y_out)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // Task to log data
    task log_data;
    begin
        $fwrite(f, "%0d,%0d\n", x_in, y_out);
    end
    endtask

    // Stimulus
    initial begin
        // Open CSV file
        f = $fopen("C:/Users/rajes/OneDrive/Desktop/VLSI/BPM_counter/DigitalBlock/pre_processing_filter/HPF/hpf_output_log.csv", "w");
        if (f == 0) begin
            $display("ERROR: Could not open log file.");
            $finish;
        end

        // CSV Header
        $fwrite(f, "Input,Output\n");

        clk = 0;
        rst_n = 0;
        en = 1; // enable always ON for same test cases
        x_in = 0;

        // Reset
        #(5*CLK_PERIOD);
        rst_n = 1;

        // Apply a low-frequency slow ramp (should be attenuated by HPF)
        for (i = 0; i < 50; i = i + 1) begin
            x_in = i;  // ramp
            log_data();
            #(CLK_PERIOD);
        end

        // Apply a high-frequency alternating pattern (should pass through HPF)
        for (i = 0; i < 50; i = i + 1) begin
            x_in = (i % 2) ? 200 : -200; // fast alternation
            log_data();
            #(CLK_PERIOD);
        end

        // Apply constant DC value (should be removed by HPF)
        for (i = 0; i < 30; i = i + 1) begin
            x_in = 300;
            log_data();
            #(CLK_PERIOD);
        end

        $fclose(f);
        $stop;
    end

endmodule

