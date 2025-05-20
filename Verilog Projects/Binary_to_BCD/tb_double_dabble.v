`timescale 1ns / 1ps

module tb_bin_to_bcd;

    // Parameters
    parameter BIN_WIDTH = 8;
    parameter BCD_DIGITS = (BIN_WIDTH*3)/10 + 1;

    // DUT I/O
    reg  [BIN_WIDTH-1:0] bin;
    wire [(4*BCD_DIGITS-1):0] bcd;

    // Instantiate the DUT (Design Under Test)
    bin_to_bcd #(
        .bin_width(BIN_WIDTH),
        .bcd_digits(BCD_DIGITS)
    ) uut (
        .bin(bin),
        .bcd(bcd)
    );

    // Task to print BCD as decimal digits
    task display_bcd;
        integer i;
        begin
            $write("BCD Digits: ");
            for (i = BCD_DIGITS-1; i >= 0; i = i - 1)
                $write("%0d", bcd[4*i +: 4]);
            $write("\n");
        end
    endtask

    // VCD dump initialization
    initial begin
        $dumpfile("bin_to_bcd_tb.vcd");   // Name of the dump file
        $dumpvars(0, tb_bin_to_bcd);      // Dump all variables in this module
    end

    // Stimulus
    initial begin
        $display("Testing Binary to BCD Conversion");
        $display("-------------------------------");

        bin = 8'd0;   #10; $write("Binary: %0d -> ", bin); display_bcd();
        bin = 8'd5;   #10; $write("Binary: %0d -> ", bin); display_bcd();
        bin = 8'd9;   #10; $write("Binary: %0d -> ", bin); display_bcd();
        bin = 8'd12;  #10; $write("Binary: %0d -> ", bin); display_bcd();
        bin = 8'd45;  #10; $write("Binary: %0d -> ", bin); display_bcd();
        bin = 8'd99;  #10; $write("Binary: %0d -> ", bin); display_bcd();
        bin = 8'd123; #10; $write("Binary: %0d -> ", bin); display_bcd();
        bin = 8'd255; #10; $write("Binary: %0d -> ", bin); display_bcd();

        $finish;
    end

endmodule
