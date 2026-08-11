`timescale 1ns/1ps

module forwarding_unit (

    // ---------------------------------------------------------
    // Source registers of instruction in EX stage
    // ---------------------------------------------------------
    input wire [4:0] id_ex_rs,
    input wire [4:0] id_ex_rt,

    // ---------------------------------------------------------
    // Destination register of instruction in MEM stage
    // ---------------------------------------------------------
    input wire       ex_mem_reg_write,
    input wire [4:0] ex_mem_rd,

    // ---------------------------------------------------------
    // Destination register of instruction in WB stage
    // ---------------------------------------------------------
    input wire       mem_wb_reg_write,
    input wire [4:0] mem_wb_rd,

    // ---------------------------------------------------------
    // Forwarding control outputs
    // ---------------------------------------------------------
    output reg [1:0] forwardA,
    output reg [1:0] forwardB

);

    always @(*) begin

        //------------------------------------------------------
        // Default
        //------------------------------------------------------

        forwardA = 2'b00;
        forwardB = 2'b00;

        //------------------------------------------------------
        // Forward operand A
        //------------------------------------------------------

        if (ex_mem_reg_write &&
            (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rs))

            forwardA = 2'b10;

        else if (mem_wb_reg_write &&
                 (mem_wb_rd != 5'd0) &&
                 !(ex_mem_reg_write &&
                   (ex_mem_rd != 5'd0) &&
                   (ex_mem_rd == id_ex_rs)) &&
                 (mem_wb_rd == id_ex_rs))

            forwardA = 2'b01;


        //------------------------------------------------------
        // Forward operand B
        //------------------------------------------------------

        if (ex_mem_reg_write &&
            (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rt))

            forwardB = 2'b10;

        else if (mem_wb_reg_write &&
                 (mem_wb_rd != 5'd0) &&
                 !(ex_mem_reg_write &&
                   (ex_mem_rd != 5'd0) &&
                   (ex_mem_rd == id_ex_rt)) &&
                 (mem_wb_rd == id_ex_rt))

            forwardB = 2'b01;

    end

endmodule