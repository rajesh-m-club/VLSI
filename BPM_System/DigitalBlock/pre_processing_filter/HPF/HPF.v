// One-pole High-Pass: y[n] = alpha * ( y[n-1] + x[n] - x[n-1] )
module HPF #(
    parameter integer Width = 10,   // input/output bit width (signed)
    parameter integer SCALE = 15    // Q frac bits for alpha
) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     en,        // enable
    input  wire signed [Width-1:0]  x_in,
    output reg  signed [Width-1:0]  y_out
);
    // alpha ≈ 0.9408826, alpha * 2^15 = 30831
    localparam integer ALPHA_Q = 30831;

    // Internal widths
    localparam integer ACCW = Width + SCALE + 2;     // guard bits for diff
    localparam integer MULW = ACCW + SCALE;          // width after multiply

    // Properly sign-extended saturation limits for the 10-bit output range
    localparam signed [ACCW-1:0] MAX_VAL = { { (ACCW-Width){1'b0} }, 1'b0, {(Width-1){1'b1}} }; // +2^(Width-1)-1
    localparam signed [ACCW-1:0] MIN_VAL = { { (ACCW-Width){1'b1} }, 1'b1, {(Width-1){1'b0}} }; // -2^(Width-1)

    // Extend those limits to MULW for safe comparison after multiply/shift
    wire signed [MULW-1:0] MAX_EXT = { { (MULW-ACCW){MAX_VAL[ACCW-1]} }, MAX_VAL };
    wire signed [MULW-1:0] MIN_EXT = { { (MULW-ACCW){MIN_VAL[ACCW-1]} }, MIN_VAL };

    // History registers
    reg signed [Width-1:0] x_prev;
    reg signed [Width-1:0] y_prev;

    // Combinational intermediates
    reg signed [ACCW-1:0]  diff;          // y_prev + x_in - x_prev (sign-extended)
    reg signed [MULW-1:0]  prod;          // diff * ALPHA_Q
    reg signed [MULW-1:0]  scaled;        // rounded, scaled result (still wide)

    // Rounding constant (same width as 'prod')
    localparam signed [MULW-1:0] ROUND = {{(MULW-SCALE){1'b0}}, 1'b1, {(SCALE-1){1'b0}}}; // 1 << (SCALE-1)

    // Sign-extend helper (to ACCW)
    function signed [ACCW-1:0] sx;
        input signed [Width-1:0] v;
        begin
            sx = { { (ACCW-Width){v[Width-1]} }, v };
        end
    endfunction

    // -------- Combinational math --------
    always @* begin
        // Difference term: y[n-1] + x[n] - x[n-1]
        diff   = sx(y_prev) + sx(x_in) - sx(x_prev);

        // Multiply by alpha in Q(SCALE)
        prod   = diff * ALPHA_Q;

        // Round then arithmetic right shift by SCALE (keep sign)
        scaled = (prod + ROUND) >>> SCALE;
    end

    // -------- Sequential registers --------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_prev <= 0;
            y_prev <= 0;
            y_out  <= 0;
        end else if (en) begin
            // Saturate to 10-bit signed range using wide comparison
            if (scaled > MAX_EXT)
                y_out <= MAX_VAL[Width-1:0];
            else if (scaled < MIN_EXT)
                y_out <= MIN_VAL[Width-1:0];
            else
                y_out <= scaled[Width-1:0];  // within range

            // Update history (capture previous input and output)
            x_prev <= x_in;
            y_prev <= y_out;
        end
        // If en==0, hold state/output
    end
endmodule
