//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name:    spart.sv
// Module Name:    spart 
// Project Name:   miniproject1
// Target Devices: DE1_SOC board
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module peripheral_spart(
    input clk,				// 50MHz clk
    input rst_n,			// asynch active low reset
    input iocs_n,			// active low chip select (decode address range)
    input iorw_n,			// high for read, low for write
    output tx_q_full,		// indicates transmit queue is full
    output rx_q_empty,		// indicates receive queue is empty
    input  ioaddr,		    // Read/write 1 of 4 internal 8-bit registers
    input  logic [31:0] datain,	//
    output logic [31:0] dataout,    
    output logic TX,		// UART TX line
    input  RX				// UART RX line
    );
    //ioaddr 0: T/R buffer
    //       1: control register

    logic [7:0] rxdataout; //read data
    logic [7:0] status_reg; // Status register for the SPART
    logic [12:0] DB; // The Baud rate down counters and the Baud rate divisor buffer
    logic [3:0] ptr_rd_rx, ptr_wr_rx, ptr_rd_tx, ptr_wr_tx; // The pointers for the circular queues
    logic tx_q_empty, rx_q_full;
    
    //Write to TX buffer when needed and allowed
    peripheral_spart_tx iTX(.clk, .rst_n, .DB, .ioaddr, .databus(datain[7:0]), .iocs_n, .iorw_n, .TX, .tx_q_empty, .tx_q_full,
                 .ptr_rd_tx, .ptr_wr_tx);
    //Read out RX buffer, rxdataout when allowed and needed. rxdataout is self-updated
    peripheral_spart_rx iRX(.clk, .rst_n, .DB, .ioaddr, .iocs_n, .iorw_n, .RX_raw(RX), .rxdataout, .rx_q_empty, .rx_q_full,
                 .ptr_rd_rx, .ptr_wr_rx);


    assign status_reg[7:4] = ptr_wr_tx < ptr_rd_tx ? ptr_rd_tx - ptr_wr_tx - 1 : 8 - (ptr_wr_tx - ptr_rd_tx);
    assign status_reg[3:0] = ptr_wr_rx < ptr_rd_rx ? 9 - (ptr_rd_rx - ptr_wr_rx) : (ptr_wr_rx - ptr_rd_rx);

    //read out data
    //assign databus = (~iocs_n & iorw_n) ? dataout : 32'hzz;
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n)
            dataout <= 0;
        else if(~iocs_n & iorw_n)begin  //keep readout value on read
            dataout <= ioaddr ? {4'b0, status_reg[3:0], 4'b0, status_reg[7:4], 3'b0, DB} : {24'b0, rxdataout};// 0:rx, 1:control
        end
    end
    //write global DB reg
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            DB <= 13'h01B2;
        else if((ioaddr) & ~iorw_n & ~iocs_n)
            DB <= /*13'h01B2;*/ datain[12:0];
    end
				   
endmodule
