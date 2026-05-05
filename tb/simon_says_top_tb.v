`timescale 1ns / 1ps

module simon_says_top_tb;
    localparam MODE_IDLE  = 3'd0;
    localparam MODE_SHOW  = 3'd1;
    localparam MODE_INPUT = 3'd2;
    localparam MODE_LOSE  = 3'd3;
    localparam MODE_WIN   = 3'd4;

    reg clk;
    reg cpu_resetn;
    reg [4:0] btn;
    reg sw0;

    wire [3:0] led;
    wire hsync;
    wire vsync;
    wire [3:0] vgaRed;
    wire [3:0] vgaGreen;
    wire [3:0] vgaBlue;
    wire [6:0] seg;
    wire dp;
    wire [7:0] an;

    reg unit_btn_start_raw;
    reg [3:0] unit_btn_color_raw;
    reg unit_btn_rst;
    wire unit_start_level;
    wire unit_start_pulse;
    wire [3:0] unit_color_level;
    wire unit_player_valid;
    wire [1:0] unit_player_value;

    reg timing_rst;
    wire unit_pixel_tick;
    wire unit_frame_tick;
    wire unit_hsync;
    wire unit_vsync;
    wire unit_active_video;
    wire [9:0] unit_x;
    wire [9:0] unit_y;

    reg renderer_active_video;
    reg [9:0] renderer_x;
    reg [9:0] renderer_y;
    reg [2:0] renderer_mode;
    reg [1:0] renderer_active_color;
    reg renderer_light_on;
    reg [3:0] renderer_round;
    reg [3:0] renderer_high_score;
    wire [3:0] renderer_red;
    wire [3:0] renderer_green;
    wire [3:0] renderer_blue;

    reg ssd_rst;
    reg [3:0] ssd_round;
    reg [3:0] ssd_high_score;
    wire [6:0] ssd_seg;
    wire ssd_dp;
    wire [7:0] ssd_an;

    integer errors;
    integer pulse_count;
    integer cycles;
    integer timeout_count;
    reg [1:0] pulse_value;
    reg top_pulse_seen;
    integer slow_cycles;
    integer fast_cycles;
    reg [1:0] wrong_value;

    simon_says_top #(
        .DEBOUNCE_COUNT_MAX(3),
        .MAX_ROUNDS(3),
        .SLOW_ON_COUNT(4),
        .SLOW_OFF_COUNT(2),
        .FAST_ON_COUNT(2),
        .FAST_OFF_COUNT(1),
        .FEEDBACK_COUNT(2),
        .LFSR_SEED(8'hA5)
    ) dut (
        .clk(clk),
        .cpu_resetn(cpu_resetn),
        .btn(btn),
        .sw0(sw0),
        .led(led),
        .hsync(hsync),
        .vsync(vsync),
        .vgaRed(vgaRed),
        .vgaGreen(vgaGreen),
        .vgaBlue(vgaBlue),
        .seg(seg),
        .dp(dp),
        .an(an)
    );

    button_input #(.COUNT_MAX(3)) unit_buttons (
        .clk(clk),
        .rst(unit_btn_rst),
        .btn_start_raw(unit_btn_start_raw),
        .btn_color_raw(unit_btn_color_raw),
        .start_level(unit_start_level),
        .start_pulse(unit_start_pulse),
        .color_level(unit_color_level),
        .player_valid(unit_player_valid),
        .player_value(unit_player_value)
    );

    vga_timing_640x480 unit_timing (
        .clk(clk),
        .rst(timing_rst),
        .pixel_tick(unit_pixel_tick),
        .frame_tick(unit_frame_tick),
        .hsync(unit_hsync),
        .vsync(unit_vsync),
        .active_video(unit_active_video),
        .x(unit_x),
        .y(unit_y)
    );

    simon_vga_renderer unit_renderer (
        .active_video(renderer_active_video),
        .x(renderer_x),
        .y(renderer_y),
        .display_mode(renderer_mode),
        .active_color(renderer_active_color),
        .light_on(renderer_light_on),
        .round(renderer_round),
        .high_score(renderer_high_score),
        .vga_red(renderer_red),
        .vga_green(renderer_green),
        .vga_blue(renderer_blue)
    );

    simon_ssd_display unit_ssd (
        .clk(clk),
        .rst(ssd_rst),
        .round(ssd_round),
        .high_score(ssd_high_score),
        .seg(ssd_seg),
        .dp(ssd_dp),
        .an(ssd_an)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (unit_player_valid) begin
            pulse_count <= pulse_count + 1;
            pulse_value <= unit_player_value;
        end

        if (dut.player_valid) begin
            top_pulse_seen <= 1'b1;
        end
    end

    task expect_true;
        input cond;
        input [8*96-1:0] msg;
        begin
            if (!cond) begin
                $display("FAIL: %0s", msg);
                errors = errors + 1;
            end
        end
    endtask

    task reset_top_inputs;
        begin
            btn = 5'b0;
            sw0 = 1'b0;
            cpu_resetn = 1'b0;
            repeat (4) @(negedge clk);
            cpu_resetn = 1'b1;
            repeat (4) @(negedge clk);
        end
    endtask

    task press_top_button;
        input integer idx;
        begin
            btn[idx] = 1'b1;
            repeat (6) @(negedge clk);
            btn[idx] = 1'b0;
            repeat (4) @(negedge clk);
        end
    endtask

    task press_top_color;
        input [1:0] value;
        begin
            press_top_button(value + 1);
        end
    endtask

    task wait_top_mode;
        input [2:0] mode;
        input integer limit;
        begin
            timeout_count = 0;
            while (dut.display_mode !== mode && timeout_count < limit) begin
                @(posedge clk);
                timeout_count = timeout_count + 1;
            end
            expect_true(dut.display_mode === mode, "top mode wait timed out");
        end
    endtask

    task wait_led_active;
        input integer limit;
        begin
            timeout_count = 0;
            while (led == 4'b0000 && timeout_count < limit) begin
                @(posedge clk);
                timeout_count = timeout_count + 1;
            end
            expect_true(led != 4'b0000, "LED never became active");
        end
    endtask

    task measure_led_on_cycles;
        output integer count_out;
        begin
            count_out = 0;
            while (led != 4'b0000) begin
                @(posedge clk);
                count_out = count_out + 1;
            end
        end
    endtask

    task wait_timing_xy;
        input [9:0] want_x;
        input [9:0] want_y;
        input integer limit;
        begin
            timeout_count = 0;
            while (!((unit_x == want_x) && (unit_y == want_y)) && timeout_count < limit) begin
                @(posedge clk);
                timeout_count = timeout_count + 1;
            end
            expect_true((unit_x == want_x) && (unit_y == want_y), "timing coordinate wait timed out");
        end
    endtask

    initial begin
        clk = 1'b0;
        cpu_resetn = 1'b0;
        btn = 5'b0;
        sw0 = 1'b0;
        unit_btn_start_raw = 1'b0;
        unit_btn_color_raw = 4'b0;
        unit_btn_rst = 1'b1;
        timing_rst = 1'b1;
        renderer_active_video = 1'b0;
        renderer_x = 10'd0;
        renderer_y = 10'd0;
        renderer_mode = MODE_IDLE;
        renderer_active_color = 2'd0;
        renderer_light_on = 1'b0;
        renderer_round = 4'd0;
        renderer_high_score = 4'd0;
        ssd_rst = 1'b0;
        ssd_round = 4'd0;
        ssd_high_score = 4'd0;
        errors = 0;
        pulse_count = 0;
        pulse_value = 2'd0;
        top_pulse_seen = 1'b0;

        repeat (3) @(negedge clk);
        unit_btn_rst = 1'b0;
        timing_rst = 1'b0;

        unit_btn_color_raw[2] = 1'b1;
        @(negedge clk);
        unit_btn_color_raw[2] = 1'b0;
        @(negedge clk);
        unit_btn_color_raw[2] = 1'b1;
        @(negedge clk);
        unit_btn_color_raw[2] = 1'b0;
        repeat (4) @(negedge clk);
        expect_true(pulse_count == 0, "button debounce accepted bounce");

        unit_btn_color_raw[2] = 1'b1;
        repeat (5) @(negedge clk);
        unit_btn_color_raw[2] = 1'b0;
        repeat (4) @(negedge clk);
        expect_true(pulse_count == 1, "button debounce did not create one pulse");
        expect_true(pulse_value == 2'd2, "button debounce returned wrong player value");

        cycles = 0;
        while (cycles < 20 && !unit_pixel_tick) begin
            @(posedge clk);
            cycles = cycles + 1;
        end
        expect_true(unit_pixel_tick == 1'b1, "pixel tick did not appear");

        cycles = 0;
        @(posedge clk);
        while (cycles < 10 && !unit_pixel_tick) begin
            @(posedge clk);
            cycles = cycles + 1;
        end
        expect_true(cycles == 3, "pixel tick period was not four clocks");

        wait_timing_xy(10'd656, 10'd0, 5000);
        expect_true(unit_hsync == 1'b0, "hsync was not low in sync window");
        wait_timing_xy(10'd752, 10'd0, 1000);
        expect_true(unit_hsync == 1'b1, "hsync did not return high after sync window");
        wait_timing_xy(10'd0, 10'd490, 2000000);
        expect_true(unit_vsync == 1'b0, "vsync was not low in vertical sync window");

        timeout_count = 0;
        while (!unit_frame_tick && timeout_count < 2000000) begin
            @(posedge clk);
            timeout_count = timeout_count + 1;
        end
        expect_true(unit_frame_tick == 1'b1, "frame tick never asserted");

        renderer_active_video = 1'b1;
        renderer_x = 10'd100;
        renderer_y = 10'd120;
        renderer_mode = MODE_SHOW;
        renderer_active_color = 2'd0;
        renderer_light_on = 1'b1;
        renderer_round = 4'd3;
        renderer_high_score = 4'd2;
        #1;
        expect_true({renderer_red, renderer_green, renderer_blue} == 12'hF22, "renderer top-left active color failed");

        renderer_x = 10'd500;
        renderer_y = 10'd120;
        renderer_active_color = 2'd0;
        renderer_light_on = 1'b0;
        #1;
        expect_true({renderer_red, renderer_green, renderer_blue} == 12'h005, "renderer top-right dim color failed");

        renderer_x = 10'd68;
        renderer_y = 10'd20;
        renderer_mode = MODE_WIN;
        #1;
        expect_true({renderer_red, renderer_green, renderer_blue} == 12'hFFF, "renderer score digit overlay failed");

        renderer_x = 10'd99;
        renderer_y = 10'd20;
        renderer_round = 4'd0;
        renderer_high_score = 4'd0;
        renderer_mode = MODE_IDLE;
        #1;
        expect_true({renderer_red, renderer_green, renderer_blue} == 12'hDDD, "renderer score divider failed");

        renderer_active_video = 1'b0;
        #1;
        expect_true({renderer_red, renderer_green, renderer_blue} == 12'h000, "renderer blanking failed");

        ssd_round = 4'd3;
        ssd_high_score = 4'd9;
        force unit_ssd.ssd_driver.refresh_count = 20'd0;
        #1;
        expect_true(ssd_an == 8'b11111110, "ssd anode select for high ones failed");
        expect_true(ssd_seg == 7'b0010000, "ssd segment encoding for 9 failed");
        release unit_ssd.ssd_driver.refresh_count;

        force unit_ssd.ssd_driver.refresh_count = 20'h60000;
        #1;
        expect_true(ssd_an == 8'b11110111, "ssd anode select for round ones failed");
        expect_true(ssd_seg == 7'b0110000, "ssd segment encoding for 3 failed");
        release unit_ssd.ssd_driver.refresh_count;

        reset_top_inputs();
        expect_true(dut.display_mode == MODE_IDLE, "top was not idle after reset");
        expect_true(dut.round == 4'd0, "top round was not zero after reset");
        expect_true(dut.high_score == 4'd0, "top high score was not zero after reset");
        expect_true(led == 4'b0000, "top LEDs were not off after reset");

        press_top_button(0);
        wait_led_active(100);
        expect_true(dut.active_color == dut.sm.sequence[0], "first sequence color was wrong");
        measure_led_on_cycles(slow_cycles);
        expect_true(slow_cycles == 4, "slow difficulty show length was wrong");
        expect_true(led == 4'b0000, "LEDs should be off after first show pulse");
        wait_top_mode(MODE_INPUT, 100);
        expect_true(dut.round == 4'd1, "round did not reach 1");

        sw0 = 1'b1;
        top_pulse_seen = 1'b0;
        press_top_color(dut.sm.sequence[0]);
        expect_true(top_pulse_seen == 1'b1, "top button path did not create player pulse");
        wait_led_active(100);
        measure_led_on_cycles(fast_cycles);
        expect_true(fast_cycles == 2, "fast difficulty show length was wrong");
        expect_true(dut.round == 4'd2, "round did not advance to 2");
        expect_true(dut.high_score == 4'd1, "high score did not update after round 1");

        wait_top_mode(MODE_INPUT, 100);
        press_top_color(dut.sm.sequence[0]);
        press_top_color(dut.sm.sequence[1]);
        wait_top_mode(MODE_SHOW, 100);
        expect_true(dut.round == 4'd3, "round did not advance to 3");
        expect_true(dut.high_score == 4'd2, "high score did not update after round 2");

        wait_top_mode(MODE_INPUT, 150);
        press_top_color(dut.sm.sequence[0]);
        press_top_color(dut.sm.sequence[1]);
        press_top_color(dut.sm.sequence[2]);
        wait_top_mode(MODE_WIN, 100);
        expect_true(dut.high_score == 4'd3, "high score did not update on win");
        expect_true(led == 4'b1111, "win LEDs were not all on");

        press_top_button(0);
        wait_led_active(100);
        wait_top_mode(MODE_INPUT, 100);
        expect_true(dut.round == 4'd1, "restart did not return to round 1");
        expect_true(dut.high_score == 4'd3, "restart did not preserve high score");

        wrong_value = dut.sm.sequence[0] + 1'b1;
        press_top_color(wrong_value);
        wait_top_mode(MODE_LOSE, 100);
        expect_true(led == 4'b0001, "lose LEDs were not correct");

        if (errors == 0) begin
            $display("PASS: simon_says_top_tb");
        end else begin
            $display("FAIL: simon_says_top_tb with %0d error(s)", errors);
        end

        $finish;
    end
endmodule
