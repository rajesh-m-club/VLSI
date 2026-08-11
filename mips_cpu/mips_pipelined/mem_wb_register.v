`timescale 1ns/1ps

module mem_wb_register (

    input wire clk,
    input wire reset,

    //==========================================================
    // DATAPATH INPUTS
    //==========================================================

    // Data loaded from memory (LW)
    input wire [31:0] memory_data_in,

    // ALU result
    input wire [31:0] alu_result_in,

    // PC + 4 (used by JAL)
    input wire [31:0] pc_plus_4_in,

    // Destination register number
    input wire [4:0] destination_reg_in,

    //==========================================================
    // WRITEBACK CONTROL INPUTS
    //==========================================================

    input wire reg_write_in,
    input wire mem_to_reg_in,
    input wire jump_link_in,

    //==========================================================
    // DATAPATH OUTPUTS
    //==========================================================

    output reg [31:0] memory_data_out,
    output reg [31:0] alu_result_out,
    output reg [31:0] pc_plus_4_out,

    output reg [4:0] destination_reg_out,

    //==========================================================
    // WRITEBACK CONTROL OUTPUTS
    //==========================================================

    output reg reg_write_out,
    output reg mem_to_reg_out,
    output reg jump_link_out

);

always @(posedge clk) begin

    //----------------------------------------------------------
    // RESET
    //----------------------------------------------------------

    if (reset) begin

        memory_data_out     <= 32'b0;
        alu_result_out      <= 32'b0;
        pc_plus_4_out       <= 32'b0;

        destination_reg_out <= 5'b0;

        reg_write_out       <= 1'b0;
        mem_to_reg_out      <= 1'b0;
        jump_link_out       <= 1'b0;

    end

    //----------------------------------------------------------
    // NORMAL PIPELINE UPDATE
    //----------------------------------------------------------

    else begin

        memory_data_out     <= memory_data_in;
        alu_result_out      <= alu_result_in;
        pc_plus_4_out       <= pc_plus_4_in;

        destination_reg_out <= destination_reg_in;

        reg_write_out       <= reg_write_in;
        mem_to_reg_out      <= mem_to_reg_in;
        jump_link_out       <= jump_link_in;

    end

end

endmodule