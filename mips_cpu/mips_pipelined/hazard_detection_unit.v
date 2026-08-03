module hazard_detection_unit (

    input  wire        id_ex_mem_read,

    input  wire [4:0]  id_ex_rt,

    input  wire [4:0]  if_id_rs,
    input  wire [4:0]  if_id_rt,

    output reg         pc_write,
    output reg         if_id_write,
    output reg         control_flush

);

always @(*) begin

    // Default: no hazard
    pc_write     = 1'b1;
    if_id_write  = 1'b1;
    control_flush = 1'b0;

    // Load-use hazard
    if (id_ex_mem_read &&
       ((id_ex_rt == if_id_rs) ||
        (id_ex_rt == if_id_rt))) begin

        pc_write      = 1'b0;
        if_id_write   = 1'b0;
        control_flush = 1'b1;

    end

end

endmodule