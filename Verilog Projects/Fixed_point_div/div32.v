`timescale 1ns / 1ps

module fixed_div_comb (
    input  wire [31:0] numerator,
    input  wire [31:0] denominator,
    output reg  [31:0] result
);

    parameter FRAC = 30;

    // 32-bit constants (Q2.30 scaled)
    localparam [31:0] C1  = 32'd3031696225; // 48/17
    localparam [31:0] C2  = 32'd2021130817; // 32/17
    localparam [31:0] TWO = 32'd2 << FRAC;

    reg [31:0] d_norm;
    reg signed [6:0] shift;

    reg [31:0] x0;
    reg [31:0] term1, x1;
    reg [31:0] term2, x2;
    reg [31:0] term3, x3;
    reg [31:0] term4, x4;
    reg [31:0] term5, x5;

    reg [63:0] mult_temp; 

    integer i;

    always @(*) begin
        // 1. Find MSB
        shift = 0;
        for (i = 0; i < 32; i = i + 1) begin
            if (denominator[i])
                shift = (FRAC - 1) - i;
        end

        d_norm = denominator << shift;

        // 2. Initial Guess
        mult_temp = C2 * d_norm;
        x0 = C1 - (mult_temp >> FRAC);

        // Iteration 1
        mult_temp = d_norm * x0;
        term1 = mult_temp >> FRAC;

        mult_temp = x0 * (TWO - term1);
        x1 = mult_temp >> FRAC;

        // Iteration 2
        mult_temp = d_norm * x1;
        term2 = mult_temp >> FRAC;

        mult_temp = x1 * (TWO - term2);
        x2 = mult_temp >> FRAC;

        // Iteration 3
        mult_temp = d_norm * x2;
        term3 = mult_temp >> FRAC;

        mult_temp = x2 * (TWO - term3);
        x3 = mult_temp >> FRAC;

        // Iteration 4
        mult_temp = d_norm * x3;
        term4 = mult_temp >> FRAC;

        mult_temp = x3 * (TWO - term4);
        x4 = mult_temp >> FRAC;

        // Iteration 5
        mult_temp = d_norm * x4;
        term5 = mult_temp >> FRAC;

        mult_temp = x4 * (TWO - term5);
        x5 = mult_temp >> FRAC;

        // Final scaling
        mult_temp = numerator * x5;

        if (shift >= 0)
            result = mult_temp >> (FRAC - shift);

    end

endmodule
