// =============================================================
// BPM_System (Top Level Integration)
// - Sensor writes PPG samples into FIFO continuously
// - CU controls FIFO read + DigitalBlock enable during check session
// - DB calculates BPM from PPG stream
// - CU latches BPM and manages display timer
// =============================================================
`timescale 1ns/1ps

module BPM_System #(
    parameter integer PPG_WIDTH     = 10,
    parameter integer FIFO_DEPTH    = 1024,
    parameter integer CLK_FREQ_HZ   = 10_000_000  // 10 MHz system clock
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // ---- User interface ----
    input  wire                     check_btn,     // pushbutton to trigger check
    input  wire                     en,            // global enable (optional)
    output wire [7:0]               bpm_latest,    // latest BPM value latched
    output wire                     bpm_ready_out, // 1-cycle pulse when updated

    // ---- Sensor input ----
    input  wire signed [PPG_WIDTH-1:0] sensor_ppg   // continuous PPG samples
);

    // =============================================================
    // FIFO for incoming PPG samples
    // =============================================================
    wire fifo_full, fifo_empty;
    wire fifo_rd_en;
    wire signed [PPG_WIDTH-1:0] fifo_dout;

    // Write enable is ALWAYS high (sensor continuously writing samples)
    wire fifo_wr_en = 1'b1;

    FIFO #(
        .WIDTH (PPG_WIDTH),
        .DEPTH (FIFO_DEPTH)
    ) u_fifo (
        .clk   (clk),
        .reset (!rst_n),
        .wr_en (fifo_wr_en),
        .Data_in   (sensor_ppg),
        .full  (fifo_full),
        .rd_en (fifo_rd_en),
        .Data_out  (fifo_dout),
        .empty (fifo_empty)
    );

    // =============================================================
    // Wires between CU and DigitalBlock
    // =============================================================
    wire db_en;
    wire signed [PPG_WIDTH-1:0] ppg_in;
    wire [7:0] bpm_value;
    wire bpm_valid;
    wire bpm_copied;

    // =============================================================
    // Control Unit (manages FIFO read + DB handshakes)
    // =============================================================
    CU #(
        .PPG_WIDTH    (PPG_WIDTH),
        .CLK_FREQ_HZ  (CLK_FREQ_HZ),
        .SHOW_TIME_SEC(3)
    ) u_cu (
        .clk          (clk),
        .rst_n        (rst_n),
        .check_btn    (check_btn),
        .en           (en),

        // FIFO interface
        .fifo_in_empty(fifo_empty),
        .fifo_in_rd   (fifo_rd_en),
        .fifo_in_dout (fifo_dout),

        // DigitalBlock interface
        .db_en        (db_en),
        .ppg_in       (ppg_in),
        .bpm_value    (bpm_value),
        .bpm_valid    (bpm_valid),
        .bpm_copied   (bpm_copied),

        // Output to UI/Display
        .bpm_latest   (bpm_latest),
        .bpm_ready_out(bpm_ready_out)
    );

    // =============================================================
    // DigitalBlock (BPM calculation logic)
    // =============================================================
    DigitalBlock #(
        .WIDTH (PPG_WIDTH),
        .SCALE (15),
        .FS (25)
    ) u_db (
        .clk       (clk),
        .rst_n     (rst_n),
        .en        (db_en),
        .ppg_in    (ppg_in),
        .bpm_value (bpm_value),
        .bpm_valid (bpm_valid),
        .bpm_copied(bpm_copied)
    );

endmodule
