module BPM_Calculator #(
    parameter WIDTH = 6,      // interval_count width (up to 63)
    parameter FS    = 25      // downsampled sampling rate (Hz)
)(
    input  wire               clk,
    input  wire               rst_n,
    input  wire               en,
    input  wire [WIDTH-1:0]   interval_count, // ticks @ FS Hz
    input  wire               interval_valid,
    output reg  [7:0]         bpm_value,
    output reg                bpm_valid,
    input  wire               bpm_copied
);

    // =============================================================
    // Constants
    // =============================================================
    localparam integer NUMERATOR = 60 * FS;  // 60 seconds * FS (samples/sec)

    // =============================================================
    // Combinational intermediate signals
    // =============================================================
    reg [7:0] bpm_next;
    reg       valid_next;

    // Combinational logic to calculate next values
    always @(*) begin
        // Default assignments to keep previous values
        bpm_next  = bpm_value;
        valid_next = bpm_valid;

        if (en && interval_valid && !bpm_valid) begin
            case(interval_count)
                0: bpm_next = 8'd0;
                1: bpm_next = (NUMERATOR/1 > 255) ? 8'd255 : NUMERATOR/1;
                2: bpm_next = (NUMERATOR/2 > 255) ? 8'd255 : NUMERATOR/2;
                3: bpm_next = (NUMERATOR/3 > 255) ? 8'd255 : NUMERATOR/3;
                4: bpm_next = (NUMERATOR/4 > 255) ? 8'd255 : NUMERATOR/4;
                5: bpm_next = (NUMERATOR/5 > 255) ? 8'd255 : NUMERATOR/5;
                6: bpm_next = (NUMERATOR/6 > 255) ? 8'd255 : NUMERATOR/6;
                7: bpm_next = (NUMERATOR/7 > 255) ? 8'd255 : NUMERATOR/7;
                8: bpm_next = (NUMERATOR/8 > 255) ? 8'd255 : NUMERATOR/8;
                9: bpm_next = (NUMERATOR/9 > 255) ? 8'd255 : NUMERATOR/9;
                10: bpm_next = (NUMERATOR/10 > 255) ? 8'd255 : NUMERATOR/10;
                11: bpm_next = (NUMERATOR/11 > 255) ? 8'd255 : NUMERATOR/11;
                12: bpm_next = (NUMERATOR/12 > 255) ? 8'd255 : NUMERATOR/12;
                13: bpm_next = (NUMERATOR/13 > 255) ? 8'd255 : NUMERATOR/13;
                14: bpm_next = (NUMERATOR/14 > 255) ? 8'd255 : NUMERATOR/14;
                15: bpm_next = (NUMERATOR/15 > 255) ? 8'd255 : NUMERATOR/15;
                16: bpm_next = (NUMERATOR/16 > 255) ? 8'd255 : NUMERATOR/16;
                17: bpm_next = (NUMERATOR/17 > 255) ? 8'd255 : NUMERATOR/17;
                18: bpm_next = (NUMERATOR/18 > 255) ? 8'd255 : NUMERATOR/18;
                19: bpm_next = (NUMERATOR/19 > 255) ? 8'd255 : NUMERATOR/19;
                20: bpm_next = (NUMERATOR/20 > 255) ? 8'd255 : NUMERATOR/20;
                21: bpm_next = (NUMERATOR/21 > 255) ? 8'd255 : NUMERATOR/21;
                22: bpm_next = (NUMERATOR/22 > 255) ? 8'd255 : NUMERATOR/22;
                23: bpm_next = (NUMERATOR/23 > 255) ? 8'd255 : NUMERATOR/23;
                24: bpm_next = (NUMERATOR/24 > 255) ? 8'd255 : NUMERATOR/24;
                25: bpm_next = (NUMERATOR/25 > 255) ? 8'd255 : NUMERATOR/25;
                26: bpm_next = (NUMERATOR/26 > 255) ? 8'd255 : NUMERATOR/26;
                27: bpm_next = (NUMERATOR/27 > 255) ? 8'd255 : NUMERATOR/27;
                28: bpm_next = (NUMERATOR/28 > 255) ? 8'd255 : NUMERATOR/28;
                29: bpm_next = (NUMERATOR/29 > 255) ? 8'd255 : NUMERATOR/29;
                30: bpm_next = (NUMERATOR/30 > 255) ? 8'd255 : NUMERATOR/30;
                31: bpm_next = (NUMERATOR/31 > 255) ? 8'd255 : NUMERATOR/31;
                32: bpm_next = (NUMERATOR/32 > 255) ? 8'd255 : NUMERATOR/32;
                33: bpm_next = (NUMERATOR/33 > 255) ? 8'd255 : NUMERATOR/33;
                34: bpm_next = (NUMERATOR/34 > 255) ? 8'd255 : NUMERATOR/34;
                35: bpm_next = (NUMERATOR/35 > 255) ? 8'd255 : NUMERATOR/35;
                36: bpm_next = (NUMERATOR/36 > 255) ? 8'd255 : NUMERATOR/36;
                37: bpm_next = (NUMERATOR/37 > 255) ? 8'd255 : NUMERATOR/37;
                38: bpm_next = (NUMERATOR/38 > 255) ? 8'd255 : NUMERATOR/38;
                39: bpm_next = (NUMERATOR/39 > 255) ? 8'd255 : NUMERATOR/39;
                40: bpm_next = (NUMERATOR/40 > 255) ? 8'd255 : NUMERATOR/40;
                41: bpm_next = (NUMERATOR/41 > 255) ? 8'd255 : NUMERATOR/41;
                42: bpm_next = (NUMERATOR/42 > 255) ? 8'd255 : NUMERATOR/42;
                43: bpm_next = (NUMERATOR/43 > 255) ? 8'd255 : NUMERATOR/43;
                44: bpm_next = (NUMERATOR/44 > 255) ? 8'd255 : NUMERATOR/44;
                45: bpm_next = (NUMERATOR/45 > 255) ? 8'd255 : NUMERATOR/45;
                46: bpm_next = (NUMERATOR/46 > 255) ? 8'd255 : NUMERATOR/46;
                47: bpm_next = (NUMERATOR/47 > 255) ? 8'd255 : NUMERATOR/47;
                48: bpm_next = (NUMERATOR/48 > 255) ? 8'd255 : NUMERATOR/48;
                49: bpm_next = (NUMERATOR/49 > 255) ? 8'd255 : NUMERATOR/49;
                50: bpm_next = (NUMERATOR/50 > 255) ? 8'd255 : NUMERATOR/50;
                51: bpm_next = (NUMERATOR/51 > 255) ? 8'd255 : NUMERATOR/51;
                52: bpm_next = (NUMERATOR/52 > 255) ? 8'd255 : NUMERATOR/52;
                53: bpm_next = (NUMERATOR/53 > 255) ? 8'd255 : NUMERATOR/53;
                54: bpm_next = (NUMERATOR/54 > 255) ? 8'd255 : NUMERATOR/54;
                55: bpm_next = (NUMERATOR/55 > 255) ? 8'd255 : NUMERATOR/55;
                56: bpm_next = (NUMERATOR/56 > 255) ? 8'd255 : NUMERATOR/56;
                57: bpm_next = (NUMERATOR/57 > 255) ? 8'd255 : NUMERATOR/57;
                58: bpm_next = (NUMERATOR/58 > 255) ? 8'd255 : NUMERATOR/58;
                59: bpm_next = (NUMERATOR/59 > 255) ? 8'd255 : NUMERATOR/59;
                60: bpm_next = (NUMERATOR/60 > 255) ? 8'd255 : NUMERATOR/60;
                61: bpm_next = (NUMERATOR/61 > 255) ? 8'd255 : NUMERATOR/61;
                62: bpm_next = (NUMERATOR/62 > 255) ? 8'd255 : NUMERATOR/62;
                63: bpm_next = (NUMERATOR/63 > 255) ? 8'd255 : NUMERATOR/63;
                default: bpm_next = 8'd255;
            endcase
            valid_next = 1'b1;
        end else if (bpm_valid && bpm_copied) begin
            valid_next = 1'b0;
        end
    end

    // =============================================================
    // Sequential block: registers update
    // =============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bpm_value <= 0;
            bpm_valid <= 0;
        end else begin
            bpm_value <= bpm_next;
            bpm_valid <= valid_next;
        end
    end

endmodule
