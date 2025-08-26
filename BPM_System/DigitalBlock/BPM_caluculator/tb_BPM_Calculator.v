`timescale 1ns/1ps

module tb_BPM_Calculator;

    parameter WIDTH = 6;
    parameter FS    = 25;

    reg clk;
    reg rst_n;
    reg en;
    reg [WIDTH-1:0] interval_count;
    reg interval_valid;

    wire [7:0] bpm_value;
    wire        bpm_valid;
    reg         bpm_copied;

    // File I/O
    integer fd_in, fd_out;
    integer r;
    integer time_ns;
    integer dummy_clk, dummy_rst, dummy_en, dummy_peak, dummy_valid, dummy_done;

    // DUT instantiation
    BPM_Calculator #(
        .WIDTH(WIDTH),
        .FS(FS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .interval_count(interval_count),
        .interval_valid(interval_valid),
        .bpm_value(bpm_value),
        .bpm_valid(bpm_valid),
        .bpm_copied(bpm_copied)
    );

    // Clock generation
    always #5 clk = ~clk;  // 100MHz clock

    initial begin
        // Init
        clk = 0;
        rst_n = 0;
        en = 0;
        interval_count = 0;
        interval_valid = 0;
        bpm_copied = 0;

        // Open files
        fd_in  = $fopen("C:/Users/rajes/OneDrive/Desktop/VLSI/BPM_counter/time_interval_counter/time_interval_output.csv", "r");
        fd_out = $fopen("C:/Users/rajes/OneDrive/Desktop/VLSI/BPM_counter/BPM_caluculator/bpm_output.csv", "w");

        if (fd_in == 0 || fd_out == 0) begin
            $display("ERROR: Cannot open file(s).");
            $finish;
        end

        // Write output file header
        $fwrite(fd_out, "time_ns,interval_count,bpm_value,bpm_valid\n");

        // Reset
        #20 rst_n = 1;
        en = 1; // enable stays high (from Calc_BPM pulse)

        // Skip CSV header
        r = $fscanf(fd_in, "%s\n", dummy_clk);

        // Read input CSV line by line
        while (!$feof(fd_in)) begin
            r = $fscanf(fd_in, "%d,%d,%d,%d,%d,%d,%d,%d\n",
                        time_ns, dummy_clk, dummy_rst, dummy_en,
                        dummy_peak, interval_count, dummy_valid, dummy_done);

            // Apply stimulus
            interval_valid = dummy_peak;  // peak_detected pulse = valid interval
            #10; // wait one cycle

            // Write results
            $fwrite(fd_out, "%0d,%0d,%0d,%0d\n",
                    time_ns, interval_count, bpm_value, bpm_valid);

            // Handshake: simulate UART copying value after 2 cycles if valid
            if (bpm_valid) begin
                #20 bpm_copied = 1;
                #10 bpm_copied = 0;
            end
        end

        $fclose(fd_in);
        $fclose(fd_out);
        $finish;
    end

endmodule
