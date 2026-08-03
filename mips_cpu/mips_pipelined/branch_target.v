`timescale 1ns/1ps

module branch_target (

    input  wire [31:0] pc_plus_4,

    input  wire [31:0] branch_offset,

    output wire [31:0] branch_target

);

    assign branch_target =
        pc_plus_4 + (branch_offset << 2);

endmodule