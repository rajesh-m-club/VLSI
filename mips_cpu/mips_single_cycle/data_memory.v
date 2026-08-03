`timescale 1ns/1ps

module data_memory #(

    parameter MEMORY_SIZE = 4096

)(

    input wire        clk,

    input wire [31:0] address,

    input wire [31:0] write_data,

    input wire        mem_read,

    input wire        mem_write,

    output wire [31:0] read_data

);


    // =========================================================
    // BYTE-ADDRESSABLE DATA MEMORY
    // =========================================================

    reg [7:0] memory [0:MEMORY_SIZE-1];


    // =========================================================
    // ASYNCHRONOUS READ
    // =========================================================

    assign read_data = mem_read ?

        {

            memory[address],

            memory[address + 32'd1],

            memory[address + 32'd2],

            memory[address + 32'd3]

        }

        : 32'b0;


    // =========================================================
    // SYNCHRONOUS WRITE
    // =========================================================

    always @(posedge clk) begin

        if (mem_write) begin

            memory[address]     <= write_data[31:24];

            memory[address + 1] <= write_data[23:16];

            memory[address + 2] <= write_data[15:8];

            memory[address + 3] <= write_data[7:0];

        end

    end


endmodule