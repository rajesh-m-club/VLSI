`timescale 1ns/1ps

module lpf_genvar_pipelined #(
    parameter TAPS_OPP = 50
)(
    input  clk,
    input  rst,
    input  signed [16:0] x_in,
    output reg signed [40:0] y_out
);

localparam TOTAL_TAPS = 2*TAPS_OPP + 1;
localparam LEVELS    = $clog2(TAPS_OPP);
localparam TREE_SIZE = 2**LEVELS;

integer j, k;

reg signed [16:0] mem_x_in [0:TOTAL_TAPS-1];

always @(posedge clk) begin
    if (rst) begin
        for (j = 0; j < TOTAL_TAPS; j = j + 1) begin
            mem_x_in[j] <= 0;
        end
    end else begin
        for (j = TOTAL_TAPS-1; j > 0; j = j - 1) begin
            mem_x_in[j] <= mem_x_in[j-1];
        end
        mem_x_in[0] <= x_in;
    end
end

reg signed [16:0] coeff_full [0:TOTAL_TAPS-1];
reg signed [16:0] coeff [0:TAPS_OPP-1];
reg signed [16:0] coeff_center;

initial begin
    $readmemb("fir_taps_Q3_14.mem", coeff_full);

    for (k = 0; k < TAPS_OPP; k = k + 1) begin
        coeff[k] = coeff_full[k];
    end

    coeff_center = coeff_full[TAPS_OPP];
end

reg signed [17:0] sum_pair [0:TREE_SIZE-1];

genvar i;
generate
    for (i = 0; i < TREE_SIZE; i = i + 1) begin : SUM_PAIR
        always @(posedge clk) begin
            if (i < TAPS_OPP)
                sum_pair[i] <= mem_x_in[i] + mem_x_in[2*TAPS_OPP - i];
            else
                sum_pair[i] <= 0;
        end
    end
endgenerate

// STAGE 0B
reg signed [40:0] stage0 [0:TREE_SIZE-1];

generate
    for (i = 0; i < TREE_SIZE; i = i + 1) begin : MULT_STAGE
        always @(posedge clk) begin
            if (i < TAPS_OPP)
                stage0[i] <= coeff[i] * sum_pair[i];
            else
                stage0[i] <= 0;
        end
    end
endgenerate

// Stage 1
reg signed [40:0] stage1 [0:TREE_SIZE/2-1];
generate
    for (i = 0; i < TREE_SIZE/2; i = i + 1) begin : STAGE1_GEN
        always @(posedge clk) begin
            stage1[i] <= stage0[2*i] + stage0[2*i+1];
        end
    end
endgenerate

// Stage 2
reg signed [40:0] stage2 [0:TREE_SIZE/4-1];
generate
    for (i = 0; i < TREE_SIZE/4; i = i + 1) begin : STAGE2_GEN
        always @(posedge clk) begin
            stage2[i] <= stage1[2*i] + stage1[2*i+1];
        end
    end
endgenerate

// Stage 3
reg signed [40:0] stage3 [0:TREE_SIZE/8-1];
generate
    for (i = 0; i < TREE_SIZE/8; i = i + 1) begin : STAGE3_GEN
        always @(posedge clk) begin
            stage3[i] <= stage2[2*i] + stage2[2*i+1];
        end
    end
endgenerate

// Stage 4
reg signed [40:0] stage4 [0:TREE_SIZE/16-1];
generate
    for (i = 0; i < TREE_SIZE/16; i = i + 1) begin : STAGE4_GEN
        always @(posedge clk) begin
            stage4[i] <= stage3[2*i] + stage3[2*i+1];
        end
    end
endgenerate

// Stage 5
reg signed [40:0] stage5 [0:TREE_SIZE/32-1];
generate
    for (i = 0; i < TREE_SIZE/32; i = i + 1) begin : STAGE5_GEN
        always @(posedge clk) begin
            stage5[i] <= stage4[2*i] + stage4[2*i+1];
        end
    end
endgenerate

// Stage 6
reg signed [40:0] stage6 [0:TREE_SIZE/64-1];
generate
    for (i = 0; i < TREE_SIZE/64; i = i + 1) begin : STAGE6_GEN
        always @(posedge clk) begin
            stage6[i] <= stage5[2*i] + stage5[2*i+1];
        end
    end
endgenerate

//CENTER PATH
reg signed [40:0] center_mult;

always @(posedge clk) begin
    center_mult <= coeff_center * mem_x_in[TAPS_OPP];
end

// pipeline align
reg signed [40:0] center_pipe [0:6];

always @(posedge clk) begin
    center_pipe[0] <= center_mult;
    for (k = 1; k < 7; k = k + 1) begin
        center_pipe[k] <= center_pipe[k-1];
    end
end

// OUTPUT
always @(posedge clk) begin
    if (rst)
        y_out <= 0;
    else
        y_out <= stage6[0] + center_pipe[6];
end

endmodule