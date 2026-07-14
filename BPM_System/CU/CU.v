// =============================================================
// CU for Mode B: Process only when 'check' pulse is generated
// - FIFO_in is written by sensor continuously (outside CU)
// - CU reads FIFO_in only during a check session
// - DigitalBlock enabled only during a check session
// - On bpm_valid: write 1-deep buffer, ack with bpm_copied, stop
// =============================================================
// =============================================================
// CU with 3s Display Timer @10MHz + Restart on New Check
// - FIFO_in is filled continuously by sensor (outside CU)
// - On check: enable DigitalBlock, feed samples, wait for bpm_valid
// - On bpm_valid: latch BPM, show for 3s, then clear
// - If user presses check again within 3s: reset & restart immediately
// =============================================================
module CU #(
    parameter integer PPG_WIDTH     =
     10,
    parameter integer CLK_FREQ_HZ   = 10_000_000,  // 10 MHz system clock
    parameter integer SHOW_TIME_SEC = 3            // show BPM for 3 seconds
)(
    input  wire                         clk,
    input  wire                         rst_n,

    // ---- User control ----
    input  wire                         check_btn,     // asynchronous/user domain
    input  wire                         en,            // global enable (optional)

    // ---- FIFO_in (PPG samples) ----
    input  wire                         fifo_in_empty,
    output reg                          fifo_in_rd,
    input  wire signed [PPG_WIDTH-1:0]  fifo_in_dout,

    // ---- DigitalBlock interface ----
    output reg                          db_en,
    output reg  signed [PPG_WIDTH-1:0]  ppg_in,        // registered input to DB
    input  wire        [7:0]            bpm_value,
    input  wire                         bpm_valid,
    output reg                          bpm_copied,

    // ---- Output to UI/Display ----
    output reg         [7:0]            bpm_latest,    // latched BPM for UI
    output reg                          bpm_ready_out  // 1-cycle pulse when bpm_latest updates
);

    // ---------------------------------------------------------
    // Sync + edge-detect for check button (2FF sync)
    // ---------------------------------------------------------
    reg check_sync1, check_sync2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            check_sync1 <= 1'b0;
            check_sync2 <= 1'b0;
        end else begin
            check_sync1 <= check_btn;
            check_sync2 <= check_sync1;
        end
    end
    wire check_rise = check_sync1 & ~check_sync2; // 1-cycle pulse on rising edge

    // ---------------------------------------------------------
    // FSM
    // ---------------------------------------------------------
    localparam [2:0]
        IDLE    = 3'd0,
        START   = 3'd1,
        FEED    = 3'd2,
        CAPTURE = 3'd3,
        STOP    = 3'd4;

    reg [2:0] state, next_state;

    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end

    // ---------------------------------------------------------
    // Display timer params (3s @ 10MHz = 30,000,000 cycles)
    // ---------------------------------------------------------
    localparam integer DISP_TIMEOUT      = CLK_FREQ_HZ * SHOW_TIME_SEC; // 30_000_000
    localparam integer DISP_TIMER_WIDTH  = $clog2(DISP_TIMEOUT + 1);
    reg [DISP_TIMER_WIDTH-1:0] disp_timer;

    // ---------------------------------------------------------
    // Next-state + combinational outputs
    // NOTE: ppg_in is driven ONLY in the sequential block below.
    // ---------------------------------------------------------
    always @(*) begin
        // defaults
        fifo_in_rd    = 1'b0;
        db_en         = 1'b0;
        bpm_copied    = 1'b0;
        bpm_ready_out = 1'b0;
        next_state    = state;

        case (state)
            IDLE: begin
                if (en && check_rise)
                    next_state = START;
            end

            START: begin
                db_en = 1'b1;
                if (!fifo_in_empty) fifo_in_rd = 1'b1; // prime first sample
                next_state = FEED;
            end

            FEED: begin
                db_en = 1'b1;
                if (!fifo_in_empty) begin
                    fifo_in_rd = 1'b1; // pull next sample (ppg_in registered below)
                end
                if (bpm_valid)
                    next_state = CAPTURE;
            end

            CAPTURE: begin
                db_en         = 1'b1;       // allow clean handoff
                bpm_copied    = 1'b1;       // ack DB
                bpm_ready_out = 1'b1;       // 1-cycle strobe for UI
                next_state    = STOP;
            end

            STOP: begin
                // Remain here while showing BPM; restart on new check
                if (check_rise)
                    next_state = START;      // restart immediately
                else if (disp_timer == 0)
                    next_state = IDLE;       // auto-return after 3s
            end

            default: next_state = IDLE;
        endcase
    end

    // ---------------------------------------------------------
    // Sequential: register ppg_in on FIFO read
    // ---------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ppg_in <= {PPG_WIDTH{1'b0}};
        end else if (fifo_in_rd) begin
            ppg_in <= fifo_in_dout;
        end
    end

    // ---------------------------------------------------------
    // BPM latch + 3-second display timer w/ restart on new check
    // ---------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bpm_latest <= 8'd0;
            disp_timer <= {DISP_TIMER_WIDTH{1'b0}};
        end else begin
            if (state == CAPTURE) begin
                // Latch new BPM and start 3s timer
                bpm_latest <= bpm_value;
                disp_timer <= DISP_TIMEOUT[DISP_TIMER_WIDTH-1:0];
            end else if (check_rise) begin
                // If user presses check during display window, clear immediately
                bpm_latest <= 8'd0;
                disp_timer <= {DISP_TIMER_WIDTH{1'b0}};
            end else if (state == STOP && disp_timer != 0) begin
                disp_timer <= disp_timer - 1'b1;
                if (disp_timer == 1) begin
                    // about to hit zero -> clear display on next cycle
                    bpm_latest <= 8'd0;
                end
            end
        end
    end

endmodule
