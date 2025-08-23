`timescale 1ns/1ps

module tb_PeakDetector;

    parameter WIDTH = 10;

    // Testbench signals
    reg clk;
    reg rst_n;
    reg en;
    reg valid_in;
    reg signed [WIDTH-1:0] tb_ppg_in;
    wire peak_detected;

    integer input_file, output_file, status;
    integer sample_index;
    reg [100*8:1] header1, header2; 
    integer file_ppg_in, dummy;     

    // Instantiate DUT (Downsampled version but named PeakDetector)
    PeakDetector #(
        .WIDTH(WIDTH),
        .THRESH(20),
        .REF_PERIOD(8)    // refractory period in valid samples
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .ppg_in(tb_ppg_in),
        .valid_in(valid_in),
        .peak_detected(peak_detected)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 20 ns period (50 MHz)
    end

    // Reset and enable sequence
    initial begin
        rst_n    = 0;
        en       = 0;
        valid_in = 0;
        #50 rst_n = 1;
        #20 en    = 1; 
    end

    // Main stimulus process
    initial begin
        sample_index = 0;

        // Open files
        input_file  = $fopen("C:/Users/rajes/OneDrive/Desktop/VLSI/BPM_counter/DigitalBlock/pre_processing_filter/PreProcessing/ppg_output.csv", "r");
        output_file = $fopen("C:/Users/rajes/OneDrive/Desktop/VLSI/BPM_counter/DigitalBlock/peak_detector/peak_output.csv", "w");

        if (input_file == 0) begin
            $display("❌ Error: Could not open input file.");
            $finish;
        end

        if (output_file == 0) begin
            $display("❌ Error: Could not open output file.");
            $finish;
        end

        $display("✅ Simulation started. Reading PPG samples...");

        // Skip header line
        status = $fscanf(input_file, "%s,%s\n", header1, header2);

        // Read and feed samples
        while (!$feof(input_file)) begin
            status = $fscanf(input_file, "%d,%d\n", dummy, file_ppg_in);

            if (status == 2) begin
                tb_ppg_in = file_ppg_in;

                // Apply sample with valid_in
                @(posedge clk);
                valid_in <= 1;

                // Log output: index, input, peak_detected
                $fdisplay(output_file, "%0d,%0d,%0d", sample_index, tb_ppg_in, peak_detected);
                sample_index = sample_index + 1;

                @(posedge clk);
                valid_in <= 0;
            end
        end

        $display("✅ Simulation finished. Results written to peak_output.csv");

        $fclose(input_file);
        $fclose(output_file);
        $finish;
    end

endmodule
