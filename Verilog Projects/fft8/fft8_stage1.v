`timescale 1ns/1ps

module fft8_stage1 (
    input clk,
    input rst,
    input signed [7:0] xr, xi,
    input valid_in,

    output reg signed [8:0] sum_r, sum_i,
    output reg signed [8:0] diff_r, diff_i,
    output reg valid_out
);

// ============================
// Memory (store first 4 samples)
// ============================
reg signed [7:0] mem_r [0:3];
reg signed [7:0] mem_i [0:3];

reg [2:0] count;

// pipeline regs
reg signed [7:0] a_r, a_i;
reg signed [7:0] b_r, b_i;
reg valid_d;

// ============================
// Main logic
// ============================
always @(posedge clk or posedge rst) begin
    if (rst) begin
        count <= 0;
        valid_out <= 0;
        valid_d <= 0;
    end else begin
        valid_out <= 0;
        valid_d <= 0;

        if (valid_in) begin
            if (count < 4) begin
                // store first 4
                mem_r[count] <= xr;
                mem_i[count] <= xi;
            end else begin
                // fetch pair
                a_r <= mem_r[count - 4];
                a_i <= mem_i[count - 4];

                b_r <= xr;
                b_i <= xi;

                valid_d <= 1;
            end

            count <= count + 3'd1;
        end

        // compute butterfly (same cycle output)
        if (valid_d) begin
            sum_r  <= a_r + b_r;
            sum_i  <= a_i + b_i;

            diff_r <= a_r - b_r;
            diff_i <= a_i - b_i;

            valid_out <= 1;
        end
    end
end

endmodule