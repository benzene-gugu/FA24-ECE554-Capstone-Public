/*
 * File name: tb_cache_bus.sv
 * File type: SystemVerilog Testbench
 * DUT: cache_bus(clk, inst_re, inst_addr, inst_data, inst_valid, data_re, data_we, data_addr, data_read, data_write,
 *                data_valid, comm_re, comm_we, comm_addr, comm_read_data, comm_write_data, comm_valid)
 * Author: Daniel Zhao
 * Date: 04/27/2024
 * Description: This is a testbench for cache_bus module. The testbench tests the communication between the cache and
 *              the communicator. The testbench generates the cache signals and the communicator signals to test the functionality
 *              of the bus.
 * Dependencies: cache_bus.sv
 */
module tb_cache_bus();

    // Testing signals
    // Global signals
    logic clk; // Clock signal for the CPU (50 MHz)

    // Instruction side signals
    logic inst_re; // Read enable signal from the CPU (asserted until ack is received)
    logic [31:0] inst_addr; // Address signal from the CPU
    logic [31:0] inst_data; // Data signal from the CPU
    logic inst_valid; // Valid signal indicating that the read/write data is valid

    // Data side signals
    logic data_re; // Read enable signal from the CPU (asserted until ack is received)
    logic data_we; // Write enable signal from the CPU (asserted until ack is received)
    logic [31:0] data_addr; // Address signal from the CPU
    logic [31:0] data_read; // Data read for the CPU
    logic [31:0] data_write; // Data write from the CPU
    logic data_valid; // Valid signal indicating that the read/write data is valid

    // Communicator side signals
    logic comm_re; // Read enable signal for the communicator
    logic comm_we; // Write enable signal for the communicator
    logic [31:0] comm_addr; // Address signal for the communicator
    logic [31:0] comm_read_data; // Data read from the communicator
    logic [31:0] comm_write_data; // Data write to the communicator
    logic comm_valid; // Valid signal indicating that the read/write data is valid

    // Create the instance of the DUT
    cache_bus iDUT(
        .clk(clk),
        .inst_re(inst_re),
        .inst_addr(inst_addr),
        .inst_data(inst_data),
        .inst_valid(inst_valid),
        .data_re(data_re),
        .data_we(data_we),
        .data_addr(data_addr),
        .data_read(data_read),
        .data_write(data_write),
        .data_valid(data_valid),
        .comm_re(comm_re),
        .comm_we(comm_we),
        .comm_addr(comm_addr),
        .comm_read_data(comm_read_data),
        .comm_write_data(comm_write_data),
        .comm_valid(comm_valid)
    );

    // Create the clock signal for the CPU
    always begin
        #20 clk = ~clk;
    end

    // Create the testbench logic
    initial begin
        // Initialize the signals
        clk = 0;
        inst_re = 0;
        inst_addr = 0;
        data_re = 0;
        data_we = 0;
        data_addr = 0;
        data_write = 0;
        comm_read_data = 0;
        comm_valid = 0;

        // Wait for a few clock cycles
        repeat(10) @(posedge clk);

        // Test instruction read
        inst_re = 1;
        inst_addr = 32'h0000_0010;
        @(posedge clk);
        inst_re = 0;
        repeat(10) @(posedge clk);
        comm_valid = 1;
        comm_read_data = 32'h0000_0001;
        @(posedge clk);
        comm_valid = 0;
        comm_read_data = 32'h0002_0003;
        @(posedge clk);
        comm_read_data = 32'h0004_0005;
        @(posedge clk);
        comm_read_data = 32'h0006_0007;

        // Wait for a few clock cycles
        repeat(10) @(posedge clk);

        // Test data read
        data_re = 1;
        data_addr = 32'h0000_0100;
        @(posedge clk);
        data_re = 0;
        repeat(10) @(posedge clk);
        comm_valid = 1;
        comm_read_data = 32'h0010_0011;
        @(posedge clk);
        comm_valid = 0;
        comm_read_data = 32'h0012_0013;
        @(posedge clk);
        comm_read_data = 32'h0014_0015;
        @(posedge clk);
        comm_read_data = 32'h0016_0017;

        // Wait for a few clock cycles
        repeat(10) @(posedge clk);

        // Test data write
        data_we = 1;
        data_addr = 32'h0000_1000;
        data_write = 32'h0020_0021;
        @(posedge clk);
        data_we = 0;
        data_write = 32'h0022_0023;
        @(posedge clk);
        data_write = 32'h0024_0025;
        @(posedge clk);
        data_write = 32'h0026_0027;
        repeat(10) @(posedge clk);
        comm_valid = 1;
        @(posedge clk);
        comm_valid = 0;

        // Wait for a few clock cycles
        repeat(10) @(posedge clk);

        // Test instruction read the same time as data read
        inst_re = 1;
        inst_addr = 32'h0000_0010;
        data_re = 1;
        data_addr = 32'h0000_0100;
        @(posedge clk);
        inst_re = 0;
        data_re = 0;
        repeat(10) @(posedge clk);
        comm_valid = 1;
        comm_read_data = 32'h0010_0011;
        @(posedge clk);
        comm_valid = 0;
        comm_read_data = 32'h0012_0013;
        @(posedge clk);
        comm_read_data = 32'h0014_0015;
        @(posedge clk);
        comm_read_data = 32'h0016_0017;
        repeat(10) @(posedge clk);
        comm_valid = 1;
        comm_read_data = 32'h0000_0001;
        @(posedge clk);
        comm_valid = 0;
        comm_read_data = 32'h0002_0003;
        @(posedge clk);
        comm_read_data = 32'h0004_0005;
        @(posedge clk);
        comm_read_data = 32'h0006_0007;

        // Wait for a few clock cycles
        repeat(10) @(posedge clk);

        // Test instruction read the same time as data write
        inst_re = 1;
        inst_addr = 32'h0000_0010;
        data_we = 1;
        data_addr = 32'h0000_1000;
        data_write = 32'h0020_0021;
        @(posedge clk);
        inst_re = 0;
        data_we = 0;
        data_write = 32'h0022_0023;
        @(posedge clk);
        data_write = 32'h0024_0025;
        @(posedge clk);
        data_write = 32'h0026_0027;
        repeat(10) @(posedge clk);
        comm_valid = 1;
        comm_read_data = 32'h0000_0001;
        @(posedge clk);
        comm_valid = 0;
        comm_read_data = 32'h0002_0003;
        @(posedge clk);
        comm_read_data = 32'h0004_0005;
        @(posedge clk);
        comm_read_data = 32'h0006_0007;
        repeat(10) @(posedge clk);
        comm_valid = 1;
        @(posedge clk);
        comm_valid = 0;

        // Wait for a few clock cycles
        repeat(10) @(posedge clk);

        // Stop the simulation
        $stop();
    end

endmodule