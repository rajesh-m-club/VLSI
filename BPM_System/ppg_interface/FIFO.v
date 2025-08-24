module FIFO #(
    parameter WIDTH = 10,
    parameter DEPTH = 32
)(
    input  wire                  clk,
    input  wire                  reset,    // Active-high synchronous reset
    input  wire                  wr_en,
    input  wire                  rd_en,
    input  wire [WIDTH-1:0]      Data_in,
    output reg  [WIDTH-1:0]      Data_out,
    output wire                   full,
    output wire                   empty
);

    // Memory
    reg [WIDTH-1:0] ppg_data [DEPTH-1:0];

    // Pointers
    reg [$clog2(DEPTH)-1:0] wr_ptr;
    reg [$clog2(DEPTH)-1:0] rd_ptr;

    // Counter
    reg [$clog2(DEPTH):0] count;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    always @(posedge clk) begin
        if (reset) begin
            wr_ptr   <= 0;
            rd_ptr   <= 0;
            count    <= 0;
            Data_out <= 0;
        end else begin
            // Write
            if (wr_en) begin
                ppg_data[wr_ptr] <= Data_in;
                wr_ptr <= (wr_ptr + 1) % DEPTH;
                if (full) begin
                    rd_ptr <= (rd_ptr + 1) % DEPTH; // discard oldest data
                end else begin
                    count <= count + 1;
                end
            end

            // Read
            if (rd_en && !empty) begin
                Data_out <= ppg_data[rd_ptr];
                rd_ptr <= (rd_ptr + 1) % DEPTH;
                count <= count - 1;
            end
        end
    end
endmodule
