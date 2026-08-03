`timescale 1ns/1ps

module tb_total_mips;

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
    // CLOCK GENERATION
    // 10 ns clock period
    // =========================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    // =========================================================
    // VCD DUMP
    // =========================================================

    initial begin

        $dumpfile("mips_total.vcd");

        $dumpvars(0, tb_total_mips);

    end


    // =========================================================
    // MONITOR
    // =========================================================

    always @(posedge clk) begin

        if (!reset) begin

            #1;

            $display(
                "Time=%0t | PC=%h | Instruction=%h | ALU_Result=%0d | NextPC=%h",
                $time,
                dut.pc,
                dut.instruction,
                dut.alu_result,
                dut.next_pc
            );

        end

    end


    // =========================================================
    // TEST
    // =========================================================

    initial begin

        // -----------------------------------------------------
        // RESET
        // -----------------------------------------------------

        reset = 1'b1;

        #12;

        reset = 1'b0;


        // -----------------------------------------------------
        // RUN PROGRAM
        // -----------------------------------------------------
        //
        // The program contains:
        //
        // ADDI
        // ADD
        // SUB
        // AND
        // OR
        // SLT
        // SLL
        // SRL
        // ANDI
        // ORI
        // SW
        // LW
        // BEQ
        // BNE
        // J
        // JAL
        // JR
        //
        // -----------------------------------------------------

        #400;


        // =====================================================
        // FINAL REGISTER VALUES
        // =====================================================

        $display("");
        $display("========================================");
        $display("        COMPLETE ISA TEST RESULTS");
        $display("========================================");


        $display(
            "$t0 ($8)  = %0d (0x%08h)",
            dut.registers.registers[8],
            dut.registers.registers[8]
        );


        $display(
            "$t1 ($9)  = %0d (0x%08h)",
            dut.registers.registers[9],
            dut.registers.registers[9]
        );


        $display(
            "$t2 ($10) = %0d (0x%08h)",
            dut.registers.registers[10],
            dut.registers.registers[10]
        );


        $display(
            "$t3 ($11) = %0d (0x%08h)",
            dut.registers.registers[11],
            dut.registers.registers[11]
        );


        $display(
            "$t4 ($12) = %0d (0x%08h)",
            dut.registers.registers[12],
            dut.registers.registers[12]
        );


        $display(
            "$t5 ($13) = %0d (0x%08h)",
            dut.registers.registers[13],
            dut.registers.registers[13]
        );


        $display(
            "$t6 ($14) = %0d (0x%08h)",
            dut.registers.registers[14],
            dut.registers.registers[14]
        );


        $display(
            "$s0 ($16) = %0d (0x%08h)",
            dut.registers.registers[16],
            dut.registers.registers[16]
        );


        $display(
            "$s1 ($17) = %0d (0x%08h)",
            dut.registers.registers[17],
            dut.registers.registers[17]
        );


        $display(
            "$s2 ($18) = %0d (0x%08h)",
            dut.registers.registers[18],
            dut.registers.registers[18]
        );


        $display(
            "$s3 ($19) = %0d (0x%08h)",
            dut.registers.registers[19],
            dut.registers.registers[19]
        );


        $display(
            "$s4 ($20) = %0d (0x%08h)",
            dut.registers.registers[20],
            dut.registers.registers[20]
        );


        $display(
            "$s5 ($21) = %0d (0x%08h)",
            dut.registers.registers[21],
            dut.registers.registers[21]
        );


        $display(
            "$s6 ($22) = %0d (0x%08h)",
            dut.registers.registers[22],
            dut.registers.registers[22]
        );


        $display(
            "$s7 ($23) = %0d (0x%08h)",
            dut.registers.registers[23],
            dut.registers.registers[23]
        );


        $display(
            "$ra ($31) = %0d (0x%08h)",
            dut.registers.registers[31],
            dut.registers.registers[31]
        );


        // =====================================================
        // MEMORY RESULTS
        // =====================================================

        $display("");
        $display("MEMORY RESULTS");
        $display("========================================");


        $display(
            "MEM[0] = %02h %02h %02h %02h",
            dut.data_mem.memory[0],
            dut.data_mem.memory[1],
            dut.data_mem.memory[2],
            dut.data_mem.memory[3]
        );


        // =====================================================
        // AUTOMATIC CHECKING
        // =====================================================

        if (

            // -----------------------------
            // R-TYPE / IMMEDIATE RESULTS
            // -----------------------------

            dut.registers.registers[8]  == 32'd10  &&

            dut.registers.registers[9]  == 32'd20  &&

            dut.registers.registers[10] == 32'd30  &&

            dut.registers.registers[11] == 32'd10  &&

            dut.registers.registers[12] == 32'd10  &&

            dut.registers.registers[13] == 32'd30  &&

            dut.registers.registers[14] == 32'd1  &&


            // -----------------------------
            // SHIFT / LOGICAL RESULTS
            // -----------------------------

            dut.registers.registers[16] == 32'd40  &&

            dut.registers.registers[18] == 32'd4  &&

            dut.registers.registers[19] == 32'd11  &&


            // -----------------------------
            // MEMORY RESULT
            // -----------------------------

            dut.registers.registers[20] == 32'd30  &&


            // -----------------------------
            // BRANCH / JUMP RESULTS
            // -----------------------------

            dut.registers.registers[21] == 32'd123  &&

            dut.registers.registers[22] == 32'd66  &&

            dut.registers.registers[23] == 32'd77  &&


            // -----------------------------
            // JAL RETURN ADDRESS
            // -----------------------------

            dut.registers.registers[31] == 32'd100  &&


            // -----------------------------
            // MEMORY CONTENT
            // -----------------------------

            dut.data_mem.memory[0] == 8'h00 &&

            dut.data_mem.memory[1] == 8'h00 &&

            dut.data_mem.memory[2] == 8'h00 &&

            dut.data_mem.memory[3] == 8'h1E

        ) begin

            $display("");
            $display("========================================");
            $display("PASS: COMPLETE ISA TEST PASSED");
            $display("========================================");

        end

        else begin

            $display("");
            $display("========================================");
            $display("FAIL: ISA TEST FAILED");
            $display("========================================");

        end


        #10;

        $finish;

    end

endmodule