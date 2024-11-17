/*
 * File name: tb_cpu_direct_bus.sv
 * File type: SystemVerilog Testbench
 * DUT: cpu_direct_bus(clk, stall, PC, inst, ready_inst, inst_addr, data_addr, data_re, data_we, data_read, data_write, 
 *                     data_ready, data_ack, re_CPU, we_CPU, addr_CPU, data_read_CPU, data_write_CPU, valid_CPU)
 * Author: Daniel Zhao
 * Date: 04/25/2024
 * Description: This is a testbench for cpu_direct_bus module. The testbench tests the communication between the CPU and
 *              the communicator. The testbench generates the CPU signals and the communicator signals to test the functionality
 *              of the bus. 
 * Dependencies: cpu_direct_bus.sv
 */
module tb_cpu_direct_bus();
    
    // Testing signals
    // Global signals
    logic clk; // Clock signal for the CPU (50 MHz)

    // Instruction side signals
    logic stall; // Stall signal from the CPU
    logic [31:0] PC; // Program counter signal from the CPU (address of the instruction)
    logic [31:0] inst; // Instruction signal from the CPU\
    logic ready_inst; // Ready signal indicating that the instruction is ready
    logic [31:0] inst_addr; // Address of the instruction that has been read

    // Data side signals
    logic [31:0] data_addr; // Address signal from the CPU
    logic data_re; // Read enable signal from the CPU (asserted until ack is received)
    logic data_we; // Write enable signal from the CPU (asserted until ack is received)
    logic [31:0] data_read; // Data read for the CPU
    logic [31:0] data_write; // Data write from the CPU
    logic data_ready; // Ready signal indicating that the data is ready
    logic data_ack; // Acknowledge signal indicating that the data has been received

    // Communicator side signals
    logic re_CPU; // Read enable signal for the communicator
    logic we_CPU; // Write enable signal for the communicator
    logic [31:0] addr_CPU; // Address signal for the communicator
    logic [31:0] data_read_CPU; // Data read from the communicator
    logic [31:0] data_write_CPU; // Data write to the communicator
    logic valid_CPU; // Valid signal indicating that the read/write data is valid

    // Create the instance of the DUT
    cpu_direct_bus iDUT(
        .clk(clk),
        .stall(stall),
        .PC(PC),
        .inst(inst),
        .ready_inst(ready_inst),
        .inst_addr(inst_addr),
        .data_addr(data_addr),
        .data_re(data_re),
        .data_we(data_we),
        .data_read(data_read),
        .data_write(data_write),
        .data_ready(data_ready),
        .data_ack(data_ack),
        .re_CPU(re_CPU),
        .we_CPU(we_CPU),
        .addr_CPU(addr_CPU),
        .data_read_CPU(data_read_CPU),
        .data_write_CPU(data_write_CPU),
        .valid_CPU(valid_CPU)
    );

    // Create the clock signal for the CPU
    always begin
        #20 clk = ~clk;
    end

    // Create the testbench logic
    initial begin
        // Initialize the signals
        clk = 0;
        stall = 1;
        PC = 0;
        data_addr = 0;
        data_re = 0;
        data_we = 0;
        data_write = 0;
        data_ack = 0;
        data_read_CPU = 0;
        valid_CPU = 0;

        // Wait for a few clock cycles
        repeat(10) @(posedge clk);

        // Test the read req from instruction side with no alteration of CPU signals
        stall = 0;
        repeat(10) @(posedge clk);
        data_read_CPU = 32'h1234_5678;
        valid_CPU = 1;
        @(posedge ready_inst);
        stall = 1;
        valid_CPU = 0;

        // Wait for a few clock cycles
        repeat(10) @(posedge clk);

        // Test the read req from instruction side with alteration of CPU signals
        PC = 0;
        stall = 0;
        repeat(5) @(posedge clk);
        PC = 32'h0000_1000;
        repeat(5) @(posedge clk);
        data_read_CPU = 32'h1234_5678;
        valid_CPU = 1;
        @(posedge ready_inst);
        stall = 1;
        valid_CPU = 0;

        // Wait for a few clock cycles
        repeat(10) @(posedge clk);

        // Test the read req from data side
        data_addr = 32'h0000_0000;
        data_re = 1;
        repeat(10) @(posedge clk);
        data_read_CPU = 32'h1234_5678;
        valid_CPU = 1;
        @(posedge data_ready);
        @(posedge clk);
        data_re = 0;
        data_ack = 1;
        valid_CPU = 0;
        @(posedge clk);
        data_ack = 0;

        // Wait for a few clock cycles
        repeat(10) @(posedge clk);

        // Test the write req from data side
        data_addr = 32'h0000_0000;
        data_we = 1;
        data_write = 32'h1234_5678;
        repeat(10) @(posedge clk);
        valid_CPU = 1;
        @(posedge data_ready);
        @(posedge clk);
        data_we = 0;
        data_ack = 1;
        valid_CPU = 0;
        @(posedge clk);
        data_ack = 0;

        // Wait for a few clock cycles
        repeat(10) @(posedge clk);

        // Test the read req from instruction side with read data from data side
        PC = 0;
        stall = 0;
        data_addr = 32'h0000_0000;
        data_re = 1;
        repeat(10) @(posedge clk);
        // Read was processed first in this rr case
        data_read_CPU = 32'h1234_5678;
        valid_CPU = 1;
        @(posedge data_ready);
        @(posedge clk);
        data_re = 0;
        data_ack = 1;
        valid_CPU = 0;
        @(posedge clk);
        data_ack = 0;
        repeat(10) @(posedge clk);
        data_read_CPU = 32'h1234_5678;
        valid_CPU = 1;
        @(posedge ready_inst);
        stall = 1;
        valid_CPU = 0;

        // Wait for a few clock cycles
        repeat(10) @(posedge clk);

        // Test the read req from instruction side with write data from data side
        PC = 0;
        stall = 0;
        data_addr = 32'h0000_0000;
        data_we = 1;
        data_write = 32'h1234_5678;
        repeat(10) @(posedge clk);
        // Write was processed first in this rr case
        valid_CPU = 1;
        @(posedge data_ready);
        @(posedge clk);
        data_we = 0;
        data_ack = 1;
        valid_CPU = 0;
        @(posedge clk);
        data_ack = 0;
        repeat(10) @(posedge clk);
        data_read_CPU = 32'h1234_5678;
        valid_CPU = 1;
        @(posedge ready_inst);
        stall = 1;
        valid_CPU = 0;

        // Wait for a few clock cycles
        repeat(10) @(posedge clk);

        // Complete the testbench
        $stop();
    end

endmodule