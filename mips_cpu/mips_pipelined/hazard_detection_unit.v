`timescale 1ns/1ps

module hazard_detection_unit (

    //==========================================================
    // Instruction currently in ID/EX
    //==========================================================

    input wire        id_ex_mem_read,
    input wire [4:0]  id_ex_rt,

    //==========================================================
    // Instruction currently in IF/ID
    //==========================================================

    input wire [5:0]  if_id_opcode,
    input wire [5:0]  if_id_funct,

    input wire [4:0]  if_id_rs,
    input wire [4:0]  if_id_rt,

    //==========================================================
    // Hazard control outputs
    //==========================================================

    output reg pc_write,
    output reg if_id_write,
    output reg control_flush

);

    //==========================================================
    // MIPS opcodes
    //==========================================================

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


    //==========================================================
    // R-type function codes
    //==========================================================

    localparam FUNCT_JR = 6'b001000;
    localparam FUNCT_SLL = 6'b000000;
    localparam FUNCT_SRL = 6'b000010;


    //==========================================================
    // Determine which source registers are actually used
    // by the instruction currently in IF/ID.
    //==========================================================

    reg uses_rs;
    reg uses_rt;


    always @(*) begin

        //------------------------------------------------------
        // Defaults
        //------------------------------------------------------

        uses_rs = 1'b0;
        uses_rt = 1'b0;


        //------------------------------------------------------
        // Determine source registers
        //------------------------------------------------------

        case (if_id_opcode)

            //==================================================
            // R-TYPE
            //==================================================

            OP_RTYPE: begin

                case (if_id_funct)

                    // JR uses rs
                    FUNCT_JR: begin
                        uses_rs = 1'b1;
                        uses_rt = 1'b0;
                    end

                    // SLL / SRL use rt only
                    FUNCT_SLL,
                    FUNCT_SRL: begin
                        uses_rs = 1'b0;
                        uses_rt = 1'b1;
                    end

                    // ADD, SUB, AND, OR, SLT
                    default: begin
                        uses_rs = 1'b1;
                        uses_rt = 1'b1;
                    end

                endcase

            end


            //==================================================
            // LW
            //==================================================

            OP_LW: begin

                // Base address comes from rs
                uses_rs = 1'b1;
                uses_rt = 1'b0;

            end


            //==================================================
            // SW
            //==================================================

            OP_SW: begin

                // Base address = rs
                // Store data   = rt
                uses_rs = 1'b1;
                uses_rt = 1'b1;

            end


            //==================================================
            // BEQ / BNE
            //==================================================

            OP_BEQ,
            OP_BNE: begin

                uses_rs = 1'b1;
                uses_rt = 1'b1;

            end


            //==================================================
            // ADDI / ANDI / ORI
            //==================================================

            OP_ADDI,
            OP_ANDI,
            OP_ORI: begin

                // Immediate ALU instruction uses rs only
                uses_rs = 1'b1;
                uses_rt = 1'b0;

            end


            //==================================================
            // J / JAL
            //==================================================

            OP_J,
            OP_JAL: begin

                // No register source operands
                uses_rs = 1'b0;
                uses_rt = 1'b0;

            end


            //==================================================
            // Unknown opcode
            //==================================================

            default: begin

                uses_rs = 1'b0;
                uses_rt = 1'b0;

            end

        endcase


        //======================================================
        // Default hazard controls
        //======================================================

        pc_write      = 1'b1;
        if_id_write   = 1'b1;
        control_flush = 1'b0;


        //======================================================
        // Load-use hazard
        //======================================================

        if (id_ex_mem_read &&
            (id_ex_rt != 5'd0) &&
            (
                (uses_rs && (id_ex_rt == if_id_rs)) ||
                (uses_rt && (id_ex_rt == if_id_rt))
            )
        ) begin

            //--------------------------------------------------
            // Freeze PC
            //--------------------------------------------------

            pc_write = 1'b0;


            //--------------------------------------------------
            // Freeze IF/ID
            //--------------------------------------------------

            if_id_write = 1'b0;


            //--------------------------------------------------
            // Insert NOP into ID/EX
            //--------------------------------------------------

            control_flush = 1'b1;

        end

    end

endmodule