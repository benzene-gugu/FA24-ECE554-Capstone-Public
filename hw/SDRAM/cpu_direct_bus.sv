/*
 * File name: cpu_direct_bus.sv
 * File Type: SystemVerilog Source
 * Module name: cpu_direct_bus(clk, stall, PC, inst, ready_inst, inst_addr, data_addr, data_re, data_we, data_read, data_write,
 *                              data_ready, data_ack, re_CPU, we_CPU, addr_CPU, data_read_CPU, data_write_CPU, valid_CPU)
 * Testbench: tb_cpu_direct_bus.sv
 * Author: Daniel Zhao
 * Date: 04/25/2024
 * Description: This module handles the actual memory requests from the CPU and convert it into a format that the communicator
 *              can understand better. 
 * Dependent files: NONE
 */
 //TODO: 
module cpu_direct_bus(clk, stall, PC, inst, ready_inst, inst_addr, data_addr, data_re, data_we, data_read, data_write, data_ready, data_ack, re_CPU, we_CPU, addr_CPU, data_read_CPU, data_write_CPU, valid_CPU);

    // Global signals
    input logic clk; // Clock signal for the CPU (50 MHz)

    // Instruction side signals
    input logic stall; // Stall signal from the CPU
    input logic [31:0] PC; // Program counter signal from the CPU (address of the instruction)
    output logic [31:0] inst; // Instruction signal from the CPU
    output logic ready_inst; // Ready signal indicating that the instruction is ready
    output logic [31:0] inst_addr; // Address of the instruction that has been read

    // Data side signals
    input logic [31:0] data_addr; // Address signal from the CPU
    input logic data_re; // Read enable signal from the CPU (asserted until ack is received):TODO
    input logic data_we; // Write enable signal from the CPU (asserted until ack is received):TODO
    output logic [31:0] data_read; // Data read for the CPU
    input logic [31:0] data_write; // Data write from the CPU
    output logic data_ready; // Ready signal indicating that the data is ready
    input logic data_ack; // Acknowledge signal indicating that the data has been received

    // Communicator side signals
    output logic re_CPU; // Read enable signal for the communicator
    output logic we_CPU; // Write enable signal for the communicator
    output logic [31:0] addr_CPU; // Address signal for the communicator
    input logic [31:0] data_read_CPU; // Data read from the communicator
    output logic [31:0] data_write_CPU; // Data write to the communicator
    input logic valid_CPU; // Valid signal indicating that the read/write data is valid

    // Create a buffer for CPU address to be used by comparing results
    logic [31:0] PC_buffer;
    logic PC_buffer_en;

    // Create the flip flop for the PC buffer
    always_ff @(posedge clk) begin
        if(PC_buffer_en) begin
            PC_buffer <= PC;
        end
    end

    // Create the state machine for the handling of the bus; 
    logic rr = 0; // Round-robin signal for data access choice
    logic next_rr; // Next round-robin signal for data access choice
    typedef enum logic [3:0] {
        IDLE = 4'b0000,
        INST_READ = 4'b0001,
        INST_WAIT = 4'b0010,
        INST_COMP = 4'b0011,
        DATA_READ = 4'b0100,
        DATA_READ_WAIT = 4'b0101,
        DATA_READ_COMP = 4'b0110,
        DATA_WRITE = 4'b0111,
        DATA_WRITE_WAIT = 4'b1000,
        DATA_WRITE_COMP = 4'b1001
    } state_t;
    state_t state, next_state;

    // Create the flip flop for the state machine
    always_ff @(posedge clk) begin
        state <= next_state;
    end

    // Create the round-robin logic
    always_ff @(posedge clk) begin
        rr <= next_rr;
    end

    // Create the next state logic
    always_comb begin
        next_state = state;
        re_CPU = 0;
        we_CPU = 0;
        addr_CPU = 0;
        data_write_CPU = 0;
        PC_buffer_en = 0;
        inst = 0;
        ready_inst = 0;
        inst_addr = 0;
        data_read = 0;
        data_ready = 0;
        next_rr = rr;
        case(state)
            IDLE: begin
                if (~rr && ~stall) begin
                    next_state = INST_READ;
                end
                else if (rr & data_re) begin
                    next_state = DATA_READ;
                end
                else if (rr & data_we) begin
                    next_state = DATA_WRITE;
                end
                else begin
                    next_rr = ~rr;
                end
            end
            INST_READ: begin
                re_CPU = 1;
                addr_CPU = PC;
                PC_buffer_en = 1;
                next_state = INST_WAIT;
            end
            INST_WAIT: begin
                addr_CPU = PC;
                if (valid_CPU) begin
                    next_state = INST_COMP;
                end
            end
            INST_COMP: begin
                addr_CPU = PC;
                if (PC_buffer === PC) begin
                    ready_inst = 1;  
                end
                inst_addr = PC_buffer;
                inst = data_read_CPU;
                next_state = IDLE;
            end
            DATA_READ: begin
                re_CPU = 1;
                addr_CPU = data_addr;
                next_state = DATA_READ_WAIT;
            end
            DATA_READ_WAIT: begin
                addr_CPU = data_addr;
                if (valid_CPU) begin
                    next_state = DATA_READ_COMP;
                end
            end
            DATA_READ_COMP: begin
                addr_CPU = data_addr;
                data_read = data_read_CPU;
                data_ready = 1;
                if (data_ack) begin
                    next_state = IDLE;
                end
            end
            DATA_WRITE: begin
                we_CPU = 1;
                addr_CPU = data_addr;
                data_write_CPU = data_write;
                next_state = DATA_WRITE_WAIT;
            end
            DATA_WRITE_WAIT: begin
                addr_CPU = data_addr;
                if (valid_CPU) begin
                    next_state = DATA_WRITE_COMP;
                end
            end
            DATA_WRITE_COMP: begin
                addr_CPU = data_addr;
                data_ready = 1;
                if (data_ack) begin
                    next_state = IDLE;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule