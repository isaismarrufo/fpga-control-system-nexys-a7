module simon_vga_renderer(
    input wire active_video,
    input wire [9:0] x,
    input wire [9:0] y,
    input wire [2:0] display_mode,
    input wire [1:0] active_color,
    input wire light_on,
    input wire [3:0] round,
    input wire [3:0] high_score,
    output reg [3:0] vga_red,
    output reg [3:0] vga_green,
    output reg [3:0] vga_blue
);
    localparam MODE_IDLE  = 3'd0;
    localparam MODE_SHOW  = 3'd1;
    localparam MODE_INPUT = 3'd2;
    localparam MODE_LOSE  = 3'd3;
    localparam MODE_WIN   = 3'd4;

    wire [3:0] round_tens;
    wire [3:0] round_ones;
    wire [3:0] high_tens;
    wire [3:0] high_ones;

    wire round_tens_on;
    wire round_ones_on;
    wire high_tens_on;
    wire high_ones_on;
    wire digits_on;

    reg [11:0] color_next;
    reg [11:0] quad_color;

    wire top_left;
    wire top_right;
    wire bottom_left;
    wire bottom_right;
    wire divider_on;
    wire banner_on;
    wire score_divider_on;

    assign top_left = (x < 10'd320) && (y < 10'd240);
    assign top_right = (x >= 10'd320) && (y < 10'd240);
    assign bottom_left = (x < 10'd320) && (y >= 10'd240);
    assign bottom_right = (x >= 10'd320) && (y >= 10'd240);
    assign divider_on = (x == 10'd319) || (x == 10'd320) || (y == 10'd239) || (y == 10'd240);
    assign banner_on = (y < 10'd56);
    assign score_divider_on = (x >= 10'd98) && (x < 10'd102) && (y >= 10'd10) && (y < 10'd50);

    assign round_tens = (round >= 4'd10) ? 4'd1 : 4'hF;
    assign round_ones = (round >= 4'd10) ? 4'd0 : round;
    assign high_tens = (high_score >= 4'd10) ? 4'd1 : 4'hF;
    assign high_ones = (high_score >= 4'd10) ? 4'd0 : high_score;

    seven_seg_digit_pixel #(.X0(18),  .Y0(10), .W(24), .H(40), .T(4)) round_tens_digit (
        .x(x),
        .y(y),
        .digit(round_tens),
        .pixel_on(round_tens_on)
    );

    seven_seg_digit_pixel #(.X0(48),  .Y0(10), .W(24), .H(40), .T(4)) round_ones_digit (
        .x(x),
        .y(y),
        .digit(round_ones),
        .pixel_on(round_ones_on)
    );

    seven_seg_digit_pixel #(.X0(120), .Y0(10), .W(24), .H(40), .T(4)) high_tens_digit (
        .x(x),
        .y(y),
        .digit(high_tens),
        .pixel_on(high_tens_on)
    );

    seven_seg_digit_pixel #(.X0(150), .Y0(10), .W(24), .H(40), .T(4)) high_ones_digit (
        .x(x),
        .y(y),
        .digit(high_ones),
        .pixel_on(high_ones_on)
    );

    assign digits_on = round_tens_on || round_ones_on || high_tens_on || high_ones_on;

    always @* begin
        if (top_left) begin
            quad_color = (light_on && (active_color == 2'd0)) ? 12'hF22 : 12'h500;
        end else if (top_right) begin
            quad_color = (light_on && (active_color == 2'd1)) ? 12'h46F : 12'h005;
        end else if (bottom_left) begin
            quad_color = (light_on && (active_color == 2'd2)) ? 12'h3F3 : 12'h050;
        end else begin
            quad_color = (light_on && (active_color == 2'd3)) ? 12'hFF3 : 12'h550;
        end

        color_next = quad_color;

        if (divider_on) begin
            color_next = 12'h111;
        end

        if (banner_on) begin
            case (display_mode)
                MODE_IDLE:  color_next = 12'h333;
                MODE_SHOW:  color_next = 12'h157;
                MODE_INPUT: color_next = 12'h850;
                MODE_LOSE:  color_next = 12'h900;
                MODE_WIN:   color_next = 12'h090;
                default:    color_next = 12'h333;
            endcase
        end

        if (score_divider_on) begin
            color_next = 12'hDDD;
        end

        if (digits_on) begin
            color_next = 12'hFFF;
        end

        if (!active_video) begin
            color_next = 12'h000;
        end
    end

    always @* begin
        vga_red = color_next[11:8];
        vga_green = color_next[7:4];
        vga_blue = color_next[3:0];
    end
endmodule
