module FIFO #(
    parameter WIDTH = 10,
    parameter DEPTH = 32
)(
    input  wire                  clk,
    input  wire                  reset,
    input  wire                  wr_en,
    input  wire                  rd_en,
    input  wire [WIDTH-1:0]      Data_in,
    output reg  [WIDTH-1:0]      Data_out,
    output wire                  full,
    output wire                  empty
);

    // Localparams
    localparam PTR_WIDTH = $clog2(DEPTH);
    localparam [PTR_WIDTH-1:0] DEPTH_M1 = PTR_WIDTH'(DEPTH - 1);

    // Memory array
    reg [WIDTH-1:0] ppg_data [0:DEPTH-1];

    // Pointers
    reg [PTR_WIDTH-1:0] wr_ptr;
    reg [PTR_WIDTH-1:0] rd_ptr;

    // Counter
    reg [PTR_WIDTH:0] count;

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
                if (wr_ptr == DEPTH_M1)
                    wr_ptr <= 0;
                else
                    wr_ptr <= wr_ptr + 1;

                if (full) begin
                    if (rd_ptr == DEPTH_M1)
                        rd_ptr <= 0;
                    else
                        rd_ptr <= rd_ptr + 1;
                end else begin
                    count <= count + 1;
                end
            end

            // Read
            if (rd_en && !empty) begin
                Data_out <= ppg_data[rd_ptr];
                if (rd_ptr == DEPTH_M1)
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1;

                count <= count - 1;
            end
        end
    end
endmodule
