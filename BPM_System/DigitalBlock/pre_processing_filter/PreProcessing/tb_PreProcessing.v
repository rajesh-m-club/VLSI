`timescale 1ns/1ps

module tb_PreProcessing;

  // Parameters
  parameter Width     = 10;
  parameter SCALE     = 15;
  parameter DATA_LEN  = 1000; // max number of samples to read

  // DUT Inputs
  reg clk;
  reg rst_n;
  reg en;
  reg signed [Width-1:0] Data_in;

  // DUT Outputs
  wire signed [Width-1:0] Data_out;
  wire valid_out;

  // File & Memory
  integer infile, outfile;
  integer r;
  integer i;
  integer j;
  integer dummy;
  reg signed [Width-1:0] mem [0:DATA_LEN-1];

  // Clock Generation (20 ns period -> 50 MHz simulation)
  initial clk = 0;
  always #10 clk = ~clk;

  // Instantiate DUT
  PreProcessing #(
    .Width(Width),
    .SCALE(SCALE)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .en(en),
    .ppg_in(Data_in),
    .ppg_out(Data_out),
    .valid_out(valid_out)
  );

  initial begin
    // Initial values
    rst_n = 0;
    en = 0;
    Data_in = 0;

    // Hold reset low
    #50;
    rst_n = 1;
    en = 1;

    // ---------------------------
    // 1. OPEN INPUT CSV FILE
    // ---------------------------
    infile = $fopen("C:/Users/rajes/OneDrive/Desktop/VLSI/BPM_counter/DigitalBlock/pre_processing_filter/PreProcessing/ppg_input.csv", "r");
    if (infile == 0) begin
      $display("ERROR: Could not open ppg_input.csv");
      $finish;
    end

    // Skip header if present
    r = $fgetc(infile);
    if ((r >= "A" && r <= "Z") || (r >= "a" && r <= "z")) begin
      while (r != "\n" && r != "\r" && !$feof(infile))
        r = $fgetc(infile);
    end else begin
      $ungetc(r, infile);
    end

    // Read input CSV (two columns, skip second)
    i = 0;
    while (i < DATA_LEN && !$feof(infile)) begin
      r = $fscanf(infile, "%d,%d\n", mem[i], dummy);
      if (r >= 1) i = i + 1;
    end
    $fclose(infile);
    $display("INFO: Read %0d input samples from CSV", i);

    // ---------------------------
    // 2. OPEN OUTPUT FILE
    // ---------------------------
    outfile = $fopen("C:/Users/rajes/OneDrive/Desktop/VLSI/BPM_counter/DigitalBlock/pre_processing_filter/PreProcessing/ppg_output.csv", "w");
    if (outfile == 0) begin
      $display("ERROR: Could not open ppg_output.csv for writing");
      $finish;
    end
    $fwrite(outfile, "Input,Output\n");

    // ---------------------------
    // 3. APPLY INPUTS & LOG OUTPUTS
    // ---------------------------
    j = 0;
    while (j < i) begin
      Data_in = mem[j];
      #20; // wait one clock cycle
      if (valid_out) begin
        $fwrite(outfile, "%0d,%0d\n", mem[j], Data_out);
      end
      j = j + 1;
    end

    $fclose(outfile);
    $display("INFO: Simulation complete, output saved to ppg_output.csv");
    $stop;
  end

endmodule
