`timescale 1us/1ns   // 1us time unit, 1ns precision

module tb_LPF;

    // Parameters
    localparam Width = 10;
    localparam SCALE = 15;

    // Testbench signals
    reg clk;
    reg rst_n;
    reg en;  // NEW enable pin
    reg signed [Width-1:0] x_in;
    wire signed [Width-1:0] y_out;

    // File handle for CSV logging
    integer f;

    // Instantiate LPF
    LPF #(
        .Width(Width),
        .SCALE(SCALE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),       // connected
        .x_in(x_in),
        .y_out(y_out)
    );

    // Clock generation: 1 kHz => 1 ms period
    initial clk = 0;
    always #500 clk = ~clk; // 500 us high/low

    // Open CSV file
    initial begin
        f = $fopen("C:/Users/rajes/OneDrive/Desktop/VLSI/BPM_counter/DigitalBlock/pre_processing_filter/LPF/lpf_output.csv", "w");
        if (f == 0) begin
            $display("ERROR: Could not open CSV file!");
            $stop;
        end
        $fwrite(f, "time_us,x_in,y_out\n");
    end

    // Write data every clock
    always @(posedge clk) begin
        $fwrite(f, "%0t,%0d,%0d\n", $time, x_in, y_out);
    end

    // Stimulus
    initial begin
        // Init
        rst_n = 0;
        en    = 0;
        x_in  = 0;
        #2000;

        // Release reset
        rst_n = 1;
        en    = 1;

        // Test 1: Step response
        x_in = 10;
        repeat(20) @(posedge clk);

        // Test 2: Impulse response
        x_in = 50;
        @(posedge clk);
        x_in = 0;
        repeat(20) @(posedge clk);

        // Test 3: Low frequency sine
        repeat(40) begin
            x_in = $rtoi(30.0 * $sin(2.0 * 3.14159265 * 0.05 * $time/1000.0));
            @(posedge clk);
        end

        // Test 4: High frequency sine
        repeat(40) begin
            x_in = $rtoi(30.0 * $sin(2.0 * 3.14159265 * 0.4 * $time/1000.0));
            @(posedge clk);
        end

        // Test 5: Disable enable mid-run
        en = 0; // hold output
        repeat(5) @(posedge clk);
        en = 1; // resume
        repeat(5) @(posedge clk);

        // Test 6: Reset
        rst_n = 0;
        repeat(2) @(posedge clk);
        rst_n = 1;
        repeat(10) @(posedge clk);

        // Close CSV file and stop simulation
        $fclose(f);
        $stop;
    end

endmodule
