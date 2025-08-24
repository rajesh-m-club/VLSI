// =============================================================
// UART Transmitter (8N1): 1 start + 8 data + 1 stop = 10 bits
// =============================================================
`timescale 1ns/1ps

module UART_tx #(
    parameter integer BAUD_DIV = 5208   // example: 50MHz/9600
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_start,        // pulse high to send data
    input  wire [7:0] data_in,         // 8-bit BPM value
    output reg        tx,              // UART TX line
    output reg        busy             // High while transmitting
);

    // ------------ Baud generator ------------
    reg [$clog2(BAUD_DIV)-1:0] baud_cnt;
    wire baud_tick = (baud_cnt == 0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            baud_cnt <= BAUD_DIV - 1;
        else if (busy) begin
            if (baud_cnt == 0)
                baud_cnt <= BAUD_DIV - 1;
            else
                baud_cnt <= baud_cnt - 1;
        end else
            baud_cnt <= BAUD_DIV - 1;
    end

    // ------------ Shift register + counter ------------
    reg [9:0] shifter;   // [0]=start(0), [8:1]=data, [9]=stop(1)
    reg [3:0] bit_idx;   // counts 0..9
    reg       state;

    localparam IDLE = 1'b0,
               XMIT = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= IDLE;
            tx      <= 1'b1; // idle high
            busy    <= 1'b0;
            shifter <= 10'b1111111111;
            bit_idx <= 4'd0;
        end else begin
            case (state)
                IDLE: begin
                    tx   <= 1'b1;
                    busy <= 1'b0;
                    if (tx_start) begin
                        // Load frame: start(0), data, stop(1)
                        shifter <= {1'b1, data_in, 1'b0};
                        bit_idx <= 4'd0;
                        busy    <= 1'b1;
                        state   <= XMIT;
                        tx      <= 1'b0; // drive start immediately
                    end
                end

                XMIT: begin
                    if (baud_tick) begin
                        shifter <= {1'b1, shifter[9:1]}; // shift right, keep MSB=1
                        bit_idx <= bit_idx + 1'b1;
                        tx      <= shifter[1]; // next bit
                        if (bit_idx == 4'd9) begin
                            state <= IDLE;
                            busy  <= 1'b0;
                            tx    <= 1'b1; // back to idle
                        end
                    end
                end
            endcase
        end
    end

endmodule
