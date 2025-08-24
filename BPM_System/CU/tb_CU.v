`timescale 1ns/1ps

module tb_CU;

    // Parameters
    localparam PPG_WIDTH     = 10;
    localparam CLK_FREQ_HZ   = 10_000_000;
    localparam SHOW_TIME_SEC = 3;

    // DUT signals
    reg                         clk;
    reg                         rst_n;
    reg                         check_btn;
    reg                         en;

    reg                         fifo_in_empty;
    reg  signed [PPG_WIDTH-1:0] fifo_in_dout;
    wire                        fifo_in_rd;

    wire                        db_en;
    wire signed [PPG_WIDTH-1:0] ppg_in;
    reg        [7:0]            bpm_value;
    reg                         bpm_valid;
    wire                        bpm_copied;

    wire       [7:0]            bpm_latest;
    wire                        bpm_ready_out;

    // DUT instantiation
    CU #(
        .PPG_WIDTH(PPG_WIDTH),
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .SHOW_TIME_SEC(SHOW_TIME_SEC)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .check_btn(check_btn),
        .en(en),
        .fifo_in_empty(fifo_in_empty),
        .fifo_in_rd(fifo_in_rd),
        .fifo_in_dout(fifo_in_dout),
        .db_en(db_en),
        .ppg_in(ppg_in),
        .bpm_value(bpm_value),
        .bpm_valid(bpm_valid),
        .bpm_copied(bpm_copied),
        .bpm_latest(bpm_latest),
        .bpm_ready_out(bpm_ready_out)
    );

    // -------------------------------------------------
    // Clock generation (10 MHz -> 100 ns period)
    // -------------------------------------------------
    initial clk = 0;
    always #50 clk = ~clk; // 100 ns period

    // -------------------------------------------------
    // Stimulus
    // -------------------------------------------------
    initial begin
        // Init
        rst_n       = 0;
        check_btn   = 0;
        en          = 1;
        fifo_in_empty = 1;
        fifo_in_dout  = 0;
        bpm_value     = 0;
        bpm_valid     = 0;

        // Reset pulse
        #200;
        rst_n = 1;
        #200;

        // ---- First check ----
        $display("[%0t] Pressing check button",$time);
        pulse_check();
        // Provide FIFO samples
        repeat (5) begin
            @(posedge clk);
            fifo_in_empty <= 0;
            fifo_in_dout  <= $random % 512;
            @(posedge clk);
            fifo_in_empty <= 1;
        end

        // After some delay, emulate bpm_valid from DB
        repeat (20) @(posedge clk);
        bpm_value <= 8'd72;
        bpm_valid <= 1;
        @(posedge clk);
        bpm_valid <= 0;

        // Wait ~1 sec of sim time
        repeat (10_000_000/100) @(posedge clk); // shorter wait for sim (not 3s real-time)

        // ---- Press check again while BPM is still showing ----
        $display("[%0t] Pressing check button again",$time);
        pulse_check();

        // Feed FIFO again
        repeat (5) begin
            @(posedge clk);
            fifo_in_empty <= 0;
            fifo_in_dout  <= $random % 512;
            @(posedge clk);
            fifo_in_empty <= 1;
        end

        // Fake new BPM
        repeat (20) @(posedge clk);
        bpm_value <= 8'd95;
        bpm_valid <= 1;
        @(posedge clk);
        bpm_valid <= 0;

        // Let timer expire
        repeat (1_000) @(posedge clk);

        $finish;
    end

    // -------------------------------------------------
    // Task: pulse check button
    // -------------------------------------------------
    task pulse_check;
    begin
        check_btn <= 1;
        repeat (2) @(posedge clk); // hold a bit
        check_btn <= 0;
    end
    endtask

    // -------------------------------------------------
    // Monitors
    // -------------------------------------------------
    initial begin
        $monitor("[%0t] state: bpm_latest=%0d bpm_ready_out=%b fifo_rd=%b db_en=%b",
                 $time, bpm_latest, bpm_ready_out, fifo_in_rd, db_en);
    end

endmodule
