`timescale 1ns / 100ps

module tb_spi();

    logic rst_n, clk;

    logic data_available, next_write_data, read_ready;
    logic SCLK, SS_n;
    wire MOSI, MISO;
    wire HOLD_N, WP_N;
    reg HOLD_N_reg, WP_N_reg;
    logic [7:0] write_data, read_data;

    peripheral_SPI_master SPI_master(
        .clk, .rst_n,
        .clk_per_half_cycle(8'h01),
        .data_available,
        .write_data, .next_write_data,
        .read_data, .read_ready,
        .MOSI, .SCLK, .SS_n, .MISO
    );

    assign HOLD_N = HOLD_N_reg;
    assign WP_N = WP_N_reg;

    AT25SF128A flash_chip(
        .SCLK, .CS_N(SS_n), .SI(MOSI), .SO(MISO), .HOLD_N, .WP_N
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        HOLD_N_reg = 1'b1;
        WP_N_reg = 1'b1;
        data_available = 1'b0;
        write_data = 8'h00;
        read_data = 8'h00;

        @(negedge clk);
        @(negedge clk);

        rst_n = 1'b1;

        @(negedge clk);

        // wait for flash chip to power up
        #300_000;

        write_data = 8'h90;
        data_available = 1'b1;

        @(posedge next_write_data);

        write_data = 8'h00;

        repeat(3) @(posedge next_write_data);
        @(posedge read_ready);

        @(posedge next_write_data);
        @(posedge read_ready);
        $display("received 1 %h", read_data);

        @(posedge next_write_data);
        @(posedge read_ready);
        $display("received 2 %h", read_data);

        data_available = 1'b0;

        $stop();
    end

endmodule
