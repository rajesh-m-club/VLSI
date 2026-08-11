`timescale 1ns/1ps

module pipelined_control_unit(

    input  wire [5:0] opcode,
    input  wire [5:0] funct,

    //---------------- EX ----------------
    output reg [1:0] reg_dst,
    output reg       alu_src,
    output reg [2:0] alu_control,

    //---------------- MEM ---------------
    output reg       mem_read,
    output reg       mem_write,
    output reg       branch_eq,
    output reg       branch_ne,
    output reg       jump,
    output reg       jump_reg,

    //---------------- WB ----------------
    output reg       reg_write,
    output reg       mem_to_reg,
    output reg       jump_link,

    //---------------- Decode ------------
    output reg       sign_extend
);

localparam OP_RTYPE = 6'b000000;
localparam OP_LW    = 6'b100011;
localparam OP_SW    = 6'b101011;
localparam OP_BEQ   = 6'b000100;
localparam OP_BNE   = 6'b000101;
localparam OP_ADDI  = 6'b001000;
localparam OP_ANDI  = 6'b001100;
localparam OP_ORI   = 6'b001101;
localparam OP_J     = 6'b000010;
localparam OP_JAL   = 6'b000011;

localparam FUNCT_ADD = 6'b100000;
localparam FUNCT_SUB = 6'b100010;
localparam FUNCT_AND = 6'b100100;
localparam FUNCT_OR  = 6'b100101;
localparam FUNCT_SLT = 6'b101010;
localparam FUNCT_SLL = 6'b000000;
localparam FUNCT_SRL = 6'b000010;
localparam FUNCT_JR  = 6'b001000;

localparam ALU_ADD = 3'b000;
localparam ALU_SUB = 3'b001;
localparam ALU_AND = 3'b010;
localparam ALU_OR  = 3'b011;
localparam ALU_SLT = 3'b100;
localparam ALU_SLL = 3'b101;
localparam ALU_SRL = 3'b110;

localparam DST_RT = 2'b00;
localparam DST_RD = 2'b01;
localparam DST_RA = 2'b10;

always @(*) begin

    //---------------- Defaults ----------------

    reg_write   = 0;
    mem_to_reg  = 0;
    jump_link   = 0;

    mem_read    = 0;
    mem_write   = 0;
    branch_eq   = 0;
    branch_ne   = 0;
    jump        = 0;
    jump_reg    = 0;

    reg_dst     = DST_RT;
    alu_src     = 0;
    alu_control = ALU_ADD;

    sign_extend = 1;

    //--------------------------------------------------

    case(opcode)

    //--------------------------------------------------
    // R TYPE
    //--------------------------------------------------

    OP_RTYPE:

        case(funct)

        FUNCT_ADD:
        begin
            reg_write=1;
            reg_dst=DST_RD;
            alu_control=ALU_ADD;
        end

        FUNCT_SUB:
        begin
            reg_write=1;
            reg_dst=DST_RD;
            alu_control=ALU_SUB;
        end

        FUNCT_AND:
        begin
            reg_write=1;
            reg_dst=DST_RD;
            alu_control=ALU_AND;
        end

        FUNCT_OR:
        begin
            reg_write=1;
            reg_dst=DST_RD;
            alu_control=ALU_OR;
        end

        FUNCT_SLT:
        begin
            reg_write=1;
            reg_dst=DST_RD;
            alu_control=ALU_SLT;
        end

        FUNCT_SLL:
        begin
            reg_write=1;
            reg_dst=DST_RD;
            alu_control=ALU_SLL;
        end

        FUNCT_SRL:
        begin
            reg_write=1;
            reg_dst=DST_RD;
            alu_control=ALU_SRL;
        end

        FUNCT_JR:
        begin
            jump_reg=1;
        end

        endcase

    //--------------------------------------------------
    // ADDI
    //--------------------------------------------------

    OP_ADDI:
    begin
        reg_write=1;
        alu_src=1;
        alu_control=ALU_ADD;
    end

    //--------------------------------------------------
    // ANDI
    //--------------------------------------------------

    OP_ANDI:
    begin
        reg_write=1;
        alu_src=1;
        alu_control=ALU_AND;
        sign_extend=0;
    end

    //--------------------------------------------------
    // ORI
    //--------------------------------------------------

    OP_ORI:
    begin
        reg_write=1;
        alu_src=1;
        alu_control=ALU_OR;
        sign_extend=0;
    end

    //--------------------------------------------------
    // LW
    //--------------------------------------------------

    OP_LW:
    begin
        reg_write=1;
        mem_to_reg=1;
        mem_read=1;
        alu_src=1;
        alu_control=ALU_ADD;
    end

    //--------------------------------------------------
    // SW
    //--------------------------------------------------

    OP_SW:
    begin
        mem_write=1;
        alu_src=1;
        alu_control=ALU_ADD;
    end

    //--------------------------------------------------
    // BEQ
    //--------------------------------------------------

    OP_BEQ:
    begin
        branch_eq=1;
        alu_control=ALU_SUB;
    end

    //--------------------------------------------------
    // BNE
    //--------------------------------------------------

    OP_BNE:
    begin
        branch_ne=1;
        alu_control=ALU_SUB;
    end

    //--------------------------------------------------
    // J
    //--------------------------------------------------

    OP_J:
    begin
        jump=1;
    end

    //--------------------------------------------------
    // JAL
    //--------------------------------------------------

    OP_JAL:
    begin
        jump=1;
        jump_link=1;
        reg_write=1;
        reg_dst=DST_RA;
    end

    endcase

end

endmodule