module LPF #(
    parameter Width = 10,    // 10-bit signed samples
    parameter SCALE = 15     // Q fractional bits
) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     en,       // enable pin
    input  wire signed [Width-1:0] x_in,
    output reg  signed [Width-1:0] y_out
);
    // ALPHA_Q = alpha * 2^SCALE for Fc=5 Hz, Fs=50 Hz
    localparam integer ALPHA_Q = 12629; // ~0.385869 * 32768

    // accumulator width: Width + SCALE + guard bits
    localparam ACCW = Width + SCALE + 2;

    /* verilator lint_off UNUSED */
    reg signed [2*ACCW-1:0] mult_acc;
    /* verilator lint_on UNUSED */
    reg signed [ACCW-1:0] acc;
    reg signed [Width-1:0] y_prev;

    // Extended saturation limits to ACCW bits
    localparam signed [ACCW-1:0] MAX_VAL = $signed({{(ACCW-Width){1'b0}}, 1'b0, {(Width-1){1'b1}}});
    localparam signed [ACCW-1:0] MIN_VAL = $signed({{(ACCW-Width){1'b0}}, 1'b1, {(Width-1){1'b0}}});

    // sign-extend helper
    function signed [ACCW-1:0] sx;
        input signed [Width-1:0] v;
        begin
            sx = { { (ACCW-Width){v[Width-1]} }, v };
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_prev   <= 0;
            y_out    <= 0;
            acc      <= 0;
            mult_acc <= 0;
        end else if (en) begin
            // diff = x_in - y_prev
            acc <= sx(x_in) - sx(y_prev);

            // Multiply by ALPHA_Q with extended width and suppress lint warning
            /* verilator lint_off WIDTHTRUNC */
            mult_acc <= acc * ALPHA_Q;
            /* verilator lint_on WIDTHTRUNC */

            // Take lower ACCW bits after multiplication
            acc <= mult_acc[ACCW-1:0];

            // Rounding before shifting
            acc <= acc + (1 <<< (SCALE-1));
            acc <= acc >>> SCALE;

            // Add to y_prev (extended)
            acc <= sx(y_prev) + acc;

            // Saturate to Width bits
            if (acc > MAX_VAL)
                y_out <= MAX_VAL[Width-1:0];
            else if (acc < MIN_VAL)
                y_out <= MIN_VAL[Width-1:0];
            else
                y_out <= acc[Width-1:0];

            // Update history
            y_prev <= y_out;
        end
        // else: hold y_out and y_prev
    end
endmodule
