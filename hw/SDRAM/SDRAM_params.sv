/*
 * File name: SDRAM_params.sv
 * File Type: SystemVerilog Package
 * Parameters: 
 *  - RATE = 100M The rate at which the SDRAM operates
 *  - READ_BURST = 8 The number of data to be read in a burst measured in half-words (16-bit)
 *  - WRITE_BURST = 1 Enable write burst mode
 *  - BANK_ADDRESS_WIDTH = 2 The number of bits used to address the bank
 *  - ROW_ADDRESS_WIDTH = 13 The number of bits used to address the row
 *  - COLUMN_ADDRESS_WIDTH = 10 The number of bits used to address the column
 *  - DATA_WIDTH = 16 The width of the data bus
 *  - DQM_WIDTH = 2 The width of the data mask bus
 *  - CAS_LATENCY = 2 The number of cycles between the read command and the data being available
 *  - ROW_CYCLE_TIME = 60n The time it takes to read a row
 *  - RAS_TO_CAS_DELAY = 15n The time it takes to read a column after a row has been read
 *  - PRECHARGE_TO_REFRESH_OR_ROW_ACTIVATE_SAME_BANK_TIME = 15n The time it takes to precharge a bank
 *  - ROW_ACTIVATE_TO_ROW_ACTIVATE_DIFFERENT_BANK_TIME = 14n The time it takes to activate a row in a different bank
 *  - ROW_ACTIVATE_TO_PRECHARGE_SAME_BANK_TIME = 37n The time it takes to precharge a row
 *  - MINIMUM_STABLE_CONDITION_TIME = 100u The time it takes for the SDRAM to become stable on power up
 *  - MODE_REGISTER_SET_CYCLE_TIME = 2/RATE The time it takes to set the mode register
 *  - WRITE_RECOVERY_TIME = 2/RATE The time it takes to recover from a write operation
 *  - AVERAGE_REFRESH_INTERVAL_TIME = 64m/8192 The time it takes to refresh the SDRAM
 * Author: Daniel Zhao
 * Date: 04/09/2024
 * Description: This module contains definition for the structure of the SDRAM interface signals. 
 * Dependent files: NONE
 */
package SDRAM_params;
    parameter RATE = 100000000; // The rate at which the SDRAM operates
    parameter READ_BURST = 8; // The number of data to be read in a burst measured in half-words (16-bit)
    parameter WRITE_BURST = 1; // Enable write burst mode
    parameter BANK_ADDRESS_WIDTH = 2; // The number of bits used to address the bank
    parameter ROW_ADDRESS_WIDTH = 13; // The number of bits used to address the row
    parameter COLUMN_ADDRESS_WIDTH = 10; // The number of bits used to address the column
    parameter DATA_WIDTH = 16; // The width of the data bus
    parameter DQM_WIDTH = 2; // The width of the data mask bus
    parameter CAS_LATENCY = 3; // The number of cycles between the read command and the data being available
    parameter ROW_CYCLE_TIME = 60E-9; // The time it takes to read a row
    parameter RAS_TO_CAS_DELAY = 30E-9; // The time it takes to read a column after a row has been read
    parameter PRECHARGE_TO_REFRESH_OR_ROW_ACTIVATE_SAME_BANK_TIME = 20E-9; // The time it takes to precharge a bank
    parameter ROW_ACTIVATE_TO_ROW_ACTIVATE_DIFFERENT_BANK_TIME = 70E-9; // The time it takes to activate a row in a different bank
    parameter ROW_ACTIVATE_TO_PRECHARGE_SAME_BANK_TIME = 40E-9; // The time it takes to precharge a row
    parameter MINIMUM_STABLE_CONDITION_TIME = 24000E-8; // The time it takes for the SDRAM to become stable on power up
    parameter MODE_REGISTER_SET_CYCLE_TIME = 3E-8; // The time it takes to set the mode register
    parameter WRITE_RECOVERY_TIME = 10E-8; // The time it takes to recover from a write operation
    parameter AVERAGE_REFRESH_INTERVAL_TIME = 3E-6; // The time it takes to refresh the SDRAM

    // Non-public parameters
    parameter CHIP_ADDRESS_WIDTH = 13; // The number of bits used to address the chip
    parameter USER_ADDRESS_WIDTH = 25; // The number of bits used to address the user
endpackage