/*
 * File name: tb_sdram_comm.sv
 * File type: SystemVerilog Testbench
 * DUT: sdram_comm(clk_CPU, re_CPU, we_CPU, addr_CPU, data_read_CPU, data_write_CPU, valid_CPU, clk_SDRAM, addr_SDRAM, re_SDRAM,
 *                 we_SDRAM, data_read_SDRAM, data_write_SDRAM, valid_SDRAM, done_SDRAM)
 * Author: Daniel Zhao
 * Date: 04/27/2024
 * Description: This is a testbench for sdram_comm module. The testbench tests the communication between the CPU and the
 *              SDRAM. The testbench generates the CPU signals and the SDRAM signals to test the communication between the
 *              CPU and the SDRAM.
 * Dependencies: sdram_comm.sv, SDRAM_params.sv
 */
module tb_sdram_comm();

    // Testing signals
    // CPU side signals
    logic clk_CPU; // Clock signal for the CPU (50 MHz)
    logic rst_n; // Reset signal for the CPU
    logic re; // Read enable signal from the CPU
    logic we; // Write enable signal from the CPU
    logic [31:0] addr_CPU; // Address signal from the CPU
    logic [31:0] data_read_CPU; // Data read for the CPU
    logic [31:0] data_write_CPU; // Data write from the CPU
    logic valid_CPU; // Valid signal indicating that the read/write data is valid

    // SDRAM side signals
    logic clk_SDRAM; // Clock signal for the SDRAM (100 MHz)
    logic [23:0] addr_SDRAM; // Address signal for the SDRAM
    logic [31:0] data_write_SDRAM; // Data write for the SDRAM
    logic write_SDRAM; // Write enable signal for the SDRAM
    logic request_SDRAM; // Request signal from the CPU to the SDRAM
    logic ack_SDRAM; // Acknowledge signal from the SDRAM to the CPU
    logic valid_SDRAM; // Valid signal indicating that the read/write data is valid
    logic [31:0] data_read_SDRAM; // Data read for the SDRAM

    // Create the instance of the DUT
    sdram_comm iDUT(
        .clk_CPU(clk_CPU),
        .rst_n(rst_n),
        .re_CPU(re),
        .we_CPU(we),
        .addr_CPU(addr_CPU),
        .data_read_CPU(data_read_CPU),
        .data_write_CPU(data_write_CPU),
        .valid_CPU(valid_CPU),

        .clk_SDRAM(clk_SDRAM),
        .addr_SDRAM(addr_SDRAM),
        .data_write_SDRAM(data_write_SDRAM),
        .write_SDRAM(write_SDRAM),
        .request_SDRAM(request_SDRAM),
        .ack_SDRAM(ack_SDRAM),
        .valid_SDRAM(valid_SDRAM),
        .data_read_SDRAM(data_read_SDRAM)
    );

    // Create the clock signal for the CPU
    always begin
        #20 clk_CPU = ~clk_CPU;
    end

    // Create the clock signal for the SDRAM
    always begin
        #10 clk_SDRAM = ~clk_SDRAM;
    end

    // Create the testbench logic
    initial begin
        // Initialize the signals
        clk_CPU = 0;
        rst_n = 1;
        re = 0;
        we = 0;
        addr_CPU = 32'hxxxx_xxxx;
        data_write_CPU = 32'hxxxx_xxxx;

        clk_SDRAM = 0;
        ack_SDRAM = 0;
        valid_SDRAM = 0;
        data_read_SDRAM = 16'hxxxx;

        // Reset the CPU
        @(negedge clk_CPU)
        rst_n = 0;
        @(negedge clk_CPU)
        rst_n = 1;


        // Startup time
        repeat(10) @(posedge clk_CPU);

        // Test the write operation
        // Start the write operation
        we = 1;
        addr_CPU = 32'h0001_0000;
        data_write_CPU = 32'h0010_0011;
        @(posedge clk_CPU);
        we = 0;
        addr_CPU = 32'hxxxx_xxxx;
        data_write_CPU = 32'h0012_0013;
        @(posedge clk_CPU);
        data_write_CPU = 32'h0014_0015;
        @(posedge clk_CPU);
        data_write_CPU = 32'h0016_0017;
        @(posedge clk_CPU);
        data_write_CPU = 32'hxxxx_xxxx;

        // Wait for a few clock cycles
        repeat(10) @(posedge clk_SDRAM);
        ack_SDRAM = 1;
        @(posedge clk_SDRAM);
        ack_SDRAM = 0;
        
        repeat(10) @(posedge clk_SDRAM);
        ack_SDRAM = 1;
        @(posedge clk_SDRAM);
        ack_SDRAM = 0;

        repeat(10) @(posedge clk_SDRAM);
        ack_SDRAM = 1;
        @(posedge clk_SDRAM);
        ack_SDRAM = 0;

        repeat(10) @(posedge clk_SDRAM);
        ack_SDRAM = 1;
        @(posedge clk_SDRAM);
        ack_SDRAM = 0;

        while(valid_CPU != 1'd1)
            @(posedge clk_CPU);

        // Test the read operation
        // Start the read operation
        re = 1;
        addr_CPU = 32'h0000_1000;
        @(posedge clk_CPU);
        re = 0;
        addr_CPU = 32'hxxxx_xxxx;

        // Wait for a few clock cycles
        repeat(10) @(posedge clk_SDRAM);
        ack_SDRAM = 1;
        @(posedge clk_SDRAM);
        ack_SDRAM = 0;

        repeat(10) @(posedge clk_SDRAM);
        ack_SDRAM = 1;
        valid_SDRAM = 1;
        data_read_SDRAM = 32'h0020_0021;
        @(posedge clk_SDRAM);
        ack_SDRAM = 0;
        valid_SDRAM = 0;
        data_read_SDRAM = 32'hxxxx_xxxx;

        repeat(10) @(posedge clk_SDRAM);
        ack_SDRAM = 1;
        valid_SDRAM = 1;
        data_read_SDRAM = 32'h0022_0023;
        @(posedge clk_SDRAM);
        ack_SDRAM = 0;
        valid_SDRAM = 0;
        data_read_SDRAM = 32'hxxxx_xxxx;

        repeat(10) @(posedge clk_SDRAM);
        ack_SDRAM = 1;
        valid_SDRAM = 1;
        data_read_SDRAM = 32'h0024_0025;
        @(posedge clk_SDRAM);
        ack_SDRAM = 0;
        valid_SDRAM = 0;
        data_read_SDRAM = 32'hxxxx_xxxx;

        repeat(10) @(posedge clk_SDRAM);
        valid_SDRAM = 1;
        data_read_SDRAM = 32'h0026_0027;
        @(posedge clk_SDRAM);
        valid_SDRAM = 0;
        data_read_SDRAM = 32'hxxxx_xxxx;

        // Wait for some time
        repeat(10) @(posedge clk_CPU);


        // Wait for some time
        repeat(10) @(posedge clk_CPU);

        // Stop the testbench
        $stop();

    end
endmodule