/*
 * File name: tb_sdram_direct_comm.sv
 * File type: SystemVerilog Testbench
 * DUT: sdram_direct_comm (clk_CPU, re_CPU, we_CPU, addr_CPU, data_read_CPU, data_write_CPU, valid_CPU, clk_SDRAM, addr_SDRAM,
 *                         re_SDRAM, we_SDRAM, data_read_SDRAM, data_write_SDRAM, valid_SDRAM, done_SDRAM);
 * Author: Daniel Zhao
 * Date: 04/25/2024
 * Description: This is a testbench for sdram_direct_comm module. The testbench tests the communication between the CPU 
 *              and the SDRAM. The testbench generates the CPU signals and the SDRAM signals to test the communication
 *              between the CPU and the SDRAM.
 * Dependencies: sdram_direct_comm.sv, SDRAM_params.sv
 */
import SDRAM_params::*; // Import the SDRAM parameters

module tb_sdram_direct_comm();

    // Testing signals
    // CPU side signals
    logic clk_CPU; // Clock signal for the CPU (50 MHz)
    logic re_CPU; // Read enable signal from the CPU
    logic we_CPU; // Write enable signal from the CPU
    logic [31:0] addr_CPU; // Address signal from the CPU
    logic [31:0] data_read_CPU; // Data read for the CPU
    logic [31:0] data_write_CPU; // Data write from the CPU
    logic valid_CPU; // Valid signal indicating that the read/write data is valid

    // SDRAM side signals
    logic clk_SDRAM; // Clock signal for the SDRAM (100 MHz)
    logic [USER_ADDRESS_WIDTH-1:0] addr_SDRAM; // Address signal for the SDRAM
    logic re_SDRAM; // Read enable signal for the SDRAM
    logic we_SDRAM; // Write enable signal for the SDRAM
    logic [15:0] data_read_SDRAM; // Data read from the SDRAM
    logic [15:0] data_write_SDRAM; // Data write to the SDRAM
    logic valid_SDRAM; // Valid signal indicating that the read/write data is valid
    logic done_SDRAM; // Done signal indicating that the first write is complete

    // Create the instance of the DUT
    sdram_direct_comm iDUT(
        .clk_CPU(clk_CPU),
        .re_CPU(re_CPU),
        .we_CPU(we_CPU),
        .addr_CPU(addr_CPU),
        .data_read_CPU(data_read_CPU),
        .data_write_CPU(data_write_CPU),
        .valid_CPU(valid_CPU),
        .clk_SDRAM(clk_SDRAM),
        .addr_SDRAM(addr_SDRAM),
        .re_SDRAM(re_SDRAM),
        .we_SDRAM(we_SDRAM),
        .data_read_SDRAM(data_read_SDRAM),
        .data_write_SDRAM(data_write_SDRAM),
        .valid_SDRAM(valid_SDRAM),
        .done_SDRAM(done_SDRAM)
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
        re_CPU = 0;
        we_CPU = 0;
        addr_CPU = 0;
        data_write_CPU = 0;

        clk_SDRAM = 0;
        data_read_SDRAM = 0;
        valid_SDRAM = 0;
        done_SDRAM = 0;

        // Startup time
        repeat(10) @(posedge clk_CPU);

        // Test the write operation
        // Start the write operation
        we_CPU = 1;
        addr_CPU = 32'h0000_0000;
        data_write_CPU = 32'h1234_5678;
        @(posedge clk_CPU);
        we_CPU = 0;
        addr_CPU = 32'h0000_0000;
        data_write_CPU = 32'h0000_0000;

        // Wait for a few clock cycles
        repeat(3) @(posedge clk_SDRAM);
        
        // Allow write done
        done_SDRAM = 1;
        repeat(2) @(posedge clk_SDRAM);
        done_SDRAM = 0;

        // Wait for some time
        repeat(10) @(posedge clk_CPU);

        // Test the read operation
        // Start the read operation
        re_CPU = 1;
        addr_CPU = 32'h0000_0000;
        @(posedge clk_CPU);
        re_CPU = 0;
        addr_CPU = 32'h0000_0000;

        // Wait for a few clock cycles
        repeat(3) @(posedge clk_SDRAM);

        // Provide the read data
        valid_SDRAM = 1;
        data_read_SDRAM = 16'h5678;
        @(posedge clk_SDRAM);
        valid_SDRAM = 1;
        data_read_SDRAM = 16'h1234;
        @(posedge clk_SDRAM);
        valid_SDRAM = 0;

        // Wait for some time
        repeat(10) @(posedge clk_CPU);

        // End the simulation
        $stop();
    end

endmodule