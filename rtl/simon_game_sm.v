module simon_game_sm #(
    parameter integer MAX_ROUNDS = 10,
    parameter integer SLOW_ON_COUNT = 25000000,
    parameter integer SLOW_OFF_COUNT = 12000000,
    parameter integer FAST_ON_COUNT = 12000000,
    parameter integer FAST_OFF_COUNT = 6000000,
    parameter integer FEEDBACK_COUNT = 6000000,
    parameter [7:0] LFSR_SEED = 8'hA5
)(
    input wire clk,
    input wire rst,
    input wire start_pulse,
    input wire player_valid,
    input wire [1:0] player_value,
    input wire difficulty_fast,
    output reg [2:0] display_mode,
    output reg [1:0] active_color,
    output reg light_on,
    output reg [3:0] round,
    output reg [3:0] high_score,
    output reg [3:0] led_drive
);
    localparam ST_IDLE     = 3'd0;
    localparam ST_SHOW_ON  = 3'd1;
    localparam ST_SHOW_OFF = 3'd2;
    localparam ST_WAIT     = 3'd3;
    localparam ST_LOSE     = 3'd4;
    localparam ST_WIN      = 3'd5;

    localparam MODE_IDLE  = 3'd0;
    localparam MODE_SHOW  = 3'd1;
    localparam MODE_INPUT = 3'd2;
    localparam MODE_LOSE  = 3'd3;
    localparam MODE_WIN   = 3'd4;

    reg [2:0] state;
    reg [3:0] round_reg;
    reg [3:0] high_score_reg;
    reg [3:0] show_index;
    reg [3:0] input_index;
    reg [31:0] timer;
    reg [7:0] lfsr;
    reg [1:0] seq_mem [0:MAX_ROUNDS-1];
    reg feedback_on;
    reg [31:0] feedback_timer;
    reg [1:0] feedback_color;
    wire [31:0] show_on_count;
    wire [31:0] show_off_count;
    integer i;

    function [7:0] next_lfsr;
        input [7:0] value;
        begin
            next_lfsr = {value[6:0], value[7] ^ value[5] ^ value[4] ^ value[3]};
        end
    endfunction

    function [1:0] next_symbol;
        input [7:0] value;
        begin
            next_symbol = next_lfsr(value);
        end
    endfunction

    assign show_on_count = difficulty_fast ? FAST_ON_COUNT : SLOW_ON_COUNT;
    assign show_off_count = difficulty_fast ? FAST_OFF_COUNT : SLOW_OFF_COUNT;

    always @(posedge clk) begin
        if (rst) begin
            state <= ST_IDLE;
            round_reg <= 4'd0;
            high_score_reg <= 4'd0;
            show_index <= 4'd0;
            input_index <= 4'd0;
            timer <= 32'd0;
            lfsr <= LFSR_SEED;
            feedback_on <= 1'b0;
            feedback_timer <= 32'd0;
            feedback_color <= 2'd0;

            for (i = 0; i < MAX_ROUNDS; i = i + 1) begin
                seq_mem[i] <= 2'd0;
            end
        end else begin
            if (feedback_on) begin
                if (feedback_timer == 32'd0) begin
                    feedback_on <= 1'b0;
                end else begin
                    feedback_timer <= feedback_timer - 1'b1;
                end
            end

// state logis are below : state machine detail
            if (start_pulse) begin
                lfsr <= next_lfsr(lfsr);
                seq_mem[0] <= next_symbol(lfsr);
                round_reg <= 4'd1;
                show_index <= 4'd0;
                input_index <= 4'd0;
                timer <= 32'd0;
                feedback_on <= 1'b0;
                feedback_timer <= 32'd0;
                feedback_color <= 2'd0;
                state <= ST_SHOW_ON;
            end else begin
                case (state)
                    ST_IDLE: begin
                        timer <= 32'd0;
                    end

                    ST_SHOW_ON: begin
                        if (timer >= show_on_count - 1) begin
                            timer <= 32'd0;
                            state <= ST_SHOW_OFF;
                        end else begin
                            timer <= timer + 1'b1;
                        end
                    end

                    ST_SHOW_OFF: begin
                        if (timer >= show_off_count - 1) begin
                            timer <= 32'd0;
                            if (show_index + 1'b1 < round_reg) begin
                                show_index <= show_index + 1'b1;
                                state <= ST_SHOW_ON;
                            end else begin
                                show_index <= 4'd0;
                                input_index <= 4'd0;
                                state <= ST_WAIT;
                            end
                        end else begin
                            timer <= timer + 1'b1;
                        end
                    end

                    ST_WAIT: begin
                        if (player_valid) begin
                            feedback_on <= 1'b1;
                            feedback_timer <= FEEDBACK_COUNT - 1;
                            feedback_color <= player_value;

                            if (player_value == seq_mem[input_index]) begin
                                if (input_index + 1'b1 >= round_reg) begin
                                    if (round_reg == MAX_ROUNDS) begin
                                        if (high_score_reg < MAX_ROUNDS) begin
                                            high_score_reg <= MAX_ROUNDS;
                                        end
                                        state <= ST_WIN;
                                    end else begin
                                        if (high_score_reg < round_reg) begin
                                            high_score_reg <= round_reg;
                                        end
                                        lfsr <= next_lfsr(lfsr);
                                        seq_mem[round_reg] <= next_symbol(lfsr);
                                        round_reg <= round_reg + 1'b1;
                                        show_index <= 4'd0;
                                        input_index <= 4'd0;
                                        timer <= 32'd0;
                                        state <= ST_SHOW_ON;
                                    end
                                end else begin
                                    input_index <= input_index + 1'b1;
                                end
                            end else begin
                                state <= ST_LOSE;
                            end
                        end
                    end

                    ST_LOSE: begin
                        timer <= 32'd0;
                    end

                    ST_WIN: begin
                        timer <= 32'd0;
                    end

                    default: begin
                        state <= ST_IDLE;
                    end
                endcase
            end
        end
    end

    always @* begin
        display_mode = MODE_IDLE;
        active_color = 2'd0;
        light_on = 1'b0;
        round = round_reg;
        high_score = high_score_reg;
        led_drive = 4'b0000;

        case (state)
            ST_IDLE: begin
                display_mode = MODE_IDLE;
            end

            ST_SHOW_ON: begin
                display_mode = MODE_SHOW;
                active_color = seq_mem[show_index];
                light_on = 1'b1;
                led_drive = 4'b0001 << seq_mem[show_index];
            end

            ST_SHOW_OFF: begin
                display_mode = MODE_SHOW;
            end

            ST_WAIT: begin
                display_mode = MODE_INPUT;
                if (feedback_on) begin
                    active_color = feedback_color;
                    light_on = 1'b1;
                    led_drive = 4'b0001 << feedback_color;
                end
            end

            ST_LOSE: begin
                display_mode = MODE_LOSE;
                led_drive = 4'b0001;
            end

            ST_WIN: begin
                display_mode = MODE_WIN;
                led_drive = 4'b1111;
            end
        endcase
    end
endmodule
