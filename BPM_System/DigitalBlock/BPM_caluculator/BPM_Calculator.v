module BPM_Calculator #(
    parameter WIDTH = 6,      // time_counter width
    parameter FS    = 25      // << downsampled sampling rate
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
    // Optional: scale for round-to-nearest (reduces truncation bias)
    localparam integer SCALE = 100;  // keep small to avoid overflow
    integer bpm_tmp;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bpm_value <= 0;
            bpm_valid <= 0;
        end else begin
            if (en && interval_valid && !bpm_valid) begin
                if (interval_count != 0) begin
                    // (60*FS)≈1500. Multiply by SCALE for precision and round.
                    bpm_tmp   = (60*FS*SCALE + (interval_count>>1)) / interval_count;
                    bpm_value <= bpm_tmp / SCALE;
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
