module clock(
    input clk,
    input reset,
    input ena,
    output reg pm,
    output reg [7:0] hh,
    output reg [7:0] mm,
    output reg [7:0] ss); 
    wire [1:0]en_hh,en_mm;
    wire en_s;
    assign en_s = ena && (ss[0 +: 4] == 4'd9);
    assign en_mm[0] = en_s && (ss[4 +: 4] == 4'd5);
    assign en_mm[1] = en_mm[0] && (mm[0 +: 4] == 4'd9);
    assign en_hh[0] = en_mm[1] && (mm[4 +: 4] == 4'd5);
    assign en_hh[1] = en_hh[0] && (hh[0 +: 4] == 4'd9);
    always @(posedge clk) begin
        if(reset) begin
            hh <= {4'd1,4'd2};
            mm <= 8'b0;
            ss <= 8'b0;
	    pm <= 0;
        end
        else begin
            if (ena && (ss[0 +: 4] == 4'd9)) ss[0 +: 4] <= 4'd0;
            else if(ena) ss[0 +: 4] <= ss[0 +: 4] +1;
            if (en_s && (ss[4 +: 4] == 4'd5)) ss[4 +: 4] <= 4'd0;
            else if(en_s) ss[4 +: 4] <= ss[4 +: 4] + 1;
            if(en_mm[0] && (mm[0 +: 4] == 4'd9)) mm[0 +: 4] <= 4'd0;
            else if (en_mm[0]) mm[0 +: 4] <= mm[0 +: 4] + 1;
            if(en_mm[1] && (mm[4 +: 4] == 4'd5)) mm[4 +: 4] <= 4'd0;
            else if (en_mm[1]) mm[4 +: 4] <= mm[4 +: 4] + 1;
            if(en_hh[0] && (hh[0 +: 4] == 4'd9)) hh[0 +: 4] <= 4'd0;
            else if (en_hh[0] && (hh[4 +: 4] == 4'd1) && (hh[0 +: 4] == 4'd2)) hh[0 +: 4] <= 4'd1;
            else if (en_hh[0]) hh[0 +: 4] <= hh[0 +: 4] + 1;
            if(en_hh[0] && (hh[4 +: 4] == 4'd1) && (hh[0 +: 4] == 4'd2)) hh[4 +: 4] <= 4'd0;
            else if(en_hh[1]) hh[4 +: 4] <= hh[4 +: 4] + 1;
        end
        // Toggle PM before time increments from 11:59:59 to 12:00:00
if (ena && hh == 8'h11 && mm == 8'h59 && ss == 8'h59)
    pm <= ~pm;

    end

endmodule

