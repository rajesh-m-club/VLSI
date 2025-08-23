`timescale 1ns/1ps

// =============================================================
// Integrated PreProcessing Module (HPF -> LPF -> DownSampler)
// Single enable pin for entire pipeline
// =============================================================
module PreProcessing #(
    parameter Width = 10,
    parameter SCALE = 15

)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     en,           // single enable
    input  wire signed [Width-1:0]  ppg_in,
    output wire signed [Width-1:0]  ppg_out,
    output wire                     valid_out
);

    // Internal signals
    wire signed [Width-1:0] hpf_out;
    wire signed [Width-1:0] lpf_out;

    // ===================== HPF =====================
    HPF #(
        .Width(Width),
        .SCALE(SCALE)
    ) u_HPF (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .x_in(ppg_in),
        .y_out(hpf_out)
    );

    // ===================== LPF =====================
    LPF #(
        .Width(Width),
        .SCALE(SCALE)
    ) u_LPF (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .x_in(hpf_out),
        .y_out(lpf_out)
    );

    // ================= DownSampler =================
    DownSampler #(
        .Width(Width)
    ) u_DownSampler (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .data_in(lpf_out),
        .data_out(ppg_out),
        .valid_out(valid_out)      
    );

endmodule
