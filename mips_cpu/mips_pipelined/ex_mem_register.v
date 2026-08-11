`timescale 1ns/1ps

module ex_mem_register (

    input wire clk,
    input wire reset,

    //==========================================================
    // DATAPATH INPUTS
    //==========================================================

    input wire [31:0] alu_result_in,
    input wire [31:0] write_data_in,
    input wire [31:0] pc_plus_4_in,

    // Destination register
    input wire [4:0] destination_reg_in,

    //==========================================================
    // WRITEBACK CONTROL
    //==========================================================

    input wire reg_write_in,
    input wire mem_to_reg_in,
    input wire jump_link_in,

    //==========================================================
    // MEMORY CONTROL
    //==========================================================

    input wire mem_read_in,
    input wire mem_write_in,

    //==========================================================
    // DATAPATH OUTPUTS
    //==========================================================

    output reg [31:0] alu_result_out,
    output reg [31:0] write_data_out,
    output reg [31:0] pc_plus_4_out,

    output reg [4:0] destination_reg_out,

    //==========================================================
    // WRITEBACK CONTROL OUTPUTS
    //==========================================================

    output reg reg_write_out,
    output reg mem_to_reg_out,
    output reg jump_link_out,

    //==========================================================
    // MEMORY CONTROL OUTPUTS
    //==========================================================

    output reg mem_read_out,
    output reg mem_write_out

);

always @(posedge clk) begin

    //----------------------------------------------------------
    // RESET
    //----------------------------------------------------------

    if (reset) begin

        alu_result_out       <= 32'b0;
        write_data_out       <= 32'b0;
        pc_plus_4_out        <= 32'b0;

        destination_reg_out  <= 5'b0;

        //---------------- Writeback ----------------

        reg_write_out        <= 1'b0;
        mem_to_reg_out       <= 1'b0;
        jump_link_out        <= 1'b0;

        //---------------- Memory -------------------

        mem_read_out         <= 1'b0;
        mem_write_out        <= 1'b0;

    end

    //----------------------------------------------------------
    // NORMAL PIPELINE UPDATE
    //----------------------------------------------------------

    else begin

        alu_result_out       <= alu_result_in;
        write_data_out       <= write_data_in;
        pc_plus_4_out        <= pc_plus_4_in;

        destination_reg_out  <= destination_reg_in;

        //---------------- Writeback ----------------

        reg_write_out        <= reg_write_in;
        mem_to_reg_out       <= mem_to_reg_in;
        jump_link_out        <= jump_link_in;

        //---------------- Memory -------------------

        mem_read_out         <= mem_read_in;
        mem_write_out        <= mem_write_in;

    end

end

endmodule