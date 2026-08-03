`timescale 1ns/1ps

module tb_mips_single_cycle;


    // =========================================================
    // CLOCK AND RESET
    // =========================================================

    reg clk;
    reg reset;


    // =========================================================
    // DUT
    // =========================================================

    mips_single_cycle dut (

        .clk   (clk),
        .reset (reset)

    );


    // =========================================================
    // CLOCK
    // =========================================================

    always #5 clk = ~clk;


    // =========================================================
    // TRACE
    // =========================================================

    always @(posedge clk) begin

        if (!reset) begin

            #1;

            $display(

                "Time=%0t | PC=%h | Instruction=%h | ALU_Result=%0d | NextPC=%h",

                $time,

                dut.pc,

                dut.instruction,

                $signed(dut.alu_result),

                dut.next_pc

            );

        end

    end


    // =========================================================
    // TEST
    // =========================================================

    initial begin


        // -----------------------------------------------------
        // VCD
        // -----------------------------------------------------

        $dumpfile("mips_single_cycle.vcd");

        $dumpvars(0, tb_mips_single_cycle);


        // -----------------------------------------------------
        // INITIALIZATION
        // -----------------------------------------------------

        clk   = 1'b0;

        reset = 1'b1;


        // -----------------------------------------------------
        // RESET
        // -----------------------------------------------------

        #12;

        reset = 1'b0;


        // -----------------------------------------------------
        // RUN PROGRAM
        // -----------------------------------------------------

        repeat (7) begin

            @(posedge clk);

        end


        #1;


        // =====================================================
        // FINAL REGISTER VALUES
        // =====================================================

        $display("");

        $display("========================================");

        $display("SINGLE-CYCLE MIPS REGISTER VALUES");

        $display("========================================");


        $display("$t0 ($8) = %0d (0x%h)",

            $signed(dut.registers.registers[8]),

            dut.registers.registers[8]

        );


        $display("$t1 ($9) = %0d (0x%h)",

            $signed(dut.registers.registers[9]),

            dut.registers.registers[9]

        );


        $display("$t2 ($10) = %0d (0x%h)",

            $signed(dut.registers.registers[10]),

            dut.registers.registers[10]

        );


        $display("$t3 ($11) = %0d (0x%h)",

            $signed(dut.registers.registers[11]),

            dut.registers.registers[11]

        );


        $display("$t4 ($12) = %0d (0x%h)",

            $signed(dut.registers.registers[12]),

            dut.registers.registers[12]

        );


        $display("$t5 ($13) = %0d (0x%h)",

            $signed(dut.registers.registers[13]),

            dut.registers.registers[13]

        );


        $display("$t6 ($14) = %0d (0x%h)",

            $signed(dut.registers.registers[14]),

            dut.registers.registers[14]

        );


        // =====================================================
        // SELF-CHECK
        // =====================================================

        $display("");

        if (

            dut.registers.registers[8]  == 32'd10 &&

            dut.registers.registers[9]  == 32'd20 &&

            dut.registers.registers[10] == 32'd30 &&

            dut.registers.registers[11] == 32'd0 &&

            dut.registers.registers[12] == 32'd10 &&

            dut.registers.registers[13] == 32'd30 &&

            dut.registers.registers[14] == 32'd1

        ) begin

            $display("PASS: SINGLE-CYCLE MIPS ALU OPERATIONS WORK");

        end

        else begin

            $display("FAIL: INCORRECT REGISTER VALUES");

        end


        $display("========================================");


        $finish;

    end

endmodule