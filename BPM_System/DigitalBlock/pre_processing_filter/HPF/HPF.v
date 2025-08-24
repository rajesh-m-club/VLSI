module HPF #(
    parameter Width = 10,    // 10-bit signed samples
    parameter SCALE = 15     // Q fractional bits
) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     en,       // enable pin
    input  wire signed [Width-1:0]  x_in,
    output reg  signed [Width-1:0]  y_out
);
    localparam integer ALPHA_Q = 30831; // alpha * 2^15 ~= 0.9408826 * 32768

    // accumulator width: Width + SCALE + guard bits
    localparam ACCW = Width + SCALE + 2;  // 10 + 15 + 2 = 27

    // Properly extended saturation limits (already ACCW bits)
    localparam signed [ACCW-1:0] MAX_VAL = $signed({{(ACCW-Width){1'b0}}, 1'b0, {(Width-1){1'b1}}});
    localparam signed [ACCW-1:0] MIN_VAL = $signed({{(ACCW-Width){1'b0}}, 1'b1, {(Width-1){1'b0}}});

    reg signed [ACCW-1:0] acc;
    reg signed [Width-1:0] x_prev;
    reg signed [Width-1:0] y_prev;

    /* verilator lint_off UNUSED */
    reg signed [2*ACCW-1:0] mult_acc;
    /* verilator lint_on UNUSED */

    // sign-extend helper
    function signed [ACCW-1:0] sx;
        input signed [Width-1:0] v;
        begin
            sx = { { (ACCW-Width){v[Width-1]} }, v };
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_prev   <= 0;
            y_prev   <= 0;
            y_out    <= 0;
            acc      <= 0;
            mult_acc <= 0;
        end else if (en) begin
            acc <= sx(y_prev) + sx(x_in) - sx(x_prev);

            mult_acc <= acc * ALPHA_Q;

            // Use lower ACCW bits after multiplication
            acc <= mult_acc[ACCW-1:0];

            // Rounding before shifting
            acc <= acc + (1 <<< (SCALE-1)); 
            acc <= acc >>> SCALE;

            // Saturate output to 10-bit signed range
            if (acc > MAX_VAL)
                y_out <= MAX_VAL[Width-1:0];
            else if (acc < MIN_VAL)
                y_out <= MIN_VAL[Width-1:0];
            else
                y_out <= acc[Width-1:0];

            // Update history
            x_prev <= x_in;
            y_prev <= y_out;
        end
    end
endmodule
