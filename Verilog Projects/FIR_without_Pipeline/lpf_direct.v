`timescale 1ns/1ps
module lpf_direct #(
    parameter TAPS = 101
) (
    input clk,
    input rst,
    input signed [16:0] x_in,
    output reg signed [40:0] y_out
);

reg signed [16:0] mem_x_in [0:TAPS-1];
reg signed [16:0] coff [0:TAPS-1];
reg signed [40:0] acc;

integer i;

// Load coefficients from file
initial begin
    $readmemb("fir_taps_Q3_14.mem", coff);
end

// Combinational MAC
always @(*) begin
    acc = 0;
    for(i = 0; i < TAPS; i = i + 1) begin
        acc = acc + mem_x_in[i] * coff[i];
    end
end

// Shift register + output
always @(posedge clk) begin
    if(rst) begin
        for(i = 0; i < TAPS; i = i + 1)
            mem_x_in[i] <= 0;
    end
    else begin
        for(i = TAPS-1; i > 0; i = i - 1)
            mem_x_in[i] <= mem_x_in[i-1];

        mem_x_in[0] <= x_in;
        y_out <= acc;
    end
end

endmodule