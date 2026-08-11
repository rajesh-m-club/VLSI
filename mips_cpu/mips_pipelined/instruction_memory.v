`timescale 1ns/1ps

module instruction_memory #(
    parameter MEMORY_SIZE = 4096,
    parameter PROGRAM_FILE = "program.hex"
)(
    input  wire [31:0] address,

    output wire [31:0] instruction
);

    // Byte-addressable memory
    reg [7:0] memory [0:MEMORY_SIZE-1];

    // Load program into memory during simulation
    initial begin
        $readmemh(PROGRAM_FILE, memory);
    end

    // Fetch four consecutive bytes
    assign instruction = {
        memory[address],
        memory[address + 32'd1],
        memory[address + 32'd2],
        memory[address + 32'd3]
    };

endmodule