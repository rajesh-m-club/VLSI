
module PeakDetector#(
    parameter WIDTH = 10,
    parameter THRESH = 20,
    parameter REF_PERIOD = 8     // in number of valid samples
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     en,
    input  wire signed [WIDTH-1:0]  ppg_in,
    input  wire                     valid_in,      // from PreProcessing DownSampler
    output reg                      peak_detected
);

    reg signed [WIDTH-1:0] prev;
    reg signed [WIDTH-1:0] prev2;
    integer ref_counter;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            prev <= 0;
            prev2 <= 0;
            peak_detected <= 0;
            ref_counter <= 0;
        end else if(en) begin
            // Default output
            peak_detected <= 0;

            if(valid_in) begin
                // decrement refractory only on valid sample
                if(ref_counter > 0)
                    ref_counter <= ref_counter - 1;

                // Detect peak
                if(ref_counter == 0) begin
                    if((prev > prev2) && (prev > ppg_in) && (prev > THRESH)) begin
                        peak_detected <= 1;
                        ref_counter <= REF_PERIOD;  // reset refractory
                    end
                end

                // Shift history
                prev2 <= prev;
                prev  <= ppg_in;
            end
        end
    end

endmodule

