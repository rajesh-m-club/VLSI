`timescale 1ns/1ps

module immediate_generator (
    input  wire [31:0] instruction,
    input  wire        sign_extend,

    output wire [31:0] immediate
);

    assign immediate = sign_extend
                     ? {{16{instruction[15]}}, instruction[15:0]}
                     : {16'b0, instruction[15:0]};

endmodule