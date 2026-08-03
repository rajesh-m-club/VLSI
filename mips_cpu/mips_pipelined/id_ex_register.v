`timescale 1ns/1ps

module id_ex_register (

    input wire clk,
    input wire reset,
    input wire flush,

    //==========================================================
    // DATAPATH INPUTS
    //==========================================================

    input wire [31:0] pc_in,
    input wire [31:0] pc_plus_4_in,

    input wire [31:0] read_data1_in,
    input wire [31:0] read_data2_in,

    input wire [31:0] immediate_in,

    input wire [4:0] rs_in,
    input wire [4:0] rt_in,
    input wire [4:0] rd_in,

    input wire [4:0] shamt_in,

    //==========================================================
    // WRITEBACK CONTROL
    //==========================================================

    input wire       reg_write_in,
    input wire       mem_to_reg_in,
    input wire       jump_link_in,
    input wire [1:0] reg_dst_in,

    //==========================================================
    // MEMORY CONTROL
    //==========================================================

    input wire mem_read_in,
    input wire mem_write_in,

    //==========================================================
    // EXECUTE CONTROL
    //==========================================================

    input wire       alu_src_in,
    input wire [2:0] alu_control_in,

    input wire       branch_eq_in,
    input wire       branch_ne_in,

    input wire       jump_in,
    input wire       jump_reg_in,

    //==========================================================
    // DATAPATH OUTPUTS
    //==========================================================

    output reg [31:0] pc_out,
    output reg [31:0] pc_plus_4_out,

    output reg [31:0] read_data1_out,
    output reg [31:0] read_data2_out,

    output reg [31:0] immediate_out,

    output reg [4:0] rs_out,
    output reg [4:0] rt_out,
    output reg [4:0] rd_out,

    output reg [4:0] shamt_out,

    //==========================================================
    // WRITEBACK CONTROL OUTPUTS
    //==========================================================

    output reg       reg_write_out,
    output reg       mem_to_reg_out,
    output reg       jump_link_out,
    output reg [1:0] reg_dst_out,

    //==========================================================
    // MEMORY CONTROL OUTPUTS
    //==========================================================

    output reg mem_read_out,
    output reg mem_write_out,

    //==========================================================
    // EXECUTE CONTROL OUTPUTS
    //==========================================================

    output reg       alu_src_out,
    output reg [2:0] alu_control_out,

    output reg       branch_eq_out,
    output reg       branch_ne_out,

    output reg       jump_out,
    output reg       jump_reg_out

);

always @(posedge clk) begin

    //----------------------------------------------------------
    // RESET OR FLUSH
    //----------------------------------------------------------

    if (reset || flush) begin

        pc_out            <= 32'b0;
        pc_plus_4_out     <= 32'b0;

        read_data1_out    <= 32'b0;
        read_data2_out    <= 32'b0;

        immediate_out     <= 32'b0;

        rs_out            <= 5'b0;
        rt_out            <= 5'b0;
        rd_out            <= 5'b0;

        shamt_out         <= 5'b0;

        //---------------- Writeback ----------------

        reg_write_out     <= 1'b0;
        mem_to_reg_out    <= 1'b0;
        jump_link_out     <= 1'b0;
        reg_dst_out       <= 2'b00;

        //---------------- Memory -------------------

        mem_read_out      <= 1'b0;
        mem_write_out     <= 1'b0;

        //---------------- Execute ------------------

        alu_src_out       <= 1'b0;
        alu_control_out   <= 3'b000;

        branch_eq_out     <= 1'b0;
        branch_ne_out     <= 1'b0;

        jump_out          <= 1'b0;
        jump_reg_out      <= 1'b0;

    end

    //----------------------------------------------------------
    // NORMAL PIPELINE UPDATE
    //----------------------------------------------------------

    else begin

        pc_out            <= pc_in;
        pc_plus_4_out     <= pc_plus_4_in;

        read_data1_out    <= read_data1_in;
        read_data2_out    <= read_data2_in;

        immediate_out     <= immediate_in;

        rs_out            <= rs_in;
        rt_out            <= rt_in;
        rd_out            <= rd_in;

        shamt_out         <= shamt_in;

        //---------------- Writeback ----------------

        reg_write_out     <= reg_write_in;
        mem_to_reg_out    <= mem_to_reg_in;
        jump_link_out     <= jump_link_in;
        reg_dst_out       <= reg_dst_in;

        //---------------- Memory -------------------

        mem_read_out      <= mem_read_in;
        mem_write_out     <= mem_write_in;

        //---------------- Execute ------------------

        alu_src_out       <= alu_src_in;
        alu_control_out   <= alu_control_in;

        branch_eq_out     <= branch_eq_in;
        branch_ne_out     <= branch_ne_in;

        jump_out          <= jump_in;
        jump_reg_out      <= jump_reg_in;

    end

end

endmodule