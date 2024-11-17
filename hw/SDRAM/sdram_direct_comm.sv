/*
 * File name: sdram_direct_comm.sv
 * File Type: SystemVerilog Source
 * Module name: sdram_direct_comm(clk_CPU, re_CPU, we_CPU, addr_CPU, data_read_CPU, data_write_CPU, valid_CPU, clk_SDRAM,
 *                                 addr_SDRAM, re_SDRAM, we_SDRAM, data_read_SDRAM, data_write_SDRAM, valid_SDRAM, done_SDRAM)
 * Testbench: tb_sdram_direct_comm.sv
 * Author: Daniel Zhao
 * Date: 04/25/2024
 * Description: This module contains an interface from the CPU to the SDRAM. The module takes in the CPU clock signal, and 
 *              requests from the CPU 1 32-bit data word to be written to the SDRAM. The module then outputs the SDRAM side
 *              data flow, which is 2 16-bit data word.
 * Dependent files: SDRAM_params.sv
 */
import SDRAM_params::*; // Import the SDRAM parameters

module sdram_direct_comm(clk_CPU, re_CPU, we_CPU, addr_CPU, data_read_CPU, data_write_CPU, valid_CPU, clk_SDRAM, addr_SDRAM, re_SDRAM, we_SDRAM, data_read_SDRAM, data_write_SDRAM, valid_SDRAM, done_SDRAM);

    // CPU side signals
    input wire clk_CPU; // Clock signal for the CPU (50 MHz)
    input wire re_CPU; // Read enable signal from the CPU
    input wire we_CPU; // Write enable signal from the CPU
    input wire [31:0] addr_CPU; // Address signal from the CPU
    output wire [31:0] data_read_CPU; // Data read for the CPU
    input wire [31:0] data_write_CPU; // Data write from the CPU
    output wire valid_CPU; // Valid signal indicating that the read/write data is valid

    // SDRAM side signals
    input wire clk_SDRAM; // Clock signal for the SDRAM (100 MHz)
    output wire [USER_ADDRESS_WIDTH-1:0] addr_SDRAM; // Address signal for the SDRAM
    output logic re_SDRAM; // Read enable signal for the SDRAM
    output logic we_SDRAM; // Write enable signal for the SDRAM
    input wire [15:0] data_read_SDRAM; // Data read from the SDRAM
    output logic [15:0] data_write_SDRAM; // Data write to the SDRAM
    input wire valid_SDRAM; // Valid signal indicating that the read/write data is valid
    input wire done_SDRAM; // Done signal indicating that the first write is complete

    // Assign the address signal to the SDRAM
    assign addr_SDRAM = addr_CPU[USER_ADDRESS_WIDTH:1];

    // Buffered CPU data_read for synchronization
    logic [31:0] next_data_read_CPU;
    logic [31:0] data_read_CPU_buffer;

    // Create the flip flop for the data read CPU
    always_ff @(posedge clk_CPU) begin
        data_read_CPU_buffer <= next_data_read_CPU;
    end
    assign data_read_CPU = data_read_CPU_buffer;

    // Buffer CPU valid signal for synchronization
    logic next_valid_CPU;
    logic valid_CPU_buffer;

    // Create the flip flop for the valid CPU
    always_ff @(posedge clk_CPU) begin
        valid_CPU_buffer <= next_valid_CPU;
    end
    assign valid_CPU = valid_CPU_buffer;

    // Temporary storage for the data read from the SDRAM / to be written to the SDRAM
    logic [31:0] data_buffer;
    logic [31:0] next_data_buffer;
    logic buffer_en;

    // Create the flip flop for the data buffer
    always_ff @(posedge clk_SDRAM) begin
        if (buffer_en) begin
            data_buffer <= next_data_buffer;
        end
    end

    // Create the state machine for the communication between the CPU and SDRAM
    typedef enum logic [3:0] {
        IDLE = 4'b0000,
        READ_WAIT = 4'b1000,
        READ_PROC = 4'b1001,
        READ_COMPLETE = 4'b1010,
        WRITE_WAIT = 4'b1100,
        WRITE_PROC = 4'b1101,
        WRITE_COMPLETE = 4'b1110
    } state_t;
    state_t state, next_state;

    // Create the flip flop for the state machine
    always_ff @(posedge clk_SDRAM) begin
        state <= next_state;
    end

    // Create the state machine logic for the communication between the CPU and SDRAM
    always_comb begin
        next_state = state;
        next_data_buffer = data_buffer;
        buffer_en = 0;
        next_valid_CPU = 0;
        next_data_read_CPU = data_read_CPU_buffer;
        re_SDRAM = 0;
        we_SDRAM = 0;
        case(state)
            IDLE: begin
                if (re_CPU) begin
                    next_state = READ_WAIT;
                    buffer_en = 1;
                    next_data_buffer = 0;
                    re_SDRAM = 1;
                end
                else if (we_CPU) begin
                    next_state = WRITE_WAIT;
                    buffer_en = 1;
                    next_data_buffer = data_write_CPU;
                    we_SDRAM = 1;
                end
            end
            READ_WAIT: begin
                re_SDRAM = 1;
                if (valid_SDRAM) begin
                    next_state = READ_PROC;
                    buffer_en = 1;
                    next_data_buffer = {16'h0, data_read_SDRAM};
                end
            end
            READ_PROC: begin
                re_SDRAM = 1;
                buffer_en = 1;
                next_data_buffer = {data_read_SDRAM, data_buffer[15:0]};
                next_state = READ_COMPLETE;
            end
            READ_COMPLETE: begin
                re_SDRAM = 0;
                next_valid_CPU = 1;
                next_data_read_CPU = data_buffer;
                if (valid_CPU) begin
                    next_state = IDLE;
                end
            end
            WRITE_WAIT: begin
                we_SDRAM = 1;
                data_write_SDRAM = data_buffer[15:0];
                if (done_SDRAM) begin
                    next_state = WRITE_PROC;
                end
            end
            WRITE_PROC: begin
                we_SDRAM = 1;
                data_write_SDRAM = data_buffer[31:16];
                next_state = WRITE_COMPLETE;
            end
            WRITE_COMPLETE: begin
                we_SDRAM = 0;
                next_valid_CPU = 1;
                if (valid_CPU) begin
                    next_state = IDLE;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule