
module DigitalBlock #(
    parameter WIDTH = 10,
    parameter SCALE = 15,
    parameter FS    = 25
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   en,
    input  wire signed [WIDTH-1:0] ppg_in,

    output wire [7:0]             bpm_value,
    output wire                   bpm_valid,
    input  wire                   bpm_copied

    // ================= DEBUG PORTS =================
    //output wire signed [WIDTH-1:0] dbg_ppg_filt,
    //output wire                    dbg_valid,
    //output wire                    dbg_peak_pulse,
    //output wire [5:0]              dbg_time_cnt,
    //output wire                    dbg_interval_valid
);

    // ----------------------------------------------
    // Internal connections
    // ----------------------------------------------
    wire signed [WIDTH-1:0] filt_out;
    wire                    valid_pre;
    wire                    peak_pulse;
    wire [5:0]              time_cnt;
    wire                    interval_valid;

    // ---------------- PreProcessing ----------------
    PreProcessing #(
        .Width(WIDTH),
        .SCALE(SCALE)
    ) u_PreProcessing (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .ppg_in(ppg_in),
        .ppg_out(filt_out),
        .valid_out(valid_pre)
    );

    // ---------------- Peak Detector ----------------
    PeakDetector #(
        .WIDTH(WIDTH),
        .THRESH(20),
        .REF_PERIOD(8)
    ) u_PeakDetector (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .ppg_in(filt_out),
        .valid_in(valid_pre),
        .peak_detected(peak_pulse)
    );

    // ----------- Time Interval Counter -------------
    TimeInterval_counter u_TimeInterval_counter (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .valid_pre(valid_pre),
        .peak_detected(peak_pulse),
        .BPMCalc_Done(bpm_valid),   // connected here
        .time_counter(time_cnt),
        .valid(interval_valid)
    );

    // --------------- BPM Calculator ----------------
    BPM_Calculator #(
        .WIDTH(6),
        .FS(FS)
    ) u_BPM_Calculator (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .interval_count(time_cnt),
        .interval_valid(interval_valid),
        .bpm_value(bpm_value),
        .bpm_valid(bpm_valid),
        .bpm_copied(bpm_copied)
    );

    // ----------------------------------------------
    // Debug signal mapping
    // ----------------------------------------------
    //assign dbg_ppg_filt       = filt_out;
    //assign dbg_valid          = valid_pre;
    //assign dbg_peak_pulse     = peak_pulse;
    //assign dbg_time_cnt       = time_cnt;
    //assign dbg_interval_valid = interval_valid;

endmodule
