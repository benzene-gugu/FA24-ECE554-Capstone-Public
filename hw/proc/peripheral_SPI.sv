import m_rv32::*;

module peripheral_SPI
    #(
        parameter BUFFER_SIZE = 4096
    )
    (
        input clk, rst_n,

        input re, we,
        input [3:0] addr,
        input [31:0] wdata,
        output reg [31:0] rdata,

        output SS_n, SCLK, MOSI,
        input MISO
    );

    localparam ADDR_CONTROL = 4'h0;
    localparam ADDR_STATUS  = 4'h4;
    localparam ADDR_TX      = 4'h8;
    localparam ADDR_RX      = 4'hc;

    logic rx_queue_read, rx_queue_write, rx_queue_empty, rx_queue_full;
    logic [7:0] rx_queue_data_in, rx_queue_data_out;
    logic [$clog2(BUFFER_SIZE):0] rx_queue_num_entries;

    logic tx_queue_read, tx_queue_write, tx_queue_empty, tx_queue_full;
    logic [7:0] tx_queue_data_in, tx_queue_data_out;
    logic [$clog2(BUFFER_SIZE):0] tx_queue_num_entries;

    fifo_queue #(.WIDTH(8), .SIZE(BUFFER_SIZE)) rx_queue(
        .clk, .rst_n,
        .read(rx_queue_read), .write(rx_queue_write),
        .full(rx_queue_full), .empty(rx_queue_empty),
        .data_in(rx_queue_data_in), .data_out(rx_queue_data_out),
        .num_entries(rx_queue_num_entries)
    );
    fifo_queue #(.WIDTH(8), .SIZE(BUFFER_SIZE)) tx_queue(
        .clk, .rst_n,
        .read(tx_queue_read), .write(tx_queue_write),
        .full(tx_queue_full), .empty(tx_queue_empty),
        .data_in(tx_queue_data_in), .data_out(tx_queue_data_out),
        .num_entries(tx_queue_num_entries)
    );

    logic busy, data_available, transmit;
    logic [7:0] clk_per_half_cycle;

    assign data_available = !tx_queue_empty && transmit;

    peripheral_SPI_master SPI_master(
        .clk, .rst_n,
        .SS_n(/* ignored */), .SCLK, .MOSI, .MISO,
        .clk_per_half_cycle,
        .data_available, .busy,
        .write_data(tx_queue_data_out), .next_write_data(tx_queue_read),
        .read_data(rx_queue_data_in), .read_ready(rx_queue_write)
    );

    logic [31:0] control_word, next_control_word;
    logic load_control_word;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            control_word <= 32'h0;
        else if (load_control_word)
            control_word <= next_control_word;
    end

    assign clk_per_half_cycle = control_word[7:0];
    assign SS_n = control_word[8];
    assign transmit = control_word[9];

    always_comb begin
        rdata = 32'hx;

        rx_queue_read = 1'b0;

        tx_queue_write = 1'b0;
        tx_queue_data_in = 8'hxx;

        next_control_word = control_word;
        load_control_word = 1'b0;

        case (addr)
            ADDR_CONTROL: begin
                if (re) begin
                    rdata = control_word;
                end
                else if (we) begin
                    next_control_word = wdata;
                    load_control_word = 1'b1;
                end
            end
            ADDR_STATUS: begin
                if (re) begin
                    rdata = {5'h0, busy, tx_queue_num_entries, rx_queue_num_entries};
                end
            end
            ADDR_TX: begin
                if (we) begin
                    tx_queue_write = 1'b1;
                    tx_queue_data_in = wdata[7:0];
                end
            end
            ADDR_RX: begin
                if (re) begin
                    rx_queue_read = 1'b1;
                    rdata = {24'h0, rx_queue_data_out};
                end
            end
        endcase
    end

endmodule
