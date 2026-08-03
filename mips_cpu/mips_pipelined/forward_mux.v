`timescale 1ns/1ps

module forward_mux (

    input  wire [31:0] normal_data,
    input  wire [31:0] ex_mem_data,
    input  wire [31:0] mem_wb_data,

    input  wire [1:0]  forward_sel,

    output reg  [31:0] out_data

);

    always @(*) begin

        case (forward_sel)

            // No forwarding
            2'b00:
                out_data = normal_data;

            // Forward from MEM/WB
            2'b01:
                out_data = mem_wb_data;

            // Forward from EX/MEM
            2'b10:
                out_data = ex_mem_data;

            // Reserved
            default:
                out_data = normal_data;

        endcase

    end

endmodule