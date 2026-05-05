module ssd_mux(
    input wire clk,
    input wire rst,
    input wire [31:0] digits,
    output reg [6:0] seg,
    output reg dp,
    output reg [7:0] an
);
    reg [19:0] refresh_count;
    reg [2:0] digit_sel;
    reg [3:0] digit_value;

    always @(posedge clk) begin
        if (rst) begin
            refresh_count <= 20'd0;
        end else begin
            refresh_count <= refresh_count + 1'b1;
        end
    end

    always @* begin
        digit_sel = refresh_count[19:17];

        case (digit_sel)
            3'd0: begin an = 8'b11111110; digit_value = digits[3:0]; end
            3'd1: begin an = 8'b11111101; digit_value = digits[7:4]; end
            3'd2: begin an = 8'b11111011; digit_value = digits[11:8]; end
            3'd3: begin an = 8'b11110111; digit_value = digits[15:12]; end
            3'd4: begin an = 8'b11101111; digit_value = digits[19:16]; end
            3'd5: begin an = 8'b11011111; digit_value = digits[23:20]; end
            3'd6: begin an = 8'b10111111; digit_value = digits[27:24]; end
            default: begin an = 8'b01111111; digit_value = digits[31:28]; end
        endcase
    end

    always @* begin
        dp = 1'b1;

        case (digit_value)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            default: seg = 7'b1111111;
        endcase
    end
endmodule
