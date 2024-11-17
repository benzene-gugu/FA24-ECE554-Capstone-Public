// NOTE: only implements SPI mode 0
module peripheral_SPI_master(
        input clk,
        input rst_n,

        input [7:0] clk_per_half_cycle,

        input data_available,
        output reg busy,

        input [7:0] write_data,
        output reg next_write_data,

        output reg [7:0] read_data,
        output reg read_ready,

        output reg MOSI, SCLK, SS_n,
        input MISO
    );

    logic [7:0] shift_register;
    logic load_shift_register, shift_out, shift_in, SCLK_raw;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            shift_register <= 8'h00;
        else if (load_shift_register)
            shift_register <= write_data;
        else if (shift_in)
            shift_register <= {shift_register[6:0], MISO};
    end

    logic load_read_data;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            read_data <= 8'h00;
        else if (load_read_data)
            read_data <= {shift_register[6:0], MISO};
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            read_ready <= 1'b0;
        else if (load_read_data)
            read_ready <= 1'b1;
        else if (read_ready)
            read_ready <= 1'b0;
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            MOSI <= 1'b0;
        else if (load_shift_register && shift_out)
            MOSI <= write_data[7];
        else if (shift_out)
            MOSI <= shift_register[7];
    end

    logic [2:0] shift_in_counter;
    logic shifted_7_in;

    assign shifted_7_in = shift_in_counter == 3'h7;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            shift_in_counter <= 3'h0;
        else if (shift_in)
            shift_in_counter <= shift_in_counter + 3'h1;
    end

    logic [7:0] sclk_counter;
    logic reset_sclk_counter, half_cycle_event;

    assign half_cycle_event = sclk_counter == (clk_per_half_cycle - 8'h01);

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            sclk_counter <= 8'h00;
        else if (half_cycle_event || reset_sclk_counter)
            sclk_counter <= 8'h00;
        else begin
            sclk_counter <= sclk_counter + 8'h1;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            SCLK <= 1'b0;
        else
            SCLK <= SCLK_raw;
    end

    typedef enum logic [1:0] { IDLE, RISE, FALL, FINAL_FALL } state_t;
    state_t state, next_state;

    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;

    always_comb begin
        SS_n = 1'b0;
        SCLK_raw = 1'b0;
        shift_out = 1'b0;
        shift_in = 1'b0;
        load_shift_register = 1'b0;
        next_write_data = 1'b0;
        load_read_data = 1'b0;
        reset_sclk_counter = 1'b0;
        busy = 1'b1;

        next_state = state;

        case (state)
            IDLE: begin
                busy = 1'b0;
                SS_n = 1'b1;

                if (data_available) begin
                    reset_sclk_counter = 1'b1;
                    load_shift_register = 1'b1;
                    shift_out = 1'b1;
                    next_write_data = 1'b1;

                    next_state = RISE;
                end
            end
            RISE: begin
                SCLK_raw = 1'b0;

                if (half_cycle_event) begin
                    shift_in = 1'b1;

                    next_state = FALL;

                    if (shifted_7_in) begin
                        load_read_data = 1'b1;
                    end

                    if (shifted_7_in && data_available) begin
                        load_shift_register = 1'b1;
                        next_write_data = 1'b1;
                    end

                    if (shifted_7_in && !data_available) begin
                        next_state = FINAL_FALL;
                    end
                end
            end
            FALL: begin
                SCLK_raw = 1'b1;

                if (half_cycle_event) begin
                    shift_out = 1'b1;

                    next_state = RISE;
                end
            end
            FINAL_FALL: begin
                SCLK_raw = 1'b1;

                if (half_cycle_event) begin
                    shift_out = 1'b1;

                    next_state = IDLE;
                end
            end
            default: next_state = IDLE;
        endcase
    end

endmodule
