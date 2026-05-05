module debounce_onepulse #(
    parameter integer COUNT_MAX = 1000000
)(
    input wire clk,
    input wire rst,
    input wire noisy,
    output reg clean,
    output reg pulse
);
    reg sync0;
    reg sync1;
    reg stable_state;
    reg [31:0] count;

    always @(posedge clk) begin
        if (rst) begin
            sync0 <= 1'b0;
            sync1 <= 1'b0;
            stable_state <= 1'b0;
            clean <= 1'b0;
            pulse <= 1'b0;
            count <= 32'd0;
        end else begin
            sync0 <= noisy;
            sync1 <= sync0;
            pulse <= 1'b0;

            if (sync1 == stable_state) begin
                count <= 32'd0;
            end else if (count == COUNT_MAX - 1) begin
                stable_state <= sync1;
                clean <= sync1;
                pulse <= sync1;
                count <= 32'd0;
            end else begin
                count <= count + 1'b1;
            end
        end
    end
endmodule
