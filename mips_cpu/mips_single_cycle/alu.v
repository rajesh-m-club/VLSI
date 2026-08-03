module alu (

    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,

    // Shift amount from instruction[10:6]
    input  wire [4:0]  shamt,

    input  wire [2:0]  alu_control,

    output reg  [31:0] result,
    output wire        zero

);


    // =========================================================
    // ALU OPERATION ENCODING
    // =========================================================

    localparam ALU_ADD = 3'b000;
    localparam ALU_SUB = 3'b001;
    localparam ALU_AND = 3'b010;
    localparam ALU_OR  = 3'b011;
    localparam ALU_SLT = 3'b100;
    localparam ALU_SLL = 3'b101;
    localparam ALU_SRL = 3'b110;


    // =========================================================
    // ALU OPERATION
    // =========================================================

    always @(*) begin

        case (alu_control)


            // -------------------------------------------------
            // ADD
            // -------------------------------------------------

            ALU_ADD:

                result = operand_a + operand_b;


            // -------------------------------------------------
            // SUBTRACT
            // -------------------------------------------------

            ALU_SUB:

                result = operand_a - operand_b;


            // -------------------------------------------------
            // AND
            // -------------------------------------------------

            ALU_AND:

                result = operand_a & operand_b;


            // -------------------------------------------------
            // OR
            // -------------------------------------------------

            ALU_OR:

                result = operand_a | operand_b;


            // -------------------------------------------------
            // SIGNED SET LESS THAN
            // -------------------------------------------------

            ALU_SLT:

                result =
                    ($signed(operand_a) < $signed(operand_b))
                    ? 32'd1
                    : 32'd0;


            // -------------------------------------------------
            // SHIFT LEFT LOGICAL
            // -------------------------------------------------
            //
            // sll rd, rt, shamt
            //
            // result = operand_b << shamt
            //
            // operand_b = value from rt
            // shamt     = instruction[10:6]
            //

            ALU_SLL:

                result = operand_b << shamt;


            // -------------------------------------------------
            // SHIFT RIGHT LOGICAL
            // -------------------------------------------------
            //
            // srl rd, rt, shamt
            //
            // result = operand_b >> shamt
            //
            // operand_b = value from rt
            // shamt     = instruction[10:6]
            //

            ALU_SRL:

                result = operand_b >> shamt;


            // -------------------------------------------------
            // DEFAULT
            // -------------------------------------------------

            default:

                result = 32'b0;


        endcase

    end


    // =========================================================
    // ZERO FLAG
    // =========================================================

    assign zero = (result == 32'b0);


endmodule