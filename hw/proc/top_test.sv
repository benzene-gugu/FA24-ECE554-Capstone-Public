import m_rv32::*;
//=======================================================
//  This code is generated by Terasic System Builder
//=======================================================
import SDRAM_params::*; // Import the SDRAM parameters
module test_top(

		//////////// ADC //////////
		output                      ADC_CONVST,
		output                      ADC_DIN,
		input                       ADC_DOUT,
		output                      ADC_SCLK,

		//////////// Audio //////////
		input                       AUD_ADCDAT,
		inout                       AUD_ADCLRCK,
		inout                       AUD_BCLK,
		output                      AUD_DACDAT,
		inout                       AUD_DACLRCK,
		output                      AUD_XCK,

		//////////// CLOCK //////////
		input                       REF_CLK,

		//////////// SDRAM //////////
		output          [12:0]      DRAM_ADDR,
		output           [1:0]      DRAM_BA,
		output                      DRAM_CAS_N,
		output                      DRAM_CKE,
		output                      DRAM_CLK,
		output                      DRAM_CS_N,
		inout           [15:0]      DRAM_DQ,
		output                      DRAM_LDQM,
		output                      DRAM_RAS_N,
		output                      DRAM_UDQM,
		output                      DRAM_WE_N,

		//////////// I2C for Audio and Video-In //////////
		output                      FPGA_I2C_SCLK,
		inout                       FPGA_I2C_SDAT,

		//////////// SEG7 //////////
		output           [6:0]      HEX0,
		output           [6:0]      HEX1,
		output           [6:0]      HEX2,
		output           [6:0]      HEX3,
		output           [6:0]      HEX4,
		output           [6:0]      HEX5,

		//////////// IR //////////
		input                       IRDA_RXD,
		output                      IRDA_TXD,

		//////////// KEY //////////
		input            [3:1]      KEY, //KEY 0 for reset
		input                       RST_n,

		//////////// LED //////////
		output           [9:0]      LEDR,

		//////////// PS2 //////////
		inout                       PS2_CLK,
		inout                       PS2_CLK2,
		inout                       PS2_DAT,
		inout                       PS2_DAT2,

		//////////// SW //////////
		input            [9:0]      SW,

		//////////// VGA //////////
		output                      VGA_BLANK_N,
		output           [7:0]      VGA_B,
		output                      VGA_CLK,
		output           [7:0]      VGA_G,
		output                      VGA_HS,
		output           [7:0]      VGA_R,
		output                      VGA_SYNC_N,
		output                      VGA_VS,
		input                       RX,
		output                      TX
	);
	logic clk, rst_n, pll_locked, clk100m;

	logic peri_w, peri_r;
	logic [31:0] peri_rdata, peri_wdata;
	logic [27:0] peri_addr;

	//VGA related signals
	wire [9:0] xpix;                    // current X coordinate of VGA
	wire [8:0] ypix;                    // current Y coordinate of VGA
	assign clk = clk100m;

	logic [USER_ADDRESS_WIDTH-1:0] addr = 0;

	//===================
	//50MHz and 25MHz VGA PLL
	//===================
	PLLsys_vga iPLL(.refclk(REF_CLK), .rst(~RST_n), .outclk_0(), .outclk_1(VGA_CLK), .outclk_2(clk100m), .locked(pll_locked));
	//===================
	//reset
	//===================
	rst_synch iRST(.clk(clk100m),.RST_n(RST_n), .pll_locked, .rst_n(rst_n));

	logic [1:0] command = 2'd0;
	logic [15:0] data_write = 16'd0, data_read;
	logic data_read_valid, data_write_done;
	

	//enum logic[] {} name

	logic no_more_writes = 1'd0;
	logic [7:0] countdown = 3'd0;


	always @(posedge clk)
	begin
  	if (command == 2'd0 && !no_more_writes)
  	begin
    	command <= 2'd1;
    	countdown <= 3'd7;
    	data_write <= addr[USER_ADDRESS_WIDTH-1:0];
  	end
  	else if (command == 2'd1 && data_write_done)
  	begin
    	if (countdown == 3'd0)
      		command <= 2'd0;
    	else
      		countdown <= countdown - 1'd1;
    	addr <= 16'(addr + 1'd1);
    	data_write <= 16'(addr + 1'd1);
		if (16'(addr + 1'd1) == 16'd0)
      		no_more_writes <= 1'b1;
  	end
  	else if (command == 2'd2 && data_read_valid)
  	begin
    	if (countdown == 3'd0)
    	begin
      		command <= 2'd0;
    	end
    	else
      		countdown <= countdown - 1'd1;
    	addr <= 22'(addr + 1'd1);
		if(22'(addr+1'd1) == 22'd0)
			no_more_writes <= 1'd0;
  	end
	else if (command == 2'd0 && no_more_writes)
	begin
		command <= 2'd2;
		countdown <= 3'd7;
	end
end


endmodule
