module vga_timing_640x480(
    input wire clk,
    input wire rst,
    output wire pixel_tick,
    output wire frame_tick,
    output wire hsync,
    output wire vsync,
    output wire active_video,
    output wire [9:0] x,
    output wire [9:0] y
);
    localparam H_VISIBLE = 10'd640;
    localparam H_FRONT   = 10'd16;
    localparam H_SYNC    = 10'd96;
    localparam H_BACK    = 10'd48;
    localparam H_TOTAL   = H_VISIBLE + H_FRONT + H_SYNC + H_BACK;

    localparam V_VISIBLE = 10'd480;
    localparam V_FRONT   = 10'd10;
    localparam V_SYNC    = 10'd2;
    localparam V_BACK    = 10'd33;
    localparam V_TOTAL   = V_VISIBLE + V_FRONT + V_SYNC + V_BACK;

    reg [1:0] pixel_div;
    reg [9:0] h_count;
    reg [9:0] v_count;

    always @(posedge clk) begin
        if (rst) begin
            pixel_div <= 2'd0;
        end else begin
            pixel_div <= pixel_div + 1'b1;
        end
    end

    assign pixel_tick = (pixel_div == 2'd3);

    always @(posedge clk) begin
        if (rst) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end else if (pixel_tick) begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;
                if (v_count == V_TOTAL - 1) begin
                    v_count <= 10'd0;
                end else begin
                    v_count <= v_count + 1'b1;
                end
            end else begin
                h_count <= h_count + 1'b1;
            end
        end
    end

    assign x = h_count;
    assign y = v_count;

    assign active_video = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);
    assign hsync = ~((h_count >= H_VISIBLE + H_FRONT) &&
                     (h_count < H_VISIBLE + H_FRONT + H_SYNC));
    assign vsync = ~((v_count >= V_VISIBLE + V_FRONT) &&
                     (v_count < V_VISIBLE + V_FRONT + V_SYNC));
    assign frame_tick = pixel_tick &&
                        (h_count == H_TOTAL - 1) &&
                        (v_count == V_TOTAL - 1);
endmodule
