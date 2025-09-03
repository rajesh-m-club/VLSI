// One-pole Low-Pass Filter
// y[n] = y[n-1] + alpha * (x[n] - y[n-1])
module LPF#(
    parameter integer Width = 10,   // input/output bit width
    parameter integer SCALE = 15    // Q fractional bits for alpha
) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     en,        // enable
    input  wire signed [Width-1:0]  x_in,
    output reg  signed [Width-1:0]  y_out
);
    // alpha ≈ 0.385869, so ALPHA_Q = round(alpha * 2^15)
    localparam integer ALPHA_Q = 12629;

    // internal widths
    localparam integer ACCW = Width + SCALE + 2; // guard bits
    localparam integer MULW = ACCW + SCALE;      // after multiply

    // Proper signed min/max for 10-bit range
    localparam signed [ACCW-1:0] MAX_VAL = { { (ACCW-Width){1'b0} }, 1'b0, {(Width-1){1'b1}} }; // +2^(Width-1)-1
    localparam signed [ACCW-1:0] MIN_VAL = { { (ACCW-Width){1'b1} }, 1'b1, {(Width-1){1'b0}} }; // -2^(Width-1)

    // Extend to MULW for comparison
    //wire signed [MULW-1:0] MAX_EXT = { { (MULW-ACCW){MAX_VAL[ACCW-1]} }, MAX_VAL };
    //wire signed [MULW-1:0] MIN_EXT = { { (MULW-ACCW){MIN_VAL[ACCW-1]} }, MIN_VAL };

    // State register
    reg signed [Width-1:0] y_prev;

    // Combinational intermediates
    reg signed [ACCW-1:0]  diff;    // (x_in - y_prev)
    reg signed [MULW-1:0]  prod;    // diff * ALPHA_Q
    reg signed [MULW-1:0]  scaled;  // rounded+scaled
    reg signed [ACCW-1:0]  acc;     // y_prev + scaled

    // Rounding constant
    localparam signed [MULW-1:0] ROUND = {{(MULW-SCALE){1'b0}}, 1'b1, {(SCALE-1){1'b0}}};

    // Sign-extend helper
    function signed [ACCW-1:0] sx;
        input signed [Width-1:0] v;
        begin
            sx = { { (ACCW-Width){v[Width-1]} }, v };
        end
    endfunction

    // ---------- Combinational path ----------
    always @* begin
        // Compute diff = x_in - y_prev
        diff   = sx(x_in) - sx(y_prev);

        // Multiply by alpha in Q(SCALE)
        prod   = diff * ALPHA_Q;

        // Round + shift down
        scaled = (prod + ROUND) >>> SCALE;

        // Add back y_prev
        acc    = sx(y_prev) + scaled[ACCW-1:0];
    end

    // ---------- Sequential registers ----------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_prev <= 0;
            y_out  <= 0;
        end else if (en) begin
            // Saturate result
            if (acc > MAX_VAL)
                y_out <= MAX_VAL[Width-1:0];
            else if (acc < MIN_VAL)
                y_out <= MIN_VAL[Width-1:0];
            else
                y_out <= acc[Width-1:0];

            // Update state
            y_prev <= y_out;
        end
        // else: hold state
    end
endmodule
