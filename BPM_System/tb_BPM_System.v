`timescale 1ns/1ps

module tb_BPM_System;

    // =====================================================
    // Parameters
    // =====================================================
    localparam CLK_PERIOD = 100;   // 10 MHz => 100 ns
    localparam PPG_WIDTH  = 10;

    reg clk;
    reg rst_n;
    reg check_btn;
    reg en;

    reg signed [PPG_WIDTH-1:0] sensor_ppg;

    wire [7:0] bpm_latest;
    wire       bpm_ready_out;

    // =====================================================
    // DUT instantiation
    // =====================================================
    BPM_System #(
        .PPG_WIDTH   (PPG_WIDTH),
        .FIFO_DEPTH  (1024),
        .CLK_FREQ_HZ (10_000_000)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .check_btn    (check_btn),
        .en           (en),
        .bpm_latest   (bpm_latest),
        .bpm_ready_out(bpm_ready_out),
        .sensor_ppg   (sensor_ppg)
    );

    // =====================================================
    // Clock generation
    // =====================================================
    always #(CLK_PERIOD/2) clk = ~clk;

    // =====================================================
    // Testbench variables
    // =====================================================
    integer infile, logfile;
    integer r;
    integer check_count;
    integer sample_count;
    reg [255:0] line;   // fixed-width reg instead of SystemVerilog string

    // =====================================================
    // Stimulus
    // =====================================================
    initial begin
        clk        = 0;
        rst_n      = 0;
        check_btn  = 0;
        en         = 1;
        sensor_ppg = 0;

        // open input CSV file
        infile = $fopen("C:/Users/rajes/OneDrive/Desktop/VLSI/BPM_counter/DigitalBlock/pre_processing_filter/PreProcessing/ppg_input.csv", "r");
        if (infile == 0) begin
            $display("ERROR: failed to open input CSV file!");
            $finish;
        end

        // open log file for writing
        logfile = $fopen("bpm_system_log.txt", "w");

        // Reset
        #(10*CLK_PERIOD);
        rst_n = 1;

        // feed PPG samples continuously
        sample_count = 0;
        // skip header line "PPG"
        r = $fgets(line, infile);
        while (!$feof(infile)) begin
            r = $fgets(line, infile);
            if (r != 0) begin
                r = $sscanf(line, "%d", sensor_ppg);
                sample_count = sample_count + 1;
            end
            #(CLK_PERIOD); // one sample per clock
        end
        $display("All PPG samples from CSV fed into DUT.");

        // wait a bit before first check
        #(500*CLK_PERIOD);

        // perform 4 checks with gaps
        for (check_count = 1; check_count <= 4; check_count = check_count + 1) begin
            // generate 1-cycle check pulse
            check_btn = 1;
            #(CLK_PERIOD);
            check_btn = 0;

            // wait for bpm_ready_out
            @(posedge bpm_ready_out);
            $display("Check %0d -> BPM = %0d", check_count, bpm_latest);
            $fwrite(logfile, "Check %0d -> BPM = %0d\n", check_count, bpm_latest);
            $fwrite(logfile, "    (Triggered at time %0t ns)\n", $time);

            // gap before next check
            #(2000*CLK_PERIOD);
        end

        $display("Simulation finished.");
        $fclose(infile);
        $fclose(logfile);
        $finish;
    end

endmodule
