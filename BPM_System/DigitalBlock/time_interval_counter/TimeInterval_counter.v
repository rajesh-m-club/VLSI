module TimeInterval_counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       peak_detected,
    input  wire       en,
    input  wire       BPMCalc_Done,
    input  wire       valid_pre,      // NEW: 25 Hz valid strobe
    output reg  [5:0] time_counter,
    output reg        valid
);

    localparam s_Idle  = 2'b00;
    localparam s_count = 2'b01;
    localparam s_stop  = 2'b11;

    reg [1:0] state, next_state;

    // FSM next state logic
    always @(*) begin
        case (state)
            s_Idle: begin
                if (en && peak_detected)
                    next_state = s_count;
                else
                    next_state = s_Idle;
            end
            s_count: begin
                if (peak_detected)
                    next_state = s_stop;
                else
                    next_state = s_count;
            end
            s_stop: begin
                if (BPMCalc_Done)
                    next_state = s_Idle;
                else
                    next_state = s_stop;
            end
            default: next_state = s_Idle;
        endcase
    end

    // FSM state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= s_Idle;
        else
            state <= next_state;
    end

    // Time counter + valid generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            time_counter <= 6'd0;
            valid        <= 1'b0;
        end else if (en) begin
            case (state)
                s_Idle: begin
                    time_counter <= 6'd0;
                    valid        <= 1'b0;
                end
                s_count: begin
                    if (valid_pre)                         // <--- count only on valid_pre
                        time_counter <= time_counter + 1'b1;
                    valid <= 1'b0;
                end
                s_stop: begin
                    time_counter <= time_counter; // hold value
                    valid        <= 1'b1;         // assert until BPMCalc_Done
                end
            endcase
        end
    end

endmodule
