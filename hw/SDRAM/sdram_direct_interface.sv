/*
 * File name: sdram_interface.sv
 * File Type: SystemVerilog Source
 * Module name: sdram_direct_interface(clk, re, we, addr, data_read, data_write, valid, done, CLK, SA, BA, CS_N, CKE, RAS_N,
 *                                     CAS_N, WE_N, DQM, DQ);
 * Testbench: NONE
 * Author: Daniel Zhao
 * Date: 04/09/2024
 * Description: This module contains an interface to the SDRAM with the specific parameters defined in SDRAM_params. The
 * module instantiates the SDRAM controller and outputs the bus signals to the SDRAM. This module could allow a direct 
 * communication with the CPU requirement of byte-sized data. 
 * References: https://github.com/hdl-util/sdram-controller
 * Dependent files: sdram_controller.sv, SDRAM_params.sv
 */
import SDRAM_params::*; // Import the SDRAM parameters

module sdram_direct_interface(clk, re, we, addr, data_read, data_write, valid, done, CLK, SA, BA, CS_N, CKE, RAS_N, CAS_N, WE_N, DQM, DQ);

    // Global signals
    input wire clk; // Clock signal for the SDRAM (100MHz)

    // Control signals
    input logic re; // Read enable signal
    input logic we; // Write enable signal
    input logic [USER_ADDRESS_WIDTH-1:0] addr; // Address signal
    output logic [DATA_WIDTH-1:0] data_read; // Data read from SDRAM
    input logic [DATA_WIDTH-1:0] data_write; // Data write to SDRAM
    output logic valid; // Valid signal indicating that the read data is valid
    output logic done; // Done signal indicating that the write operation is complete

    // SDRAM bus signals
    output wire CLK; // Clock signal
    output wire [CHIP_ADDRESS_WIDTH-1:0] SA; // Chip select address signal
    output wire [BANK_ADDRESS_WIDTH-1:0] BA; // Bank address signal
    output wire CS_N; // Chip select signal
    output wire CKE; // Clock enable signal
    output wire RAS_N; // Row address strobe signal
    output wire CAS_N; // Column address strobe signal
    output wire WE_N; // Write enable signal
    output wire [DQM_WIDTH-1:0] DQM; // Data mask signal
    inout wire [DATA_WIDTH-1:0] DQ; // Data signal

    // Command signals
    logic [1:0] command; // Command signal

    // Assign the command signal based on the read and write signals
    assign command = {re, we};

    // Create the instance of SDRAM controller
    sdram_controller #(
        .CLK_RATE(RATE),
        .READ_BURST_LENGTH(2),
        .WRITE_BURST(WRITE_BURST),
        .BANK_ADDRESS_WIDTH(BANK_ADDRESS_WIDTH),
        .ROW_ADDRESS_WIDTH(ROW_ADDRESS_WIDTH),
        .COLUMN_ADDRESS_WIDTH(COLUMN_ADDRESS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DQM_WIDTH(DQM_WIDTH),
        .CAS_LATENCY(CAS_LATENCY),
        .ROW_CYCLE_TIME(ROW_CYCLE_TIME),
        .RAS_TO_CAS_DELAY(RAS_TO_CAS_DELAY),
        .PRECHARGE_TO_REFRESH_OR_ROW_ACTIVATE_SAME_BANK_TIME(PRECHARGE_TO_REFRESH_OR_ROW_ACTIVATE_SAME_BANK_TIME),
        .ROW_ACTIVATE_TO_ROW_ACTIVATE_DIFFERENT_BANK_TIME(ROW_ACTIVATE_TO_ROW_ACTIVATE_DIFFERENT_BANK_TIME),
        .ROW_ACTIVATE_TO_PRECHARGE_SAME_BANK_TIME(ROW_ACTIVATE_TO_PRECHARGE_SAME_BANK_TIME),
        .MINIMUM_STABLE_CONDITION_TIME(MINIMUM_STABLE_CONDITION_TIME),
        .MODE_REGISTER_SET_CYCLE_TIME(MODE_REGISTER_SET_CYCLE_TIME),
        .WRITE_RECOVERY_TIME(WRITE_RECOVERY_TIME),
        .AVERAGE_REFRESH_INTERVAL_TIME(AVERAGE_REFRESH_INTERVAL_TIME)
    ) isdram_controller (
        .clk(clk),
        .command(command),
        .data_address(addr),
        .data_write(data_write),
        .data_read(data_read),
        .data_read_valid(valid),
        .data_write_done(done),
        .clock(CLK),
        .clock_enable(CKE),
        .bank_activate(BA),
        .address(SA),
        .chip_select(CS_N),
        .row_address_strobe(RAS_N),
        .column_address_strobe(CAS_N),
        .write_enable(WE_N),
        .dqm(DQM),
        .dq(DQ)
    );

endmodule