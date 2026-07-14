`timescale 1ns / 1ps

module tb_fixed_div_comb;

    reg [31:0] A, D;
    wire [31:0] Res;

    // Instantiate the combinational module
    fixed_div_comb uut (
        .numerator(A),
        .denominator(D),
        .result(Res)
    );

    // Variables for analysis
    real float_res;
    real expected_val;
    real error_val;
    real scale_factor = 1073741824.0; // 2^30

    initial begin
        $display("---------------------------------------------------------------");
        $display(" COMBINATIONAL DIVISION TEST WITH ERROR ANALYSIS");
        $display("---------------------------------------------------------------");

        // -----------------------------
        // Test cases
        // -----------------------------

        run_test(15,23);
        run_test(10,79);
        run_test(7,97);
        run_test(25,53);
        run_test(9,71);

        $finish;
    end

    // -----------------------------
    // Task for reusable test
    // -----------------------------
    task run_test;
        input [31:0] num;
        input [31:0] den;
        begin
            A = num;
            D = den;
            #10; // Wait for combinational logic to settle

            float_res    = $itor(Res) / scale_factor;
            expected_val = $itor(num) / $itor(den);
            error_val    = float_res - expected_val;
            if (error_val < 0) error_val = -error_val;

            $display("Test: %0d / %0d", num, den);
            $display("  Result   : %1.8f (Hex: %h)", float_res, Res);
            $display("  Expected : %1.8f", expected_val);
            $display("  Error    : %e", error_val);
            $display("---------------------------------------------------------------");
        end
    endtask

endmodule
