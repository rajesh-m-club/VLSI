module LPF #(
    parameter Width = 10,    // 10-bit signed samples
    parameter SCALE = 15     // Q fractional bits
) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     en,       // NEW enable pin
    input  wire signed [Width-1:0]  x_in,
    output reg  signed [Width-1:0]  y_out
);
    // ALPHA_Q = alpha * 2^SCALE for Fc=5 Hz, Fs=50 Hz
    localparam integer ALPHA_Q = 12629; // ~0.385869 * 32768

    // accumulator width: Width + SCALE + guard bits
    localparam ACCW = Width + SCALE + 2;
    reg signed [ACCW-1:0] acc;
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
            y_prev <= 0;
            y_out  <= 0;
        end 
        else if (en) begin   // process only when enabled
            // diff = x - y_prev
            acc = sx(x_in) - sx(y_prev);

            // Multiply by ALPHA_Q
            acc = acc * ALPHA_Q;

            // Rounding before shifting
            acc = acc + (1 <<< (SCALE-1));
            acc = acc >>> SCALE;

            // Add to y_prev
            acc = sx(y_prev) + acc;

            // Saturate to Width bits
            if (acc > $signed({1'b0, {(Width-1){1'b1}}}))
                y_out <= $signed({1'b0, {(Width-1){1'b1}}});
            else if (acc < $signed({1'b1, {(Width-1){1'b0}}}))
                y_out <= $signed({1'b1, {(Width-1){1'b0}}});
            else
                y_out <= acc[Width-1:0];

            // update history
            y_prev <= y_out;
        end
        // else: hold y_out and y_prev
    end
endmodule

