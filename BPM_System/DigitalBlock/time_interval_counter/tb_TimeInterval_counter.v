`timescale 1ns/1ps

module tb_TimeInterval_counter;

    // Testbench signals
    reg clk;
    reg rst_n;
    reg peak_detected;
    reg en;
    reg BPMCalc_Done;
    wire [5:0] time_counter;
    wire valid;

    integer fd; // file descriptor

    // DUT instantiation
    TimeInterval_counter dut (
        .clk(clk),
        .rst_n(rst_n),
        .peak_detected(peak_detected),
        .en(en),
        .BPMCalc_Done(BPMCalc_Done),
        .time_counter(time_counter),
        .valid(valid)
    );

    // Clock generation: 10ns period -> 100MHz
    always #5 clk = ~clk;

    // Logging
    initial begin
        fd = $fopen("C:/Users/rajes/OneDrive/Desktop/VLSI/BPM_counter/time_interval_counter/time_interval_output.csv", "w");
        if (fd == 0) begin
            $display("Error opening time_interval_output.csv file!");
            $finish;
        end
        // CSV header
        $fdisplay(fd, "time_ns,clk,rst_n,en,peak_detected,time_counter,valid,BPMCalc_Done");
    end

    // Log values only when events happen
    always @(posedge clk) begin
        if (valid || peak_detected || BPMCalc_Done) begin
            $fdisplay(fd, "%0t,%0b,%0b,%0b,%0b,%0d,%0b,%0b",
                      $time, clk, rst_n, en, peak_detected,
                      time_counter, valid, BPMCalc_Done);
        end
    end

    // Stimulus
    initial begin
        // Initialize
        clk = 0;
        rst_n = 0;
        peak_detected = 0;
        en = 0;
        BPMCalc_Done = 0;

        // Release reset
        #20 rst_n = 1;
        en = 1;

        // First peak (start counting)
        #30 peak_detected = 1;  
        #10 peak_detected = 0;

        // Let counter run
        #100;

        // Second peak (stop counter, valid=1)
        peak_detected = 1;
        #10 peak_detected = 0;

        // Wait 6 clocks (60ns)
        repeat(6) @(posedge clk);

        // Now give BPMCalc_Done
        BPMCalc_Done = 1;
        #10 BPMCalc_Done = 0;

        // Let FSM go back to Idle
        #50;

        // Another measurement cycle
        peak_detected = 1;
        #10 peak_detected = 0;
        #80;
        peak_detected = 1;
        #10 peak_detected = 0;
        repeat(6) @(posedge clk);
        BPMCalc_Done = 1;
        #10 BPMCalc_Done = 0;

        #50;

        $fclose(fd);
        $finish;
    end

endmodule
