/*
 * File name: sdram_comm.sv
 * File Type: SystemVerilog Source
 * Module name: sdram_comm(clk_CPU, re_CPU, we_CPU, addr_CPU, data_read_CPU, data_write_CPU, valid_CPU, clk_SDRAM, addr_SDRAM,
 *                         re_SDRAM, we_SDRAM, data_read_SDRAM, data_write_SDRAM, valid_SDRAM, done_SDRAM)
 * Testbench: tb_sdram_comm.sv
 * Author: Daniel Zhao
 * Date: 04/16/2024
 * Description: This module contains an interface from the CPU to the SDRAM. The module takes in the CPU clock signal, and 
 *              requests from the CPU 4 32-bit data words to be written to the SDRAM. The module then outputs the SDRAM 
 *              data flow, which is 8 16-bit data half-words. 
 * Dependent files: NONE
 */
module sdram_comm(clk_CPU, rst_n, re_CPU, we_CPU, addr_CPU, data_read_CPU, data_write_CPU, valid_CPU, clk_SDRAM, addr_SDRAM, data_write_SDRAM, write_SDRAM, request_SDRAM, ack_SDRAM, valid_SDRAM, data_read_SDRAM);

    // CPU side signals
    input wire clk_CPU; // Clock signal for the CPU (50 MHz)
    input logic rst_n; // Reset signal for the CPU
    input logic re_CPU; // Read enable signal from the CPU
    input logic we_CPU; // Write enable signal from the CPU
    input logic [31:0] addr_CPU; // Address signal from the CPU
    output logic [31:0] data_read_CPU; // Data read for the CPU
    input logic [31:0] data_write_CPU; // Data write from the CPU
    output logic valid_CPU; // Valid signal indicating that the read/write data is valid

    // SDRAM side signals
    input wire clk_SDRAM; // Clock signal for the SDRAM (100 MHz)
    output logic [23:0] addr_SDRAM; // Address signal for the SDRAM
    output logic [31:0] data_write_SDRAM; // Data write for the SDRAM
    output logic write_SDRAM; // Write signal for the SDRAM
    output logic request_SDRAM; // Request signal for the SDRAM
    input logic ack_SDRAM; // Acknowledge signal for the SDRAM
    input logic valid_SDRAM; // Valid signal indicating that the read/write data is valid
    input logic [31:0] data_read_SDRAM; // Data read for the SDRAM


    // Signals for flopping the address signal
    logic [23:0] addr_SDRAM_buffer;
    logic addr_SDRAM_buffer_en;

    // Create the flip flop for the address signal
    always_ff @(posedge clk_SDRAM, negedge rst_n) begin
        if (~rst_n) begin
            addr_SDRAM_buffer <= 0;
        end
        else if (addr_SDRAM_buffer_en) begin
            addr_SDRAM_buffer <= addr_CPU[25:2];
        end
    end

    // Buffered CPU data_read for synchronization
    logic [31:0] next_data_read_CPU;
    logic [31:0] data_read_CPU_buffer;

    // Create the flip flop for the data read CPU
    always_ff @(posedge clk_CPU, negedge rst_n) begin
        if (~rst_n) begin
            data_read_CPU_buffer <= 0;
        end
        else begin
            data_read_CPU_buffer <= next_data_read_CPU;
        end
    end
    assign data_read_CPU = data_read_CPU_buffer;

    // Buffer CPU valid signal for synchronization
    logic next_valid_CPU;
    logic valid_CPU_buffer;

    // Create the flip flop for the valid CPU
    always_ff @(posedge clk_CPU, negedge rst_n) begin
        if (~rst_n) begin
            valid_CPU_buffer <= 0;
        end
        else begin
            valid_CPU_buffer <= next_valid_CPU;
        end
    end
    assign valid_CPU = valid_CPU_buffer;

    // Temporary storage for the data to be written to the SDRAM
    logic [127:0] data_buffer;
    logic [127:0] next_data_buffer;
    logic buffer_en;

    // Create the flip flop for the data buffer
    always_ff @(posedge clk_SDRAM, negedge rst_n) begin
        if (~rst_n) begin
            data_buffer <= 0;
        end
        else if (buffer_en) begin
            data_buffer <= next_data_buffer;
        end
    end

    // Temporary storage for teh data read from the SDRAM
    logic [127:0] data_read_buffer;
    logic [127:0] next_data_read_buffer;
    logic read_buffer_en;

    // Create the flip flop for the data read buffer
    always_ff @(posedge clk_SDRAM, negedge rst_n) begin
        if (~rst_n) begin
            data_read_buffer <= 0;
        end
        else if (read_buffer_en) begin
            data_read_buffer <= next_data_read_buffer;
        end
    end

    // Create the additional state machine for capturing the data read from the SDRA
    typedef enum logic [2:0] {
        READ_IDLE,
        READ_WAIT_VALID_1,
        READ_WAIT_VALID_2,
        READ_WAIT_VALID_3,
        READ_WAIT_VALID_4,
        READ_COMPLETE
    } read_state_t;
    read_state_t read_state, next_read_state;

    // Create the flip flop for the read state machine
    always_ff @(posedge clk_SDRAM, negedge rst_n) begin
        if (~rst_n) begin
            read_state <= READ_IDLE;
        end
        else begin
            read_state <= next_read_state;
        end
    end

    logic read_complete;
    logic read_complete_ack;

    // Create the state machine logic for capturing the data read from the SDRAM
    always_comb begin
        next_read_state = read_state;
        read_buffer_en = 0;
        next_data_read_buffer = data_read_buffer;
        read_complete = 0;
        case(read_state)
            READ_IDLE: begin
                if (re_CPU) begin
                    next_read_state = READ_WAIT_VALID_1;
                end
            end
            READ_WAIT_VALID_1: begin
                if (valid_SDRAM) begin
                    read_buffer_en = 1;
                    next_data_read_buffer = {96'h0, data_read_SDRAM};
                    next_read_state = READ_WAIT_VALID_2;
                end
            end
            READ_WAIT_VALID_2: begin
                if (valid_SDRAM) begin
                    read_buffer_en = 1;
                    next_data_read_buffer = {data_read_buffer[95:0], data_read_SDRAM};
                    next_read_state = READ_WAIT_VALID_3;
                end
            end
            READ_WAIT_VALID_3: begin
                if (valid_SDRAM) begin
                    read_buffer_en = 1;
                    next_data_read_buffer = {data_read_buffer[95:0], data_read_SDRAM};
                    next_read_state = READ_WAIT_VALID_4;
                end
            end
            READ_WAIT_VALID_4: begin
                if (valid_SDRAM) begin
                    read_buffer_en = 1;
                    next_data_read_buffer = {data_read_buffer[95:0], data_read_SDRAM};
                    next_read_state = READ_COMPLETE;
                end
            end
            READ_COMPLETE: begin
                read_complete = 1;
                if (read_complete_ack) begin
                    next_read_state = READ_IDLE;
                end
            end
        endcase
    end

    // Create the main state machine for the communication between the CPU and SDRAM
    typedef enum logic [5:0] {
        IDLE,
        READ_REQ_1,
        READ_WAIT_ACK_1,
        READ_REQ_2,
        READ_WAIT_ACK_2,
        READ_REQ_3,
        READ_WAIT_ACK_3,
        READ_REQ_4,
        READ_WAIT_ACK_4,
        READ_WAIT_VALID,
        READ_COMPLETE_1,
        READ_PAUSE_1,
        READ_COMPLETE_2,
        READ_PAUSE_2,
        READ_COMPLETE_3,
        READ_PAUSE_3,
        READ_COMPLETE_4,
        READ_PAUSE_4,
        WRITE_PAUSE_1,
        WRITE_STREAM_1,
        WRITE_PAUSE_2,
        WRITE_STREAM_2,
        WRITE_PAUSE_3,
        WRITE_STREAM_3,
        WRITE_REQ_1,
        WRITE_WAIT_ACK_1,
        WRITE_REQ_2,
        WRITE_WAIT_ACK_2,
        WRITE_REQ_3,
        WRITE_WAIT_ACK_3,
        WRITE_REQ_4,
        WRITE_WAIT_ACK_4,
        WRITE_COMPLETE_1,
        WRITE_COMPLETE_2
    } main_state_t;
    main_state_t state, next_state;

    // Create the flip flop for the state machine
    always_ff @(posedge clk_SDRAM, negedge rst_n) begin
        if (~rst_n) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    // Create the state machine logic for the communication between the CPU and SDRAM
    always_comb begin
        next_state = state;
        addr_SDRAM_buffer_en = 0;
        addr_SDRAM = 0;
        write_SDRAM = 0;
        request_SDRAM = 0;
        buffer_en = 0;
        next_data_buffer = data_buffer;
        next_data_read_CPU = data_read_CPU;
        next_valid_CPU = 0;
        data_write_SDRAM = 0;
        read_complete_ack = 0;
        case(state)
            IDLE: begin
                if (we_CPU) begin
                    addr_SDRAM_buffer_en = 1;
                    buffer_en = 1;
                    next_data_buffer = {96'h0, data_write_CPU};
                    next_state = WRITE_PAUSE_1;
                end
                else if (re_CPU) begin
                    addr_SDRAM_buffer_en = 1;
                    next_state = READ_REQ_1;
                end
            end
            READ_REQ_1: begin
                write_SDRAM = 0;
                request_SDRAM = 1;
                addr_SDRAM = addr_SDRAM_buffer;
                next_state = READ_WAIT_ACK_1;
            end
            READ_WAIT_ACK_1: begin
                write_SDRAM = 0;
                request_SDRAM = 1;
                addr_SDRAM = addr_SDRAM_buffer;
                if (ack_SDRAM) begin
                    next_state = READ_REQ_2;
                end
            end
            READ_REQ_2: begin
                write_SDRAM = 0;
                request_SDRAM = 1;
                addr_SDRAM = addr_SDRAM_buffer + 1;
                next_state = READ_WAIT_ACK_2;
            end
            READ_WAIT_ACK_2: begin
                write_SDRAM = 0;
                request_SDRAM = 1;
                addr_SDRAM = addr_SDRAM_buffer + 1;
                if (ack_SDRAM) begin
                    next_state = READ_REQ_3;
                end
            end
            READ_REQ_3: begin
                write_SDRAM = 0;
                request_SDRAM = 1;
                addr_SDRAM = addr_SDRAM_buffer + 2;
                next_state = READ_WAIT_ACK_3;
            end
            READ_WAIT_ACK_3: begin
                write_SDRAM = 0;
                request_SDRAM = 1;
                addr_SDRAM = addr_SDRAM_buffer + 2;
                if (ack_SDRAM) begin
                    next_state = READ_REQ_4;
                end
            end
            READ_REQ_4: begin
                write_SDRAM = 0;
                request_SDRAM = 1;
                addr_SDRAM = addr_SDRAM_buffer + 3;
                next_state = READ_WAIT_ACK_4;
            end
            READ_WAIT_ACK_4: begin
                write_SDRAM = 0;
                request_SDRAM = 1;
                addr_SDRAM = addr_SDRAM_buffer + 3;
                if (ack_SDRAM) begin
                    next_state = READ_WAIT_VALID;
                end
            end
            READ_WAIT_VALID: begin
                write_SDRAM = 0;
                request_SDRAM = 0;
                addr_SDRAM = 0;
                if (read_complete) begin
                    next_state = READ_COMPLETE_1;
                    read_complete_ack = 1;
                end
            end
            READ_COMPLETE_1: begin
                next_data_read_CPU = data_read_buffer[127:96];
                next_valid_CPU = 1;
                next_state = READ_PAUSE_1;
            end
            READ_PAUSE_1: begin
                next_valid_CPU = 1;
                next_data_read_CPU = data_read_buffer[127:96];
                next_state = READ_COMPLETE_2;
            end
            READ_COMPLETE_2: begin
                next_valid_CPU = 0;
                next_data_read_CPU = data_read_buffer[95:64];
                next_state = READ_PAUSE_2;
            end
            READ_PAUSE_2: begin
                next_valid_CPU = 0;
                next_data_read_CPU = data_read_buffer[95:64];
                next_state = READ_COMPLETE_3;
            end
            READ_COMPLETE_3: begin
                next_valid_CPU = 0;
                next_data_read_CPU = data_read_buffer[63:32];
                next_state = READ_PAUSE_3;
            end
            READ_PAUSE_3: begin
                next_valid_CPU = 0;
                next_data_read_CPU = data_read_buffer[63:32];
                next_state = READ_COMPLETE_4;
            end
            READ_COMPLETE_4: begin
                next_valid_CPU = 0;
                next_data_read_CPU = data_read_buffer[31:0];
                next_state = READ_PAUSE_4;
            end
            READ_PAUSE_4: begin
                next_valid_CPU = 0;
                next_data_read_CPU = data_read_buffer[31:0];
                next_state = IDLE;
            end
            WRITE_PAUSE_1: begin
                next_state = WRITE_STREAM_1;
            end
            WRITE_STREAM_1: begin
                next_state = WRITE_PAUSE_2;
                buffer_en = 1;
                next_data_buffer = {data_buffer[95:0], data_write_CPU};
            end
            WRITE_PAUSE_2: begin
                next_state = WRITE_STREAM_2;
            end
            WRITE_STREAM_2: begin
                next_state = WRITE_PAUSE_3;
                buffer_en = 1;
                next_data_buffer = {data_buffer[95:0], data_write_CPU};
            end
            WRITE_PAUSE_3: begin
                next_state = WRITE_STREAM_3;
            end
            WRITE_STREAM_3: begin
                next_state = WRITE_REQ_1;
                buffer_en = 1;
                next_data_buffer = {data_buffer[95:0], data_write_CPU};
            end
            WRITE_REQ_1: begin
                write_SDRAM = 1;
                request_SDRAM = 1;
                addr_SDRAM = addr_SDRAM_buffer;
                data_write_SDRAM = data_buffer[127:96];
                next_state = WRITE_WAIT_ACK_1;
            end
            WRITE_WAIT_ACK_1: begin
                write_SDRAM = 1;
                request_SDRAM = 1;
                addr_SDRAM = addr_SDRAM_buffer;
                data_write_SDRAM = data_buffer[127:96];
                if (ack_SDRAM) begin
                    next_state = WRITE_REQ_2;
                end
            end
            WRITE_REQ_2: begin
                write_SDRAM = 1;
                request_SDRAM = 1;
                addr_SDRAM = addr_SDRAM_buffer + 1;
                data_write_SDRAM = data_buffer[95:64];
                next_state = WRITE_WAIT_ACK_2;
            end
            WRITE_WAIT_ACK_2: begin
                write_SDRAM = 1;
                request_SDRAM = 1;
                addr_SDRAM = addr_SDRAM_buffer + 1;
                data_write_SDRAM = data_buffer[95:64];
                if (ack_SDRAM) begin
                    next_state = WRITE_REQ_3;
                end
            end
            WRITE_REQ_3: begin
                write_SDRAM = 1;
                request_SDRAM = 1;
                addr_SDRAM = addr_SDRAM_buffer + 2;
                data_write_SDRAM = data_buffer[63:32];
                next_state = WRITE_WAIT_ACK_3;
            end
            WRITE_WAIT_ACK_3: begin
                write_SDRAM = 1;
                request_SDRAM = 1;
                addr_SDRAM = addr_SDRAM_buffer + 2;
                data_write_SDRAM = data_buffer[63:32];
                if (ack_SDRAM) begin
                    next_state = WRITE_REQ_4;
                end
            end
            WRITE_REQ_4: begin
                write_SDRAM = 1;
                request_SDRAM = 1;
                addr_SDRAM = addr_SDRAM_buffer + 3;
                data_write_SDRAM = data_buffer[31:0];
                next_state = WRITE_WAIT_ACK_4;
            end
            WRITE_WAIT_ACK_4: begin
                write_SDRAM = 1;
                request_SDRAM = 1;
                addr_SDRAM = addr_SDRAM_buffer + 3;
                data_write_SDRAM = data_buffer[31:0];
                if (ack_SDRAM) begin
                    next_state = WRITE_COMPLETE_1;
                end
            end
            WRITE_COMPLETE_1: begin
                request_SDRAM = 0;
                next_valid_CPU = 1;
                next_state = WRITE_COMPLETE_2;
            end
            WRITE_COMPLETE_2: begin
                next_valid_CPU = 1;
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule