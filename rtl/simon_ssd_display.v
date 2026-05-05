module simon_ssd_display(
    input wire clk,
    input wire rst,
    input wire [3:0] round,
    input wire [3:0] high_score,
    output wire [6:0] seg,
    output wire dp,
    output wire [7:0] an
);
    wire [3:0] round_tens;
    wire [3:0] round_ones;
    wire [3:0] high_tens;
    wire [3:0] high_ones;
    wire [31:0] digits;

    assign round_tens = (round >= 4'd10) ? 4'd1 : 4'hF;
    assign round_ones = (round >= 4'd10) ? 4'd0 : round;
    assign high_tens = (high_score >= 4'd10) ? 4'd1 : 4'hF;
    assign high_ones = (high_score >= 4'd10) ? 4'd0 : high_score;

    assign digits = {
        4'hF, 4'hF, round_tens, round_ones,
        4'hF, 4'hF, high_tens, high_ones
    };

    ssd_mux ssd_driver (
        .clk(clk),
        .rst(rst),
        .digits(digits),
        .seg(seg),
        .dp(dp),
        .an(an)
    );
endmodule
