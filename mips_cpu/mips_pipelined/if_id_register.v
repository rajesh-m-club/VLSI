`timescale 1ns/1ps

module if_id_register (

    input  wire        clk,
    input  wire        reset,

    // Write enable (used for pipeline stalls)
    input  wire        write_enable,

    // Flush (used after branch/jump)
    input  wire        flush,

    // Inputs from IF stage
    input  wire [31:0] instruction_in,
    input  wire [31:0] pc_plus_4_in,

    // Outputs to ID stage
    output reg  [31:0] instruction_out,
    output reg  [31:0] pc_plus_4_out

);

    always @(posedge clk) begin

        if (reset) begin

            instruction_out <= 32'b0;
            pc_plus_4_out   <= 32'b0;

        end

        else if (flush) begin

            // Insert a NOP into pipeline

            instruction_out <= 32'b0;
            pc_plus_4_out   <= 32'b0;

        end

        else if (write_enable) begin

            instruction_out <= instruction_in;
            pc_plus_4_out   <= pc_plus_4_in;

        end

    end

endmodule