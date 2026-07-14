`timescale 1ns/1ps

module tb_fixed_point_operations;

    
    reg clk;
    localparam integer CLK_PERIOD = 20833; // ns

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    
    reg  signed [16:0] q_314;
    reg  signed [16:0] q_512;
    reg  [1:0]         operation;
    wire signed [16:0] out_q_512;

    
    fixed_point_operations dut (
        .q_314     (q_314),
        .q_512     (q_512),
        .operation (operation),
        .clk       (clk),
        .out_q_512 (out_q_512)
    );

    
    reg signed [16:0] q314_mem [0:479];
    reg signed [16:0] q512_mem [0:479];

    integer infile;
    integer add_file, sub_file, mul_file;
    integer i, status;
    reg [1023:0] header;

    
    initial begin
        $dumpfile("tb_fixed_point_operations.vcd");
        $dumpvars(0, tb_fixed_point_operations);
    end

    
    initial begin
        infile = $fopen("sine_q314_q512_binary.csv", "r");
        if (infile == 0) begin
            $display("ERROR: Cannot open input CSV");
            $finish;
        end

        // Skip header
        $fgets(header, infile);

        // Read 480 samples
        for (i = 0; i < 480; i = i + 1) begin
            status = $fscanf(
                infile,
                "%*d,%b,%*d,%b\n",
                q314_mem[i],
                q512_mem[i]
            );

            if (status != 2) begin
                $display("ERROR: CSV read failed at sample %0d", i);
                $finish;
            end
        end
        $fclose(infile);

        
        add_file = $fopen("results_add.csv", "w");
        sub_file = $fopen("results_sub.csv", "w");
        mul_file = $fopen("results_mul.csv", "w");

        if (add_file == 0 || sub_file == 0 || mul_file == 0) begin
            $display("ERROR: Cannot open output CSVs");
            $finish;
        end

        $fwrite(add_file, "q314,q512,add_out\n");
        $fwrite(sub_file, "q314,q512,sub_out\n");
        $fwrite(mul_file, "q314,q512,mul_out\n");

        
        q_314     = 0;
        q_512     = 0;
        operation = 0;
        @(posedge clk);

        
        operation = 2'b00;

        // Prime pipeline
        q_314 = q314_mem[0];
        q_512 = q512_mem[0];
        @(posedge clk);

        for (i = 1; i < 480; i = i + 1) begin
            q_314 = q314_mem[i];
            q_512 = q512_mem[i];
            @(posedge clk);

            $fwrite(add_file, "%0d,%0d,%0d\n",
                    q314_mem[i-1],
                    q512_mem[i-1],
                    out_q_512);
        end

        
        operation = 2'b01;

        q_314 = q314_mem[0];
        q_512 = q512_mem[0];
        @(posedge clk);

        for (i = 1; i < 480; i = i + 1) begin
            q_314 = q314_mem[i];
            q_512 = q512_mem[i];
            @(posedge clk);

            $fwrite(sub_file, "%0d,%0d,%0d\n",
                    q314_mem[i-1],
                    q512_mem[i-1],
                    out_q_512);
        end

        
        operation = 2'b10;

        q_314 = q314_mem[0];
        q_512 = q512_mem[0];
        @(posedge clk);

        for (i = 1; i < 480; i = i + 1) begin
            q_314 = q314_mem[i];
            q_512 = q512_mem[i];
            @(posedge clk);

            $fwrite(mul_file, "%0d,%0d,%0d\n",
                    q314_mem[i-1],
                    q512_mem[i-1],
                    out_q_512);
        end

        
        $fclose(add_file);
        $fclose(sub_file);
        $fclose(mul_file);

        $display("Simulation completed successfully");
        $finish;
    end

endmodule
