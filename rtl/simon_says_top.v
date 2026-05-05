module simon_says_top #(
    parameter integer DEBOUNCE_COUNT_MAX = 1000000,
    parameter integer MAX_ROUNDS = 10,
    parameter integer SLOW_ON_COUNT = 25000000,
    parameter integer SLOW_OFF_COUNT = 12000000,
    parameter integer FAST_ON_COUNT = 12000000,
    parameter integer FAST_OFF_COUNT = 6000000,
    parameter integer FEEDBACK_COUNT = 6000000,
    parameter [7:0] LFSR_SEED = 8'hA5
)(
    input wire clk,
    input wire cpu_resetn,
    input wire [4:0] btn,
    input wire sw0,
    output wire [3:0] led,
    output wire hsync,
    output wire vsync,
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,
    output wire [6:0] seg,
    output wire dp,
    output wire [7:0] an,
    // RGB LEDs LD16 / LD17 — used as a "VGA replacement" so the game's
    // active color is visible on-board even without a monitor.
    output wire led16_r,
    output wire led16_g,
    output wire led16_b,
    output wire led17_r,
    output wire led17_g,
    output wire led17_b
);
    wire rst;
    wire start_level;
    wire start_pulse;
    wire [3:0] color_level;
    wire player_valid;
    wire [1:0] player_value;

    wire pixel_tick;
    wire frame_tick;
    wire active_video;
    wire [9:0] x;
    wire [9:0] y;

    wire [2:0] display_mode;
    wire [1:0] active_color;
    wire light_on;
    wire [3:0] round;
    wire [3:0] high_score;
    wire [3:0] led_drive;

    // Power-on reset: hold rst high for ~655 us after configuration,
    // then release. Combined with cpu_resetn (active-low) so user can
    // still manually reset by pressing the CPU_RESET button.
    reg [15:0] por_count = 16'd0;
    reg        por_done  = 1'b0;
    reg        rstn_sync_0 = 1'b1;
    reg        rstn_sync_1 = 1'b1;

    always @(posedge clk) begin
        if (!por_done) begin
            por_count <= por_count + 1'b1;
            if (&por_count) begin
                por_done <= 1'b1;
            end
        end
        rstn_sync_0 <= cpu_resetn;
        rstn_sync_1 <= rstn_sync_0;
    end

    assign rst = (~por_done) | (~rstn_sync_1);

    // Button → screen-quadrant mapping (matches VGA layout):
    //   color 0 = top-left   (Red)    ← BTNU = btn[1]
    //   color 1 = top-right  (Blue)   ← BTNR = btn[3]
    //   color 2 = bottom-left (Green) ← BTNL = btn[2]
    //   color 3 = bottom-right(Yellow)← BTND = btn[4]
    button_input #(.COUNT_MAX(DEBOUNCE_COUNT_MAX)) buttons (
        .clk(clk),
        .rst(rst),
        .btn_start_raw(btn[0]),
        .btn_color_raw({btn[4], btn[2], btn[3], btn[1]}),
        .start_level(start_level),
        .start_pulse(start_pulse),
        .color_level(color_level),
        .player_valid(player_valid),
        .player_value(player_value)
    );

    simon_game_sm #(
        .MAX_ROUNDS(MAX_ROUNDS),
        .SLOW_ON_COUNT(SLOW_ON_COUNT),
        .SLOW_OFF_COUNT(SLOW_OFF_COUNT),
        .FAST_ON_COUNT(FAST_ON_COUNT),
        .FAST_OFF_COUNT(FAST_OFF_COUNT),
        .FEEDBACK_COUNT(FEEDBACK_COUNT),
        .LFSR_SEED(LFSR_SEED)
    ) sm (
        .clk(clk),
        .rst(rst),
        .start_pulse(start_pulse),
        .player_valid(player_valid),
        .player_value(player_value),
        .difficulty_fast(sw0),
        .display_mode(display_mode),
        .active_color(active_color),
        .light_on(light_on),
        .round(round),
        .high_score(high_score),
        .led_drive(led_drive)
    );

    vga_timing_640x480 timing (
        .clk(clk),
        .rst(rst),
        .pixel_tick(pixel_tick),
        .frame_tick(frame_tick),
        .hsync(hsync),
        .vsync(vsync),
        .active_video(active_video),
        .x(x),
        .y(y)
    );

    simon_vga_renderer renderer (
        .active_video(active_video),
        .x(x),
        .y(y),
        .display_mode(display_mode),
        .active_color(active_color),
        .light_on(light_on),
        .round(round),
        .high_score(high_score),
        .vga_red(vgaRed),
        .vga_green(vgaGreen),
        .vga_blue(vgaBlue)
    );

    simon_ssd_display ssd (
        .clk(clk),
        .rst(rst),
        .round(round),
        .high_score(high_score),
        .seg(seg),
        .dp(dp),
        .an(an)
    );

    assign led = led_drive;

    // ----------------------------------------------------------------
    // RGB LED drivers (LD16 = active color, LD17 = game state)
    // Color encoding: 3'b{R,G,B}
    //   Red    = 100   Blue  = 001
    //   Green  = 010   Yellow= 110 (R+G)
    // ----------------------------------------------------------------
    localparam MODE_IDLE  = 3'd0;
    localparam MODE_SHOW  = 3'd1;
    localparam MODE_INPUT = 3'd2;
    localparam MODE_LOSE  = 3'd3;
    localparam MODE_WIN   = 3'd4;

    reg [2:0] ld16_rgb;
    reg [2:0] ld17_rgb;

    // LD16: bright color flash whenever a pad is "lit" (SHOW or INPUT feedback)
    always @* begin
        if (light_on) begin
            case (active_color)
                2'd0: ld16_rgb = 3'b100;  // red
                2'd1: ld16_rgb = 3'b001;  // blue
                2'd2: ld16_rgb = 3'b010;  // green
                2'd3: ld16_rgb = 3'b110;  // yellow
                default: ld16_rgb = 3'b000;
            endcase
        end else begin
            ld16_rgb = 3'b000;
        end
    end

    // LD17: state indicator that mirrors the on-screen banner color
    always @* begin
        case (display_mode)
            MODE_IDLE:  ld17_rgb = 3'b111;  // white  (ready to start)
            MODE_SHOW:  ld17_rgb = 3'b001;  // blue   (watch the sequence)
            MODE_INPUT: ld17_rgb = 3'b110;  // yellow (your turn)
            MODE_LOSE:  ld17_rgb = 3'b100;  // red    (game over)
            MODE_WIN:   ld17_rgb = 3'b010;  // green  (you win!)
            default:    ld17_rgb = 3'b000;
        endcase
    end

    assign {led16_r, led16_g, led16_b} = ld16_rgb;
    assign {led17_r, led17_g, led17_b} = ld17_rgb;
endmodule
