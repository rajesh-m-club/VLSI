`timescale 1ns/1ps

module control_unit (

    input wire [5:0] opcode,
    input wire [5:0] funct,

    // Register-file control
    output reg       reg_write,
    output reg [1:0] reg_dst,

    // ALU control
    output reg       alu_src,
    output reg [2:0] alu_control,

    // Data-memory control
    output reg       mem_read,
    output reg       mem_write,
    output reg       mem_to_reg,

    // Branch control
    output reg       branch_eq,
    output reg       branch_ne,

    // Jump control
    output reg       jump,
    output reg       jump_link,
    output reg       jump_reg,

    // Immediate control
    output reg       sign_extend

    // Shift control
    //output reg       shift_enable,
    //output reg       shift_right

);


    // =========================================================
    // OPCODES
    // =========================================================

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


    // =========================================================
    // R-TYPE FUNCTION CODES
    // =========================================================

    localparam FUNCT_ADD = 6'b100000;
    localparam FUNCT_SUB = 6'b100010;
    localparam FUNCT_AND = 6'b100100;
    localparam FUNCT_OR  = 6'b100101;
    localparam FUNCT_SLT = 6'b101010;

    localparam FUNCT_SLL = 6'b000000;
    localparam FUNCT_SRL = 6'b000010;

    localparam FUNCT_JR  = 6'b001000;


    // =========================================================
    // ALU CONTROL CODES
    // =========================================================

    localparam ALU_ADD = 3'b000;
    localparam ALU_SUB = 3'b001;
    localparam ALU_AND = 3'b010;
    localparam ALU_OR  = 3'b011;
    localparam ALU_SLT = 3'b100;
    localparam ALU_SLL = 3'b101;
    localparam ALU_SRL = 3'b110;


    // =========================================================
    // REGISTER DESTINATION SELECT
    // =========================================================

    localparam DST_RT = 2'b00;
    localparam DST_RD = 2'b01;
    localparam DST_RA = 2'b10;


    // =========================================================
    // CONTROL LOGIC
    // =========================================================

    always @(*) begin


        // -----------------------------------------------------
        // SAFE DEFAULT VALUES
        // -----------------------------------------------------

        reg_write = 1'b0;
        reg_dst   = DST_RT;

        alu_src   = 1'b0;
        alu_control = ALU_ADD;

        mem_read  = 1'b0;
        mem_write = 1'b0;
        mem_to_reg = 1'b0;

        branch_eq = 1'b0;
        branch_ne = 1'b0;

        jump      = 1'b0;
        jump_link = 1'b0;
        jump_reg  = 1'b0;

        sign_extend = 1'b1;

        //shift_enable = 1'b0;
        //shift_right  = 1'b0;


        // =====================================================
        // INSTRUCTION DECODE
        // =====================================================

        case (opcode)


            // =================================================
            // R-TYPE
            // =================================================

            OP_RTYPE: begin

                case (funct)


                    // -----------------------------------------
                    // ADD
                    // -----------------------------------------

                    FUNCT_ADD: begin

                        reg_write = 1'b1;
                        reg_dst   = DST_RD;

                        alu_src   = 1'b0;
                        alu_control = ALU_ADD;

                    end


                    // -----------------------------------------
                    // SUB
                    // -----------------------------------------

                    FUNCT_SUB: begin

                        reg_write = 1'b1;
                        reg_dst   = DST_RD;

                        alu_src   = 1'b0;
                        alu_control = ALU_SUB;

                    end


                    // -----------------------------------------
                    // AND
                    // -----------------------------------------

                    FUNCT_AND: begin

                        reg_write = 1'b1;
                        reg_dst   = DST_RD;

                        alu_src   = 1'b0;
                        alu_control = ALU_AND;

                    end


                    // -----------------------------------------
                    // OR
                    // -----------------------------------------

                    FUNCT_OR: begin

                        reg_write = 1'b1;
                        reg_dst   = DST_RD;

                        alu_src   = 1'b0;
                        alu_control = ALU_OR;

                    end


                    // -----------------------------------------
                    // SLT
                    // -----------------------------------------

                    FUNCT_SLT: begin

                        reg_write = 1'b1;
                        reg_dst   = DST_RD;

                        alu_src   = 1'b0;
                        alu_control = ALU_SLT;

                    end


                    // -----------------------------------------
                    // SLL
                    // -----------------------------------------

                    FUNCT_SLL: begin

                        reg_write = 1'b1;
                        reg_dst   = DST_RD;

                        alu_src     = 1'b0;
                        alu_control = ALU_SLL;

                        //shift_enable = 1'b1;
                        //shift_right  = 1'b0;

                    end


                    // -----------------------------------------
                    // SRL
                    // -----------------------------------------

                    FUNCT_SRL: begin

                        reg_write = 1'b1;
                        reg_dst   = DST_RD;

                        alu_src     = 1'b0;
                        alu_control = ALU_SRL;

                        //shift_enable = 1'b1;
                        //shift_right  = 1'b1;

                    end


                    // -----------------------------------------
                    // JR
                    // -----------------------------------------

                    FUNCT_JR: begin

                        jump_reg = 1'b1;

                    end


                    // -----------------------------------------
                    // UNKNOWN R-TYPE
                    // -----------------------------------------

                    default: begin

                        reg_write = 1'b0;

                    end

                endcase

            end


            // =================================================
            // ADDI
            // =================================================

            OP_ADDI: begin

                reg_write = 1'b1;
                reg_dst   = DST_RT;

                alu_src = 1'b1;
                alu_control = ALU_ADD;

                sign_extend = 1'b1;

            end


            // =================================================
            // ANDI
            // =================================================

            OP_ANDI: begin

                reg_write = 1'b1;
                reg_dst   = DST_RT;

                alu_src = 1'b1;
                alu_control = ALU_AND;

                sign_extend = 1'b0;

            end


            // =================================================
            // ORI
            // =================================================

            OP_ORI: begin

                reg_write = 1'b1;
                reg_dst   = DST_RT;

                alu_src = 1'b1;
                alu_control = ALU_OR;

                sign_extend = 1'b0;

            end


            // =================================================
            // LW
            // =================================================

            OP_LW: begin

                reg_write = 1'b1;
                reg_dst   = DST_RT;

                alu_src = 1'b1;
                alu_control = ALU_ADD;

                mem_read = 1'b1;
                mem_to_reg = 1'b1;

                sign_extend = 1'b1;

            end


            // =================================================
            // SW
            // =================================================

            OP_SW: begin

                reg_write = 1'b0;

                alu_src = 1'b1;
                alu_control = ALU_ADD;

                mem_write = 1'b1;

                sign_extend = 1'b1;

            end


            // =================================================
            // BEQ
            // =================================================

            OP_BEQ: begin

                alu_src = 1'b0;
                alu_control = ALU_SUB;

                branch_eq = 1'b1;

                sign_extend = 1'b1;

            end


            // =================================================
            // BNE
            // =================================================

            OP_BNE: begin

                alu_src = 1'b0;
                alu_control = ALU_SUB;

                branch_ne = 1'b1;

                sign_extend = 1'b1;

            end


            // =================================================
            // J
            // =================================================

            OP_J: begin

                jump = 1'b1;

            end


            // =================================================
            // JAL
            // =================================================

            OP_JAL: begin

                jump = 1'b1;
                jump_link = 1'b1;

                reg_write = 1'b1;
                reg_dst   = DST_RA;

            end


            // =================================================
            // UNKNOWN INSTRUCTION
            // =================================================

            default: begin

                // All controls remain disabled.

            end

        endcase

    end

endmodule