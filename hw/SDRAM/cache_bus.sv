/*
 * File name: cache_bus.sv
 * File Type: SystemVerilog Source
 * Module name: cache_bus(clk, inst_re, inst_addr, inst_data, inst_valid, data_re, data_we, data_addr, data_read, data_write,
 *                        data_valid, comm_re, comm_we, comm_addr, comm_read_data, comm_write_data, comm_valid)
 * Testbench: tb_cache_bus.sv
 * Author: Daniel Zhao
 * Date: 04/27/2024
 * Description: This module contains a bus that connects the dedicated caches to the communication module between the CPU
 *              and the SDRAM. 
 * Dependent files: NONE
 */
module cache_bus(clk, rst_n, inst_re, inst_addr, inst_data, inst_valid, data_re, data_we, data_addr, data_read, data_write, data_valid, comm_re, comm_we, comm_addr, comm_read_data, comm_write_data, comm_valid);

    // Global signals
    input logic clk; // Clock signal for the CPU (50 MHz)
    input logic rst_n; // Reset signal for the CPU

    // Instruction side signals
    input logic inst_re; // Read enable signal from the CPU
    input logic [31:0] inst_addr; // Address signal from the CPU
    output logic [31:0] inst_data; // Data read for the CPU
    output logic inst_valid; // Valid signal indicating that the read/write data is valid

    // Data side signals
    input logic data_re; // Read enable signal from the CPU
    input logic data_we; // Write enable signal from the CPU
    input logic [31:0] data_addr; // Address signal from the CPU
    output logic [31:0] data_read; // Data read for the CPU
    input logic [31:0] data_write; // Data write from the CPU
    output logic data_valid; // Valid signal indicating that the read/write data is valid

    // Communicator side signals
    output logic comm_re; // Read enable signal for the communicator
    output logic comm_we; // Write enable signal for the communicator
    output logic [31:0] comm_addr; // Address signal for the communicator
    input logic [31:0] comm_read_data; // Data read from the communicator
    output logic [31:0] comm_write_data; // Data write to the communicator
    input logic comm_valid; // Valid signal indicating that the read/write data is valid

    // Create the signals for handling the requests from the caches
    logic [2:0] priori;
    logic [2:0] next_priori;

    // Create the logic for priority handling
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            priori <= 3'b001;
        end
        else begin
            priori <= next_priori;
        end
    end

    // Create the buffered storage for the requests from the caches
    logic [31:0] inst_addr_req;
    logic inst_addr_req_valid;
    logic inst_addr_req_clr;

    logic [31:0] data_addr_req;
    logic data_addr_req_valid;
    logic data_addr_req_clr;

    logic [127:0] data_write_req;
    logic [127:0] next_data_write_req;
    logic [31:0] data_write_addr_req;
    logic [31:0] next_data_write_addr_req;
    logic data_write_req_clr;
    logic data_write_req_valid;
    logic data_write_req_valid_state;
    typedef enum logic [1:0] {
        IDLE,
        STORE_1,
        STORE_2,
        STORE_3
    } data_write_req_state_t;
    data_write_req_state_t data_write_req_state, next_data_write_req_state;

    logic [2:0] valids;

    // Create the buffered storage for the requests from the caches
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            inst_addr_req <= 0;
            inst_addr_req_valid <= 0;
        end
        else if (inst_addr_req_clr) begin
            inst_addr_req_valid <= 0;
        end
        else if (inst_re) begin
            inst_addr_req <= inst_addr;
            inst_addr_req_valid <= 1;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            data_addr_req <= 0;
            data_addr_req_valid <= 0;
        end
        else if (data_addr_req_clr) begin
            data_addr_req_valid <= 0;
        end
        else if (data_re) begin
            data_addr_req <= data_addr;
            data_addr_req_valid <= 1;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            data_write_addr_req <= 0;
        end
        else if(data_we) begin
            data_write_addr_req <= data_addr;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            data_write_req <= 0;
        end
        else begin
            data_write_req <= next_data_write_req;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            data_write_req_state <= IDLE;
        end
        else begin
            data_write_req_state <= next_data_write_req_state;
        end
    end

    always_comb begin
        next_data_write_addr_req = data_write_addr_req;
        next_data_write_req = data_write_req;
        next_data_write_req_state = data_write_req_state;
        data_write_req_valid = 0;
        case(data_write_req_state)
            IDLE: begin
                next_data_write_addr_req = data_write_addr_req;
                next_data_write_req = data_write_req;
                next_data_write_req_state = data_write_req_state;
                data_write_req_valid = 0;
                if (data_we) begin
                    next_data_write_addr_req = data_addr;
                    next_data_write_req = {96'h0, data_write};
                    next_data_write_req_state = STORE_1;
                end
            end
            STORE_1: begin
                next_data_write_addr_req = data_write_addr_req;
                data_write_req_valid = 0;
                next_data_write_req = {data_write_req[95:0], data_write};
                next_data_write_req_state = STORE_2;
            end
            STORE_2: begin
                next_data_write_addr_req = data_write_addr_req;
                data_write_req_valid = 0;
                next_data_write_req = {data_write_req[95:0], data_write};
                next_data_write_req_state = STORE_3;
            end
            STORE_3: begin
                next_data_write_addr_req = data_write_addr_req;
                next_data_write_req = {data_write_req[95:0], data_write};
                data_write_req_valid = 1;
                next_data_write_req_state = IDLE;
            end
            default: begin
                next_data_write_req_state = IDLE;
            end
        endcase
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            data_write_req_valid_state <= 0;
        end
        else if (data_write_req_clr) begin
            data_write_req_valid_state <= 0;
        end
        else if (data_write_req_valid) begin
            data_write_req_valid_state <= 1;
        end
    end

    assign valids = {inst_addr_req_valid, data_addr_req_valid, data_write_req_valid_state};

    // Create the state machine for the cache bus
    typedef enum logic [3:0] {
        IDLE_BUS,
        INST_READ_START,
        INST_READ_WAIT,
        INST_READ_PROC_1,
        INST_READ_PROC_2,
        INST_READ_PROC_3,
        DATA_READ_START,
        DATA_READ_WAIT,
        DATA_READ_PROC_1,
        DATA_READ_PROC_2,
        DATA_READ_PROC_3,
        DATA_WRITE_START,
        DATA_WRITE_PROC_1,
        DATA_WRITE_PROC_2,
        DATA_WRITE_PROC_3
    } bus_state_t;
    bus_state_t state, next_state;

    // Create the state machine for the cache bus
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            state <= IDLE_BUS;
        end
        else begin
            state <= next_state;
        end
    end

    // Create the next state logic for the cache bus
    always_comb begin
        next_state = state;
        next_priori = 3'b001;
        inst_addr_req_clr = 0;
        data_addr_req_clr = 0;
        data_write_req_clr = 0;
        inst_valid = 0;
        data_valid = 0;
        comm_re = 0;
        comm_we = 0;
        comm_addr = 0;
        comm_write_data = 0;
        inst_data = 0;
        data_read = 0;
        case(state)
            IDLE_BUS: begin
                if ((valids & priori) !== 3'b000) begin
                    if (priori[0]) begin
                        next_state = DATA_WRITE_START;
                    end
                    else if (priori[1]) begin
                        next_state = DATA_READ_START;
                    end
                    else if (priori[2]) begin
                        next_state = INST_READ_START;
                    end
                end
                else if ((valids & ({priori[1:0],priori[2]})) !== 3'b000) begin
                    if (priori[0]) begin
                        next_state = DATA_READ_START;
                    end
                    else if (priori[1]) begin
                        next_state = INST_READ_START;
                    end
                    else if (priori[2]) begin
                        next_state = DATA_WRITE_START;
                    end
                end
                else if ((valids & ({priori[0], priori[2:1]})) !== 3'b000) begin
                    if (priori[0]) begin
                        next_state = INST_READ_START;
                    end
                    else if (priori[1]) begin
                        next_state = DATA_WRITE_START;
                    end
                    else if (priori[2]) begin
                        next_state = DATA_READ_START;
                    end
                end
            end
            INST_READ_START: begin
                comm_re = 1;
                comm_addr = inst_addr_req;
                next_state = INST_READ_WAIT;
            end
            INST_READ_WAIT: begin
                comm_re = 0;
                if (comm_valid) begin
                    inst_data = comm_read_data;
                    inst_valid = 1;
                    next_state = INST_READ_PROC_1;
                end
            end
            INST_READ_PROC_1: begin
                inst_data = comm_read_data;
                inst_valid = 0;
                next_state = INST_READ_PROC_2;
            end
            INST_READ_PROC_2: begin
                inst_data = comm_read_data;
                next_state = INST_READ_PROC_3;
            end
            INST_READ_PROC_3: begin
                inst_data = comm_read_data;
                inst_addr_req_clr = 1;
                next_state = IDLE_BUS;
            end
            DATA_READ_START: begin
                comm_re = 1;
                comm_addr = data_addr_req;
                next_state = DATA_READ_WAIT;
            end
            DATA_READ_WAIT: begin
                comm_re = 0;
                if (comm_valid) begin
                    data_read = comm_read_data;
                    data_valid = 1;
                    next_state = DATA_READ_PROC_1;
                end
            end
            DATA_READ_PROC_1: begin
                data_read = comm_read_data;
                data_valid = 0;
                next_state = DATA_READ_PROC_2;
            end
            DATA_READ_PROC_2: begin
                data_read = comm_read_data;
                next_state = DATA_READ_PROC_3;
            end
            DATA_READ_PROC_3: begin
                data_read = comm_read_data;
                data_addr_req_clr = 1;
                next_state = IDLE_BUS;
            end
            DATA_WRITE_START: begin
                comm_we = 1;
                comm_addr = data_write_addr_req;
                comm_write_data = data_write_req[127:96];
                next_state = DATA_WRITE_PROC_1;
            end
            DATA_WRITE_PROC_1: begin
                comm_we = 0;
                comm_addr = data_write_addr_req;
                comm_write_data = data_write_req[95:64];
                next_state = DATA_WRITE_PROC_2;
            end
            DATA_WRITE_PROC_2: begin
                comm_we = 0;
                comm_addr = data_write_addr_req;
                comm_write_data = data_write_req[63:32];
                next_state = DATA_WRITE_PROC_3;
            end
            DATA_WRITE_PROC_3: begin
                comm_we = 0;
                comm_addr = data_write_addr_req;
                comm_write_data = data_write_req[31:0];
                if (comm_valid) begin
                    data_valid = 1;
                    data_write_req_clr = 1;
                    next_state = IDLE_BUS;
                end
            end
            default: begin
                next_state = IDLE_BUS;
                inst_addr_req_clr = 1;
                data_addr_req_clr = 1;
                data_write_req_clr = 1;
            end
        endcase
    end

endmodule