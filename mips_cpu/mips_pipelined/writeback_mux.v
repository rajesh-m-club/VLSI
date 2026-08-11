`timescale 1ns/1ps

module writeback_mux (

    // Result from ALU
    input wire [31:0] alu_result,

    // Data read from data memory
    input wire [31:0] memory_data,

    // Address of the next sequential instruction
    // Used by JAL to save the return address
    input wire [31:0] pc_plus_4,

    // Select memory data for LW
    input wire        mem_to_reg,

    // Select PC + 4 for JAL
    input wire        jump_link,

    // Final data written into register file
    output reg [31:0] write_data

);


    always @(*) begin

        // -------------------------------------------------
        // JAL
        // -------------------------------------------------
        // $ra ($31) = PC + 4
        //
        // jump_link has highest priority because JAL
        // must write the return address.
        // -------------------------------------------------

        if (jump_link)

            write_data = pc_plus_4;


        // -------------------------------------------------
        // LW
        // -------------------------------------------------
        // rt = Memory[ALU result]
        // -------------------------------------------------

        else if (mem_to_reg)

            write_data = memory_data;


        // -------------------------------------------------
        // R-TYPE / ADDI / ANDI / ORI
        // -------------------------------------------------
        // Destination register = ALU result
        // -------------------------------------------------

        else

            write_data = alu_result;

    end


endmodule