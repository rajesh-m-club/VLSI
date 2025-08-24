`timescale 1us/1ns   // use microseconds for easier UART timing view

module tb_UART_tx;

    // -------------------------------
    // Parameters
    // -------------------------------
    localparam CLK_FREQ   = 1_000_000;   // 1 MHz test clock
    localparam BAUD       = 9600;        // UART baud
    localparam BAUD_DIV   = CLK_FREQ / BAUD;

    // -------------------------------
    // DUT signals
    // -------------------------------
    reg        clk;
    reg        rst_n;
    reg        tx_start;
    reg  [7:0] data_in;
    wire       tx;
    wire       busy;

    // -------------------------------
    // Instantiate UART transmitter
    // -------------------------------
    UART_tx #(.BAUD_DIV(BAUD_DIV)) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .data_in(data_in),
        .tx(tx),
        .busy(busy)
    );

    // -------------------------------
    // Clock generation (1 MHz = 1 us period)
    // -------------------------------
    initial clk = 0;
    always #0.5 clk = ~clk;   // 1 us period → 1 MHz

    // -------------------------------
    // Stimulus
    // -------------------------------
    initial begin
        // Dump VCD for GTKWave
        $dumpfile("UART_tx_tb.vcd");
        $dumpvars(0, tb_UART_tx);

        // Reset
        rst_n = 0;
        tx_start = 0;
        data_in  = 8'h00;
        #10;
        rst_n = 1;

        // Send first BPM value = 85
        @(negedge clk);
        data_in  = 8'd85;    // 0b01010101
        tx_start = 1;
        @(negedge clk);
        tx_start = 0;

        // Wait for transmission complete
        wait (!busy);
        #100;

        // Send second BPM value = 120
        @(negedge clk);
        data_in  = 8'd120;   // 0b01111000
        tx_start = 1;
        @(negedge clk);
        tx_start = 0;

        wait (!busy);
        #200;

        $finish;
    end

endmodule
