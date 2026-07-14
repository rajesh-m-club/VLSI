`timescale 1ns/1ps

module tb_DigitalBlock;

    // Parameters
    localparam WIDTH       = 10;
    localparam CLK_PERIOD  = 10; // 100 MHz

    // Testbench signals
    reg clk;
    reg rst_n;
    reg en;
    reg signed [WIDTH-1:0] ppg_in;

    wire [7:0] bpm_value;
    wire       bpm_valid;
    reg        bpm_copied;

    // Debug signals (exposed from DigitalBlock)
    wire signed [WIDTH-1:0] dbg_ppg_filt;
    wire       dbg_valid;
    wire       dbg_peak_pulse;
    wire [5:0] dbg_time_cnt;
    wire       dbg_interval_valid;

    integer fd_in, fd_out;
    integer r;
    integer sample_idx;
    reg [256*8:1] header_line; // to store skipped header

    // ------------------------
    // DUT instantiation
    // ------------------------
    DigitalBlock #(
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .ppg_in(ppg_in),

        .bpm_value(bpm_value),
        .bpm_valid(bpm_valid),
        .bpm_copied(bpm_copied),

        // Debug signals
        .dbg_ppg_filt(dbg_ppg_filt),
        .dbg_valid(dbg_valid),
        .dbg_peak_pulse(dbg_peak_pulse),
        .dbg_time_cnt(dbg_time_cnt),
        .dbg_interval_valid(dbg_interval_valid)
    );

    // ------------------------
    // Clock generation
    // ------------------------
    always #(CLK_PERIOD/2) clk = ~clk;

    // ------------------------
    // Stimulus
    // ------------------------
    initial begin
        clk = 0;
        rst_n = 0;
        en = 0;
        bpm_copied = 0;
        ppg_in = 0;
        sample_idx = 0;

        // ---- File paths ----
        fd_in  = $fopen("C:/Users/rajes/OneDrive/Desktop/VLSI/BPM_counter/DigitalBlock/pre_processing_filter/PreProcessing/ppg_input.csv", "r");
        fd_out = $fopen("C:/Users/rajes/OneDrive/Desktop/VLSI/BPM_counter/DigitalBlock/digitalblock_output.csv", "w");

        if (fd_in == 0) begin
            $display("❌ ERROR: Failed to open input file");
            $finish;
        end
        if (fd_out == 0) begin
            $display("❌ ERROR: Failed to open output file");
            $finish;
        end

        // Skip header line in input CSV (if present)
        r = $fgets(header_line, fd_in);

        // Write header in output CSV
        $fwrite(fd_out, "index,ppg_in,ppg_filt,valid_pre,peak_pulse,time_counter,interval_valid,bpm_value,bpm_valid\n");

        // ---- Reset sequence ----
        #(5*CLK_PERIOD);
        rst_n = 1;
        en = 1;

        // ---- Feed PPG samples ----
        while (!$feof(fd_in)) begin
            r = $fscanf(fd_in, "%d\n", ppg_in);
            #(CLK_PERIOD);

            $fwrite(fd_out, "%0d,%0d,%0d,%0b,%0b,%0d,%0b,%0d,%0b\n",
                sample_idx, ppg_in, dbg_ppg_filt, dbg_valid,
                dbg_peak_pulse, dbg_time_cnt, dbg_interval_valid,
                bpm_value, bpm_valid
            );

            // ---- Simulate BPM read handshake ----
            if (bpm_valid) begin
                bpm_copied = 1;
                #(CLK_PERIOD);
                bpm_copied = 0;
            end

            sample_idx = sample_idx + 1;
        end

        $fclose(fd_in);
        $fclose(fd_out);

        #100 $finish;
    end

endmodule
