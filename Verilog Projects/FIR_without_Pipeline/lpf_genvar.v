`timescale 1ns/1ps

module lpf_genvar #(
    parameter TAPS_OPP = 50
)(
    input  clk,
    input  rst,
    input  signed [16:0] x_in,
    output reg signed [40:0] y_out
);

// ---------------- PARAMETERS ----------------
localparam TOTAL_TAPS = 2*TAPS_OPP + 1;   // 101
localparam LEVELS     = $clog2(TAPS_OPP); // 6
localparam TREE_SIZE  = 2**LEVELS;        // 64

// ---------------- SIGNALS ----------------
reg signed [16:0] mem_x_in [0:TOTAL_TAPS-1];
reg signed [16:0] coeff [0:TAPS_OPP-1];
reg signed [16:0] coeff_center;

// FIX: declare outside initial
reg signed [16:0] coeff_full [0:TOTAL_TAPS-1];

integer j;
integer k;

// ---------------- LOAD COEFFICIENTS ----------------
initial begin
    $readmemb("fir_taps_Q3_14.mem", coeff_full);

    for (k = 0; k < TAPS_OPP; k = k + 1)
        coeff[k] = coeff_full[k];

    coeff_center = coeff_full[TAPS_OPP];
end

// ---------------- SHIFT REGISTER ----------------
always @(posedge clk) begin
    if (rst) begin
        for (j = 0; j < TOTAL_TAPS; j = j + 1)
            mem_x_in[j] <= 0;
        y_out <= 0;
    end
    else begin
        for (j = TOTAL_TAPS-1; j > 0; j = j - 1)
            mem_x_in[j] <= mem_x_in[j-1];

        mem_x_in[0] <= x_in;
        y_out <= acc;
    end
end

// ---------------- SYMMETRIC SUM ----------------
wire signed [17:0] sum_pair [0:TAPS_OPP-1];

genvar i;
generate
    for (i = 0; i < TAPS_OPP; i = i + 1) begin : SUM_PAIR
        assign sum_pair[i] =
            mem_x_in[i] + mem_x_in[2*TAPS_OPP - i];
    end
endgenerate

// ---------------- MULTIPLICATION ----------------
wire signed [40:0] stage0 [0:TREE_SIZE-1];

generate
    for (i = 0; i < TAPS_OPP; i = i + 1) begin : MULT_STAGE0
        assign stage0[i] = coeff[i] * sum_pair[i];
    end

    for (i = TAPS_OPP; i < TREE_SIZE; i = i + 1) begin : ZERO_PAD
        assign stage0[i] = 0;
    end
endgenerate

// ---------------- ADDER TREE ----------------
wire signed [40:0] stage1 [0:TREE_SIZE/2-1];
wire signed [40:0] stage2 [0:TREE_SIZE/4-1];
wire signed [40:0] stage3 [0:TREE_SIZE/8-1];
wire signed [40:0] stage4 [0:TREE_SIZE/16-1];
wire signed [40:0] stage5 [0:TREE_SIZE/32-1];
wire signed [40:0] stage6 [0:TREE_SIZE/64-1];

// Stage 1
generate
    for (i = 0; i < TREE_SIZE/2; i = i + 1) begin : STAGE1
        assign stage1[i] = stage0[2*i] + stage0[2*i+1];
    end
endgenerate

// Stage 2
generate
    for (i = 0; i < TREE_SIZE/4; i = i + 1) begin : STAGE2
        assign stage2[i] = stage1[2*i] + stage1[2*i+1];
    end
endgenerate

// Stage 3
generate
    for (i = 0; i < TREE_SIZE/8; i = i + 1) begin : STAGE3
        assign stage3[i] = stage2[2*i] + stage2[2*i+1];
    end
endgenerate

// Stage 4
generate
    for (i = 0; i < TREE_SIZE/16; i = i + 1) begin : STAGE4
        assign stage4[i] = stage3[2*i] + stage3[2*i+1];
    end
endgenerate

// Stage 5
generate
    for (i = 0; i < TREE_SIZE/32; i = i + 1) begin : STAGE5
        assign stage5[i] = stage4[2*i] + stage4[2*i+1];
    end
endgenerate

// Stage 6 (final)
generate
    for (i = 0; i < TREE_SIZE/64; i = i + 1) begin : STAGE6
        assign stage6[i] = stage5[2*i] + stage5[2*i+1];
    end
endgenerate

// ---------------- CENTER TAP ----------------
wire signed [40:0] center_mult;
assign center_mult = coeff_center * mem_x_in[TAPS_OPP];

// ---------------- FINAL OUTPUT ----------------
wire signed [40:0] acc;
assign acc = stage6[0] + center_mult;

endmodule