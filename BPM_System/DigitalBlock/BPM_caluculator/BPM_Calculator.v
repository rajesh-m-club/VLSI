module BPM_Calculator #(
    parameter WIDTH = 6,      // time_counter width
    parameter FS    = 25      // downsampled sampling rate
)(
    input  wire               clk,
    input  wire               rst_n,
    input  wire               en,
    input  wire [WIDTH-1:0]   interval_count, // ticks @ 25 Hz
    input  wire               interval_valid,
    output reg  [7:0]         bpm_value,
    output reg                bpm_valid,
    input  wire               bpm_copied
);

    localparam integer SCALE = 100;

    wire [31:0] interval_ext = {26'd0, interval_count};  // explicit zero extend

    // Intermediate 32-bit calculation
    wire [31:0] bpm_calc = ((60 * FS * SCALE + (interval_ext >> 1)) / interval_ext) / SCALE;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bpm_value <= 0;
            bpm_valid <= 0;
        end else begin
            if (en && interval_valid && !bpm_valid) begin
                if (interval_count != 0) begin
                    // Saturate bpm_value to 8 bits max
                    bpm_value <= (bpm_calc > 8'hFF) ? 8'hFF : bpm_calc[7:0];
                end else begin
                    bpm_value <= 0;
                end
                bpm_valid <= 1'b1;
            end
            if (bpm_valid && bpm_copied)
                bpm_valid <= 1'b0;
        end
    end

endmodule
