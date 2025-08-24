`timescale 1ns/1ps

module tb_FIFO;

    parameter WIDTH = 10;
    parameter DEPTH = 4;

    reg clk;
    reg reset;
    reg wr_en;
    reg rd_en;
    reg [WIDTH-1:0] Data_in;
    wire [WIDTH-1:0] Data_out;
    wire full;
    wire empty;

    // DUT instance
    ppg_interface #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) uut (
        .clk(clk),
        .reset(reset),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .Data_in(Data_in),
        .Data_out(Data_out),
        .full(full),
        .empty(empty)
    );

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        $dumpfile("fifo_tb.vcd");  // For GTKWave (optional)
        $dumpvars(0, tb_ppg_interface);

        // Initialize signals
        reset   = 1;
        wr_en   = 0;
        rd_en   = 0;
        Data_in = 0;

        // Apply reset
        #15 reset = 0;

        // STEP 1: Write 5 values
        $display("\n=== Writing 5 values ===");
        repeat (5) begin
            @(posedge clk);
            if (!full) begin
                wr_en   = 1;
                Data_in = $random % 1024; // 10-bit value
                $display("[%0t] Write: %0d (full=%b)", $time, Data_in, full);
            end else begin
                wr_en = 0;
            end
        end
        @(posedge clk) wr_en = 0;

        // STEP 2: Read 2 values
        $display("\n=== Reading 2 values ===");
        repeat (2) begin
            @(posedge clk);
            if (!empty) begin
                rd_en = 1;
                $display("[%0t] Read: %0d (empty=%b)", $time, Data_out, empty);
            end else begin
                rd_en = 0;
            end
        end
        @(posedge clk) rd_en = 0;

        // STEP 3: Write 2 more values
        $display("\n=== Writing 2 more values ===");
        repeat (2) begin
            @(posedge clk);
            if (!full) begin
                wr_en   = 1;
                Data_in = $random % 1024;
                $display("[%0t] Write: %0d (full=%b)", $time, Data_in, full);
            end else begin
                wr_en = 0;
            end
        end
        @(posedge clk) wr_en = 0;

        // STEP 4: Read 4 values
        $display("\n=== Reading 4 values ===");
        repeat (4) begin
            @(posedge clk);
            if (!empty) begin
                rd_en = 1;
                $display("[%0t] Read: %0d (empty=%b)", $time, Data_out, empty);
            end else begin
                rd_en = 0;
            end
        end
        @(posedge clk) rd_en = 0;

        // Finish simulation
        #20;
        $finish;
    end

endmodule
