`timescale 1ns/1ps

module tb_mips_pipelined;

// =========================================================
// CLOCK / RESET
// =========================================================

reg clk;
reg reset;

integer errors;


// =========================================================
// DUT
// =========================================================

mips_pipelined #(
    .PROGRAM_FILE("program_all_isa.hex")
) dut (
    .clk   (clk),
    .reset (reset)
);


// =========================================================
// CLOCK
// =========================================================

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end


// =========================================================
// PIPELINE TRACE
// =========================================================

always @(posedge clk) begin

    if (!reset) begin

        #1;

        $display(
            "TIME=%0t | PC=%h | IF_INSTR=%h | IDEX_RT=%0d | IDEX_RS=%0d | IDEX_RD=%0d | FWD_A=%b | FWD_B=%b | ALU=%h | DEST=%0d | STALL=%b | BR_TAKEN=%b | JUMP=%b | JR=%b | EXMEM_WE=%b | MEMWB_WE=%b | WB_DEST=%0d | WB_DATA=%h",

            $time,

            dut.pc_current,
            dut.instr_if,

            dut.idex_rt,
            dut.idex_rs,
            dut.idex_rd,

            dut.ex_forwardA,
            dut.ex_forwardB,

            dut.ex_alu_result,
            dut.ex_dest_reg,

            dut.hz_control_flush,

            dut.ex_branch_taken,
            dut.idex_jump,
            dut.idex_jump_reg,

            dut.exmem_reg_write,
            dut.memwb_reg_write,

            dut.memwb_dest_reg,
            dut.wb_write_data
        );

    end

end


// =========================================================
// REGISTER WRITE TRACE
// =========================================================

always @(posedge clk) begin

    if (!reset) begin

        #1;

        if (dut.wb_reg_write &&
            (dut.wb_dest_reg != 5'd0)) begin

            $display(
                "          WB WRITE: $%0d <= %h",
                dut.wb_dest_reg,
                dut.wb_write_data
            );

        end

    end

end


// =========================================================
// MAIN TEST
// =========================================================

initial begin

    errors = 0;

    // -----------------------------------------------------
    // VCD
    // -----------------------------------------------------

    $dumpfile("mips_pipelined.vcd");
    $dumpvars(0, tb_mips_pipelined);


    // -----------------------------------------------------
    // RESET
    // -----------------------------------------------------

    clk   = 1'b0;
    reset = 1'b1;

    repeat (3) @(posedge clk);

    reset = 1'b0;


    // -----------------------------------------------------
    // RUN PROGRAM
    // -----------------------------------------------------

    repeat (100) @(posedge clk);

    #1;


    // =====================================================
    // FINAL REGISTER VALUES
    // =====================================================

    $display("");
    $display("==============================================");
    $display("       FINAL REGISTER VALUES");
    $display("==============================================");

    print_register(0);
    print_register(8);
    print_register(9);
    print_register(10);
    print_register(11);
    print_register(12);
    print_register(13);
    print_register(14);

    print_register(16);
    print_register(18);
    print_register(19);
    print_register(20);
    print_register(21);
    print_register(22);
    print_register(23);

    print_register(31);


    // =====================================================
    // SELF CHECK
    // =====================================================

    $display("");
    $display("==============================================");
    $display("       SELF CHECK");
    $display("==============================================");

    check_register(0,  32'd0);

    check_register(8,  32'd10);
    check_register(9,  32'd20);
    check_register(10, 32'd30);
    check_register(11, 32'd10);
    check_register(12, 32'd10);
    check_register(13, 32'd30);
    check_register(14, 32'd1);

    check_register(16, 32'd40);
    check_register(18, 32'd4);
    check_register(19, 32'd11);
    check_register(20, 32'd30);

    check_register(21, 32'd123);
    check_register(22, 32'd66);
    check_register(23, 32'd77);

    check_register(31, 32'h00000064);


    // =====================================================
    // FINAL RESULT
    // =====================================================

    $display("");
    $display("==============================================");

    if (errors == 0) begin

        $display("       MIPS PIPELINED TEST : PASS");

    end
    else begin

        $display("       MIPS PIPELINED TEST : FAIL");
        $display("       Errors = %0d", errors);

    end

    $display("==============================================");
    $display("");


    if (errors != 0)
        $fatal(1, "MIPS PIPELINED TEST FAILED");

    $finish;

end


// =========================================================
// PRINT REGISTER
// =========================================================

task print_register;

    input integer reg_num;

    begin

        $display(
            "$%0d = %h (%0d)",
            reg_num,
            dut.u_reg_file.registers[reg_num],
            $signed(dut.u_reg_file.registers[reg_num])
        );

    end

endtask


// =========================================================
// REGISTER CHECK
// =========================================================

task check_register;

    input integer reg_num;
    input [31:0] expected;

    reg [31:0] actual;

    begin

        actual = dut.u_reg_file.registers[reg_num];

        if (actual !== expected) begin

            $display(
                "FAIL: register $%0d | expected = %h | actual = %h",
                reg_num,
                expected,
                actual
            );

            errors = errors + 1;

        end
        else begin

            $display(
                "PASS: register $%0d = %h",
                reg_num,
                actual
            );

        end

    end

endtask

endmodule