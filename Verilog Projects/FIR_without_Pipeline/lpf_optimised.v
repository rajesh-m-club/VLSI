`timescale 1ns/1ps

module lpf_optimised #(
    parameter TAPS_OPP = 50
)(
    input  wire clk,
    input  wire rst,
    input  wire signed [16:0] x_in,
    output reg  signed [40:0] y_out
);

localparam TOTAL_TAPS = 2*TAPS_OPP + 1;

integer i;

// ---------------- DATA MEMORY ----------------
reg signed [16:0] x_mem [0:TOTAL_TAPS-1];

// ---------------- COEFFICIENT MEMORY ----------------
reg signed [16:0] coeff [0:TAPS_OPP-1];
reg signed [16:0] coeff_center;

// ---------------- INTERNAL SIGNALS ----------------
reg signed [17:0] pair_sum;
reg signed [40:0] acc;
reg signed [40:0] center_mult;

// ---------------- LOAD COEFFICIENTS ----------------
initial begin
    reg signed [16:0] coeff_full [0:TOTAL_TAPS-1];
    integer k;

    $readmemb("fir_taps_Q3_14.mem", coeff_full);

    // Extract symmetric coefficients
    for (k = 0; k < TAPS_OPP; k = k + 1)
        coeff[k] = coeff_full[k];

    // Center tap
    coeff_center = coeff_full[TAPS_OPP];
end

// ---------------- MAC OPERATION ----------------
always @(*) begin
    acc = 41'sd0;

    for(i = 0; i < TAPS_OPP; i = i + 1) begin
        pair_sum = x_mem[i] + x_mem[2*TAPS_OPP - i];
        acc = acc + coeff[i] * pair_sum;
    end

    center_mult = coeff_center * x_mem[TAPS_OPP];
    acc = acc + center_mult;
end

// ---------------- SHIFT REGISTER ----------------
always @(posedge clk) begin
    if (rst) begin
        for(i = 0; i < TOTAL_TAPS; i = i + 1)
            x_mem[i] <= 17'sd0;

        y_out <= 41'sd0;
    end
    else begin
        for(i = TOTAL_TAPS-1; i > 0; i = i - 1)
            x_mem[i] <= x_mem[i-1];

        x_mem[0] <= x_in;
        y_out <= acc;
    end
end

endmodule