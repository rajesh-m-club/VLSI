`timescale 1ns / 1ps

module alu_tb;

    // Inputs
    reg [3:0] A;
    reg [3:0] B;
    reg [2:0] sel;

    // Outputs
    wire [3:0] y;
    wire c_out;

    // Instantiate the ALU
    alu uut (
        .A(A),
        .B(B),
        .sel(sel),
        .y(y),
        .c_out(c_out)
    );

    initial begin
        // Set up VCD file for GTKWave
        $dumpfile("alu_tb.vcd");   // Name of the output VCD file
        $dumpvars(0, alu_tb);      // Dump all signals in this module

        // Monitor changes
        $monitor("Time=%0t A=%b B=%b sel=%b => y=%b c_out=%b", $time, A, B, sel, y, c_out);

        // Test ADD (sel = 000)
        A = 4'b0011; B = 4'b0101; sel = 3'b000; #10;

        // Test SUB (sel = 001)
        A = 4'b0110; B = 4'b0011; sel = 3'b001; #10;

        // Test AND (sel = 010)
        A = 4'b1100; B = 4'b1010; sel = 3'b010; #10;

        // Test OR (sel = 011)
        A = 4'b1100; B = 4'b1010; sel = 3'b011; #10;

        // Test XOR (sel = 100)
        A = 4'b1100; B = 4'b1010; sel = 3'b100; #10;

        // Test NOT (sel = 101)
        A = 4'b1100; B = 4'b0000; sel = 3'b101; #10;

        // Test SHIFT LEFT (sel = 110)
        A = 4'b0001; B = 4'b0010; sel = 3'b110; #10;

        // Test SHIFT RIGHT (sel = 111)
        A = 4'b1000; B = 4'b0001; sel = 3'b111; #10;

        // End simulation
        $finish;
    end

endmodule
