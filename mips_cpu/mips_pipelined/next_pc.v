`timescale 1ns/1ps

module next_pc (

    input wire [31:0] pc_plus_4,

    input wire [31:0] branch_target,

    input wire [31:0] jump_target,

    input wire [31:0] register_target,

    input wire        branch_eq,

    input wire        branch_ne,

    input wire        zero,

    input wire        jump,

    input wire        jump_reg,

    output reg [31:0] next_pc

);

    wire branch_taken;

    assign branch_taken =
        (branch_eq && zero) ||
        (branch_ne && !zero);


    always @(*) begin

        if (jump_reg)

            next_pc = register_target;

        else if (jump)

            next_pc = jump_target;

        else if (branch_taken)

            next_pc = branch_target;

        else

            next_pc = pc_plus_4;

    end

endmodule