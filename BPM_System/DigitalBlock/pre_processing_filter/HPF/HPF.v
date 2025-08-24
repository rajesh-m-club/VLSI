module HPF #(
    parameter Width = 10,    // 10-bit signed samples
    parameter SCALE = 15     // Q fractional bits
) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     en,       // NEW enable pin
    input  wire signed [Width-1:0]  x_in,
    output reg  signed [Width-1:0]  y_out
);
    localparam integer ALPHA_Q = 30831; // alpha * 2^15 ~= 0.9408826 * 32768

    // accumulator width: Width + SCALE + guard bits
    localparam ACCW = Width + SCALE + 2;  // 10 + 15 + 2 = 27
    reg signed [ACCW-1:0] acc;
    reg signed [Width-1:0] x_prev;
    reg signed [Width-1:0] y_prev;

    // sign-extend helper
    function signed [ACCW-1:0] sx;
        input signed [Width-1:0] v;
        begin
            sx = { { (ACCW-Width){v[Width-1]} }, v };
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_prev <= 0;
            y_prev <= 0;
            y_out  <= 0;
        end 
        else if (en) begin
            // t = y_prev + (x_in - x_prev)
            acc = sx(y_prev) + sx(x_in) - sx(x_prev);

            // Multiply by ALPHA_Q (Q1.SCALE) then shift back by SCALE
            acc = (acc * ALPHA_Q);

            // Rounding before shifting
            acc = acc + (1 <<< (SCALE-1)); // add half LSB for rounding
            acc = acc >>> SCALE;           // shift back to original integer domain

            // Saturate to 10-bit signed
            if (acc > $signed({1'b0, {(Width-1){1'b1}}}))       // max +ve
                y_out <= $signed({1'b0, {(Width-1){1'b1}}});
            else if (acc < $signed({1'b1, {(Width-1){1'b0}}}))  // min -ve
                y_out <= $signed({1'b1, {(Width-1){1'b0}}});
            else
                y_out <= acc[Width-1:0];

            // update history
            x_prev <= x_in;
            y_prev <= y_out;
        end
        // else: hold previous values (idle)
    end
endmodule
