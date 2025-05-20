module bin_to_bcd #(
    parameter bin_width = 8,
    parameter bcd_digits = (bin_width*3)/10 +1
) (
    input [bin_width-1:0]bin,
    output reg [(4*bcd_digits-1):0]bcd
);
  localparam n = bin_width + 4 * bcd_digits;
  reg [(n-1) : 0]dig;
  always@(*) begin
    dig = {n{1'b0}};
    dig[bin_width-1:0] = bin;  
    for(integer i =0 ; i<bin_width ; i = i+1) begin
        for(integer j=0 ;j<bcd_digits;j=j+1) begin
            if(dig[bin_width+4*j+:4] >=5) dig[bin_width+4*j+:4] = dig[bin_width+4*j +: 4] +3;
        end
        dig = dig << 1;
    end
    bcd = dig [n-1:bin_width];
  end  
endmodule