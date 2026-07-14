module DownSampler #(
    parameter Width = 10
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     en,         // NEW enable signal
    input  wire signed [Width-1:0]  data_in,
    output reg  signed [Width-1:0]  data_out,
    output reg                      valid_out
);

    reg toggle;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle     <= 0;
            data_out   <= 0;
            valid_out  <= 0;
        end else if (en) begin
            toggle <= ~toggle;
            valid_out <= toggle;  // valid every 2nd cycle
            if (toggle) begin
                data_out <= data_in; // output current input on valid cycle
            end
        end else begin
            valid_out <= 0;  // no valid output when disabled
        end
    end

endmodule
