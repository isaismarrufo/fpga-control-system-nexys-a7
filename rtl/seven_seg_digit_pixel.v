module seven_seg_digit_pixel #(
    parameter integer X0 = 0,
    parameter integer Y0 = 0,
    parameter integer W  = 24,
    parameter integer H  = 40,
    parameter integer T  = 4
)(
    input wire [9:0] x,
    input wire [9:0] y,
    input wire [3:0] digit,
    output wire pixel_on
);
    wire in_box;
    wire [9:0] xr;
    wire [9:0] yr;
    reg [6:0] seg_map;

    wire seg_a;
    wire seg_b;
    wire seg_c;
    wire seg_d;
    wire seg_e;
    wire seg_f;
    wire seg_g;

    assign in_box = (x >= X0) && (x < X0 + W) && (y >= Y0) && (y < Y0 + H);
    assign xr = x - X0;
    assign yr = y - Y0;

    always @* begin
        case (digit)
            4'h0: seg_map = 7'b1111110;
            4'h1: seg_map = 7'b0110000;
            4'h2: seg_map = 7'b1101101;
            4'h3: seg_map = 7'b1111001;
            4'h4: seg_map = 7'b0110011;
            4'h5: seg_map = 7'b1011011;
            4'h6: seg_map = 7'b1011111;
            4'h7: seg_map = 7'b1110000;
            4'h8: seg_map = 7'b1111111;
            4'h9: seg_map = 7'b1111011;
            4'hA: seg_map = 7'b1110111;
            4'hB: seg_map = 7'b0011111;
            4'hC: seg_map = 7'b1001110;
            4'hD: seg_map = 7'b0111101;
            4'hE: seg_map = 7'b1001111;
            4'hF: seg_map = 7'b0000000;
            default: seg_map = 7'b0000000;
        endcase
    end

    assign seg_a = in_box && (yr < T) && (xr >= T) && (xr < W - T);
    assign seg_b = in_box && (xr >= W - T) && (yr >= T) && (yr < (H / 2) - (T / 2));
    assign seg_c = in_box && (xr >= W - T) && (yr >= (H / 2) + (T / 2)) && (yr < H - T);
    assign seg_d = in_box && (yr >= H - T) && (xr >= T) && (xr < W - T);
    assign seg_e = in_box && (xr < T) && (yr >= (H / 2) + (T / 2)) && (yr < H - T);
    assign seg_f = in_box && (xr < T) && (yr >= T) && (yr < (H / 2) - (T / 2));
    assign seg_g = in_box && (yr >= (H / 2) - (T / 2)) && (yr < (H / 2) + (T / 2)) &&
                   (xr >= T) && (xr < W - T);

    assign pixel_on = (seg_map[6] && seg_a) ||
                      (seg_map[5] && seg_b) ||
                      (seg_map[4] && seg_c) ||
                      (seg_map[3] && seg_d) ||
                      (seg_map[2] && seg_e) ||
                      (seg_map[1] && seg_f) ||
                      (seg_map[0] && seg_g);
endmodule
