`timescale 1s / 1ms  // 1 simulation second = 1 real millisecond

module tb_hybrid_traffic;

  reg clk, reset;
  reg emergency_right, emergency_left;
  wire [2:0] T1, T2;
  wire buzzer_1, buzzer_2;
  wire T1_walk, T2_walk;

  hybrid_traffic_signal_control_fsm uut (
    .clk(clk), .reset(reset),
    .emergency_right(emergency_right),
    .emergency_left(emergency_left),
    .T1(T1), .T2(T2),
    .buzzer_1(buzzer_1), .buzzer_2(buzzer_2),
    .T1_walk(T1_walk), .T2_walk(T2_walk)
  );

  // Clock generator: 1 Hz (1s period)
  initial clk = 0;
  always #0.5 clk = ~clk;

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_hybrid_traffic);

    reset = 1; emergency_right = 0; emergency_left = 0;
    #2 reset = 0;

    // Run normal for a while
    #150;

    // Trigger emergency left (T1 stops)
    emergency_left = 1;
    #30 emergency_left = 0;

    // Trigger emergency right (T1 and T2 stop for 10 mins = 600s)
    emergency_right = 1;
    #20 emergency_right = 0;

    #1000 $finish;
  end

endmodule

