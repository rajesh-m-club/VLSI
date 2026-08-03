`timescale 1ns/1ps

module jump_target (

    input wire [31:0] pc_plus_4,

    input wire [25:0] jump_index,

    output wire [31:0] jump_target

);

    assign jump_target = {

        pc_plus_4[31:28],

        jump_index,

        2'b00

    };

endmodule