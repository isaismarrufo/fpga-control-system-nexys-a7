`timescale 1ns / 1ps

module simon_game_sm_tb;
    localparam MODE_SHOW  = 3'd1;
    localparam MODE_INPUT = 3'd2;
    localparam MODE_WIN   = 3'd4;

    reg clk;
    reg rst;
    reg start_pulse;
    reg player_valid;
    reg [1:0] player_value;
    reg difficulty_fast;
    wire [2:0] display_mode;
    wire [1:0] active_color;
    wire light_on;
    wire [3:0] round;
    wire [3:0] high_score;
    wire [3:0] led_drive;

    simon_game_sm #(
        .MAX_ROUNDS(2),
        .SLOW_ON_COUNT(3),
        .SLOW_OFF_COUNT(2),
        .FAST_ON_COUNT(2),
        .FAST_OFF_COUNT(1),
        .FEEDBACK_COUNT(2),
        .LFSR_SEED(8'hA5)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start_pulse(start_pulse),
        .player_valid(player_valid),
        .player_value(player_value),
        .difficulty_fast(difficulty_fast),
        .display_mode(display_mode),
        .active_color(active_color),
        .light_on(light_on),
        .round(round),
        .high_score(high_score),
        .led_drive(led_drive)
    );

    always #5 clk = ~clk;

    task pulse_start;
        begin
            @(negedge clk);
            start_pulse = 1'b1;
            @(negedge clk);
            start_pulse = 1'b0;
        end
    endtask

    task pulse_player;
        input [1:0] value;
        begin
            @(negedge clk);
            player_value = value;
            player_valid = 1'b1;
            @(negedge clk);
            player_valid = 1'b0;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        start_pulse = 1'b0;
        player_valid = 1'b0;
        player_value = 2'd0;
        difficulty_fast = 1'b0;

        repeat (3) @(negedge clk);
        rst = 1'b0;

        pulse_start();

        wait (display_mode == MODE_SHOW && light_on == 1'b1);
        if (active_color !== dut.sequence[0]) begin
            $display("FAIL: expected first color %0d, got %0d", dut.sequence[0], active_color);
            $finish;
        end

        wait (display_mode == MODE_INPUT);
        if (round !== 4'd1) begin
            $display("FAIL: expected round 1 at first input, got %0d", round);
            $finish;
        end

        pulse_player(dut.sequence[0]);

        wait (display_mode == MODE_SHOW && round == 4'd2);
        if (high_score !== 4'd1) begin
            $display("FAIL: expected high_score 1 after round 1, got %0d", high_score);
            $finish;
        end

        wait (display_mode == MODE_INPUT && round == 4'd2);
        pulse_player(dut.sequence[0]);
        pulse_player(dut.sequence[1]);

        wait (display_mode == MODE_WIN);
        if (high_score !== 4'd2) begin
            $display("FAIL: expected high_score 2 on win, got %0d", high_score);
            $finish;
        end

        if (led_drive !== 4'b1111) begin
            $display("FAIL: expected all LEDs on during win, got %b", led_drive);
            $finish;
        end

        $display("PASS");
        $finish;
    end
endmodule
