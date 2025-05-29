module hybrid_traffic_signal_control_fsm (
    input clk,
    input reset,
    input emergency_right,  // Emergency Right Mode (Stops both T1 and T2 for 10 mins)
    input emergency_left,   // Emergency Left Mode (Stops only T1)
    output reg [2:0] T1,         // T1 traffic light signal
    output reg [2:0] T2,         // T2 traffic light signal
    output reg buzzer_1,         // Buzzer for T1 (last 5s of RED)
    output reg buzzer_2,         // Buzzer for T2 (last 5s of RED)
    output reg T1_walk,          // Walk signal for T1
    output reg T2_walk           // Walk signal for T2
);

    // Traffic light states
    parameter RED = 2'b00, GREEN = 2'b01, YELLOW = 2'b10;
    reg [1:0] state_T1, next_state_T1;
    reg [1:0] state_T2, next_state_T2;

    reg [7:0] timer_T1;
    reg [7:0] timer_T2;
    reg [23:0] emergency_timer;

    // Time parameters
    parameter T_RED = 35;    // 35 sec @ 0.5s
    parameter T_GREEN = 30;  // 30 sec
    parameter T_YELLOW = 5; // 5 sec
    parameter EMERGENCY_TIME = 600; // 10 minutes (in clock cycles)

    // T1 FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_T1 <= RED;
            timer_T1 <= 0;
        end else if (emergency_right || emergency_left) begin
            state_T1 <= RED;
            timer_T1 <= 0;
        end else begin
            state_T1 <= next_state_T1;
            timer_T1 <= (state_T1 != next_state_T1) ? 0 : timer_T1 + 1;
        end
    end

    // T2 FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_T2 <= GREEN;
            timer_T2 <= 0;
            emergency_timer <= 0;
        end else if (emergency_right) begin
            if (emergency_timer < EMERGENCY_TIME) begin
                emergency_timer <= emergency_timer + 1;
                state_T2 <= RED;
            end else begin
                emergency_timer <= 0;
                state_T2 <= next_state_T2;
            end
        end else begin
            state_T2 <= next_state_T2;
            timer_T2 <= (state_T2 != next_state_T2) ? 0 : timer_T2 + 1;
        end
    end

    // T1 transition logic
    always @(*) begin
        next_state_T1 = state_T1;
        case (state_T1)
            RED:    if (timer_T1 >= T_RED)    next_state_T1 = GREEN;
            GREEN:  if (timer_T1 >= T_GREEN)  next_state_T1 = YELLOW;
            YELLOW: if (timer_T1 >= T_YELLOW) next_state_T1 = RED;
        endcase
    end

    // T2 transition logic
    always @(*) begin
        next_state_T2 = state_T2;
        case (state_T2)
            RED:    if (timer_T2 >= T_RED)    next_state_T2 = GREEN;
            GREEN:  if (timer_T2 >= T_GREEN)  next_state_T2 = YELLOW;
            YELLOW: if (timer_T2 >= T_YELLOW) next_state_T2 = RED;
        endcase
    end

    // Output logic
    always @(*) begin
        T1 = 3'b100;  // Default RED
        T2 = 3'b100;
        buzzer_1 = 0;
        buzzer_2 = 0;

        case (state_T1)
            RED: begin
                T1 = 3'b100;
                if (timer_T1 >= T_RED - 5) buzzer_1 = 1;  // last 5 sec
            end
            GREEN:  T1 = 3'b001;
            YELLOW: T1 = 3'b010;
        endcase

        case (state_T2)
            RED: begin
                T2 = 3'b100;
                if (timer_T2 >= T_RED - 5) buzzer_2 = 1;  // last 5 sec
            end
            GREEN:  T2 = 3'b001;
            YELLOW: T2 = 3'b010;
        endcase
    end

    // Walk signal logic
    always @(*) begin
        if (emergency_right || emergency_left) begin
            T1_walk = 0;
            T2_walk = 0;
        end else begin
            T1_walk = (state_T1 == RED || state_T1 == YELLOW) ? 1 : 0;
            T2_walk = (state_T2 == RED || state_T2 == YELLOW) ? 1 : 0;
        end
    end

endmodule

