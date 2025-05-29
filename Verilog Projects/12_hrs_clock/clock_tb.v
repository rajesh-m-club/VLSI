
`timescale 1ms/1us

module clock_tb;

  reg clk;
  reg reset;
  reg ena;
  wire pm;
  wire [7:0] hh, mm, ss;

  top_module uut (
    .clk(clk),
    .reset(reset),
    .ena(ena),
    .pm(pm),
    .hh(hh),
    .mm(mm),
    .ss(ss)
  );

  always #0.5 clk = ~clk;  // 1Hz clock: period = 1ms (1 simulated second)

  initial begin
    $dumpfile("clock.vcd");
    $dumpvars(0, clock_tb);

    clk = 0;
    reset = 1;
    ena = 0;

    #2;
    reset = 0;
    ena = 1;

    // Simulate 24 hours = 24 * 60 * 60 = 86400 simulated seconds
    #86400;

    $finish;
  end

endmodule

