`timescale 1ns/1ps
module fft8_stage2(
    input clk,
    input rst,

    input signed [8:0] sum_in_r, sum_in_i,    // y0..y3
    input signed [8:0] diff_in_r, diff_in_i,  // y4..y7
    input valid_in,

    output reg signed [10:0] sum1_r, sum1_i,
    output reg signed [10:0] sum2_r, sum2_i,
    output reg signed [10:0] diff1_r, diff1_i,
    output reg signed [10:0] diff2_r, diff2_i,
    output reg valid_out
);

    // ============================
    // Memory to store first two inputs
    // ============================
    reg signed [8:0] sum_mem_r[0:1];   // y0, y1
    reg signed [8:0] sum_mem_i[0:1];
    reg signed [8:0] diff_mem_r[0:1];  // y4, y5
    reg signed [8:0] diff_mem_i[0:1];

    reg [1:0] count;  // counts 0..3

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            count <= 0;
            valid_out <= 0;
            {sum1_r,sum1_i,sum2_r,sum2_i,
             diff1_r,diff1_i,diff2_r,diff2_i} <= 0;
        end else begin
            valid_out <= 0;

            if(valid_in) begin
                case(count)
                    2'd0: begin
                        // store y0 and y4
                        sum_mem_r[0]  <= sum_in_r;
                        sum_mem_i[0]  <= sum_in_i;
                        diff_mem_r[0] <= diff_in_r;
                        diff_mem_i[0] <= diff_in_i;
                    end
                    2'd1: begin
                        // store y1 and y5
                        sum_mem_r[1]  <= sum_in_r;
                        sum_mem_i[1]  <= sum_in_i;
                        diff_mem_r[1] <= diff_in_r;
                        diff_mem_i[1] <= diff_in_i;
                    end
                    2'd2: begin
                        // compute first pair outputs (z0, z2, z4, z6)
                        sum1_r  <= sum_mem_r[0] + sum_in_r; // z0 = y0 + y2
                        sum1_i  <= sum_mem_i[0] + sum_in_i;

                        sum2_r  <= sum_mem_r[0] - sum_in_r; // z2 = y0 - y2
                        sum2_i  <= sum_mem_i[0] - sum_in_i;

                        diff1_r <= diff_mem_r[0] + diff_in_i;  // z4 = y4 + (-j)*y6
                        diff1_i <= diff_mem_i[0] - diff_in_r;

                        diff2_r <= diff_mem_r[0] - diff_in_i;  // z6 = y4 - (-j)*y6
                        diff2_i <= diff_mem_i[0] + diff_in_r;

                        valid_out <= 1;
                    end
                    2'd3: begin
                        // compute second pair outputs (z1, z3, z5, z7)
                        sum1_r  <= sum_mem_r[1] + sum_in_r; // z1 = y1 + y3
                        sum1_i  <= sum_mem_i[1] + sum_in_i;

                        sum2_r  <= sum_mem_r[1] - sum_in_r; // z3 = y1 - y3
                        sum2_i  <= sum_mem_i[1] - sum_in_i;

                        diff1_r <= diff_mem_r[1] + diff_in_i; // z5 = y5 + (-j)*y7
                        diff1_i <= diff_mem_i[1] - diff_in_r;

                        diff2_r <= diff_mem_r[1] - diff_in_i; // z7 = y5 - (-j)*y7
                        diff2_i <= diff_mem_i[1] + diff_in_r;

                        valid_out <= 1;
                    end
                endcase

                count <= count + 2'd1;
            end
        end
    end

endmodule