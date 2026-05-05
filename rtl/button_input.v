module button_input #(
    parameter integer COUNT_MAX = 1000000
)(
    input wire clk,
    input wire rst,
    input wire btn_start_raw,
    input wire [3:0] btn_color_raw,
    output wire start_level,
    output wire start_pulse,
    output wire [3:0] color_level,
    output wire player_valid,
    output wire [1:0] player_value
);
    wire [3:0] color_pulse;

    debounce_onepulse #(.COUNT_MAX(COUNT_MAX)) start_db (
        .clk(clk),
        .rst(rst),
        .noisy(btn_start_raw),
        .clean(start_level),
        .pulse(start_pulse)
    );

    debounce_onepulse #(.COUNT_MAX(COUNT_MAX)) color0_db (
        .clk(clk),
        .rst(rst),
        .noisy(btn_color_raw[0]),
        .clean(color_level[0]),
        .pulse(color_pulse[0])
    );

    debounce_onepulse #(.COUNT_MAX(COUNT_MAX)) color1_db (
        .clk(clk),
        .rst(rst),
        .noisy(btn_color_raw[1]),
        .clean(color_level[1]),
        .pulse(color_pulse[1])
    );

    debounce_onepulse #(.COUNT_MAX(COUNT_MAX)) color2_db (
        .clk(clk),
        .rst(rst),
        .noisy(btn_color_raw[2]),
        .clean(color_level[2]),
        .pulse(color_pulse[2])
    );

    debounce_onepulse #(.COUNT_MAX(COUNT_MAX)) color3_db (
        .clk(clk),
        .rst(rst),
        .noisy(btn_color_raw[3]),
        .clean(color_level[3]),
        .pulse(color_pulse[3])
    );

    assign player_valid = |color_pulse;
    assign player_value = color_pulse[0] ? 2'd0 :
                          color_pulse[1] ? 2'd1 :
                          color_pulse[2] ? 2'd2 :
                          color_pulse[3] ? 2'd3 : 2'd0;
endmodule
