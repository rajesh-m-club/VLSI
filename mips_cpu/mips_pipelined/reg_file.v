module reg_file (
    input  wire        clk,
    input  wire        reset,

    input  wire [4:0]  read_addr1,
    output wire [31:0] read_data1,

    input  wire [4:0]  read_addr2,
    output wire [31:0] read_data2,

    input  wire        write_enable,
    input  wire [4:0]  write_addr,
    input  wire [31:0] write_data
);

    reg [31:0] registers [0:31];
    integer i;

    // -----------------------------------------------------
    // Read ports, with same-cycle write-first bypass.
    //
    // If this cycle's WB write targets the same register
    // being read this cycle, forward write_data directly
    // instead of the (stale, pre-write) stored value.
    // -----------------------------------------------------

    assign read_data1 = (write_enable && (write_addr == read_addr1)) ? write_data : registers[read_addr1];

    assign read_data2 = (write_enable && (write_addr == read_addr2)) ? write_data : registers[read_addr2];

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end
        else if (write_enable && (write_addr != 5'd0)) begin
            registers[write_addr] <= write_data;
        end
    end

endmodule