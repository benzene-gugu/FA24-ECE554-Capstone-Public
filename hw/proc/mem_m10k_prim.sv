import m_rv32::*;
module mem_cacheword_benable
#(
    parameter int
	WORD_ADDRESS_WIDTH = 11
)
(word_addr, be, data_in, we, data_out, clk, rst_n);
    input we, clk, rst_n;
    input [WORD_ADDRESS_WIDTH-1:0] word_addr;
    input [3:0] be;
    input [4*8-1:0] data_in;
    output [4*8-1:0] data_out;

    localparam RAM_DEPTH = 1 << WORD_ADDRESS_WIDTH;

    logic [7:0] ram_b0[0:RAM_DEPTH-1];
    logic [7:0] ram_b1[0:RAM_DEPTH-1];
    logic [7:0] ram_b2[0:RAM_DEPTH-1];
    logic [7:0] ram_b3[0:RAM_DEPTH-1];

	logic [WORD_ADDRESS_WIDTH-1:0] read_addr0, read_addr1, read_addr2, read_addr3;


    always @(posedge clk) begin
		if(we & be[0])
			ram_b0[word_addr] <= data_in[7:0];
		read_addr0 <= word_addr;
	end
	assign data_out[7:0] = ram_b0[read_addr0];

	always @(posedge clk) begin
		if(we & be[1])
			ram_b1[word_addr] <= data_in[15:8];
		read_addr1 = word_addr;
	end
	assign data_out[15:8] = ram_b1[read_addr1];
	
	always @(posedge clk) begin
		if(we & be[2])
			ram_b2[word_addr] <= data_in[23:16];
		read_addr2 = word_addr;
	end
	assign data_out[23:16] = ram_b2[read_addr2];
	
	always @(posedge clk) begin
		if(we & be[3])
			ram_b3[word_addr] <= data_in[31:24];
		read_addr3 = word_addr;
	end
	assign data_out[31:24] = ram_b3[read_addr3];

endmodule

module mem_fixlen_ram
#(
    parameter int
	ADDRESS_WIDTH = 11,
	DATA_WIDTH = 9
)
(addr, data_in, we, data_out, clk, rst_n);
    input  we, clk, rst_n;
    input  [ADDRESS_WIDTH-1:0] addr;
    input  [DATA_WIDTH-1:0] data_in;
    output [DATA_WIDTH-1:0] data_out;

    localparam RAM_DEPTH = 1 << ADDRESS_WIDTH;

    logic [DATA_WIDTH-1:0] ram[0:RAM_DEPTH-1];

	logic [ADDRESS_WIDTH-1:0] read_addr;


    always @(posedge clk) begin
		if(we)
			ram[addr] <= data_in;
		read_addr <= addr;
	end
	assign data_out = ram[read_addr];
endmodule


module dual_port_rom(iaddr, data_out, clk, rst_n, wfunct3, ip2_addr, p2_data_out);
	parameter BANK0 = "../firmwarehex/firmware/firmware.hexb0.vh";
	parameter BANK1 = "../firmwarehex/firmware/firmware.hexb1.vh";
	parameter BANK2 = "../firmwarehex/firmware/firmware.hexb2.vh";
	parameter BANK3 = "../firmwarehex/firmware/firmware.hexb3.vh";
	parameter ADDRESS_WIDTH = 12;

	localparam MEM_DEPTH = 2**(ADDRESS_WIDTH-2);
    
    input  logic clk, rst_n;
    input  logic[2:0] wfunct3; 
    input  logic [31:0] iaddr, ip2_addr;
    output logic[XLEN-1:0] data_out, p2_data_out;

	logic [ADDRESS_WIDTH-1:0] addr, p2_addr;
	assign addr = iaddr[ADDRESS_WIDTH-1:0];
	assign p2_addr = ip2_addr[ADDRESS_WIDTH-1:0];

    logic [7:0] mem_b0 [0:MEM_DEPTH-1];
	logic [7:0] mem_b1 [0:MEM_DEPTH-1];
	logic [7:0] mem_b2 [0:MEM_DEPTH-1];
	logic [7:0] mem_b3 [0:MEM_DEPTH-1];
    logic [XLEN-1:0] memout;
    logic signbit;

	initial begin
		$readmemh(BANK0, mem_b0);
		$readmemh(BANK1, mem_b1);
		$readmemh(BANK2 ,mem_b2);
		$readmemh(BANK3 ,mem_b3);
	end

	logic [ADDRESS_WIDTH-1:0] addr_db0, addr_db1, addr_db2, addr_db3, addr_p1;
	logic [7:0] data_out_b0, data_out_b1, data_out_b2, data_out_b3;
	assign addr_p1 = addr[ADDRESS_WIDTH-1:2]+1'b1;

	always_comb begin
		case(addr[1:0])
			2'b00:begin
				addr_db0 = addr[ADDRESS_WIDTH-1:2];
				addr_db1 = addr[ADDRESS_WIDTH-1:2];
				addr_db2 = addr[ADDRESS_WIDTH-1:2];
				addr_db3 = addr[ADDRESS_WIDTH-1:2];

				memout = {data_out_b3, data_out_b2, data_out_b1, data_out_b0};
			end
			2'b01:begin
				addr_db1 = addr[ADDRESS_WIDTH-1:2];
				addr_db2 = addr[ADDRESS_WIDTH-1:2];
				addr_db3 = addr[ADDRESS_WIDTH-1:2];
				addr_db0 = addr_p1;

				memout = {data_out_b0, data_out_b3, data_out_b2, data_out_b1};
			end
			2'b10:begin
				addr_db2 = addr[ADDRESS_WIDTH-1:2];
				addr_db3 = addr[ADDRESS_WIDTH-1:2];
				addr_db0 = addr_p1;
				addr_db1 = addr_p1;

				memout = {data_out_b1, data_out_b0, data_out_b3, data_out_b2};
			end
			2'b11:begin
				addr_db3 = addr[ADDRESS_WIDTH-1:2];
				addr_db0 = addr_p1;
				addr_db1 = addr_p1;
				addr_db2 = addr_p1;

				memout = {data_out_b2, data_out_b1, data_out_b0, data_out_b3};
			end
		endcase
	end

	//byte 0
	always @(posedge clk) begin
		data_out_b0 <= mem_b0[addr_db0];
		p2_data_out[7:0] <= mem_b0[p2_addr[ADDRESS_WIDTH-1:2]];
	end
	//byte 1
	always @(posedge clk) begin
		data_out_b1 <= mem_b1[addr_db1];
		p2_data_out[15:8] <= mem_b1[p2_addr[ADDRESS_WIDTH-1:2]];
	end
	//byte 2
	always @(posedge clk) begin
		data_out_b2 <= mem_b2[addr_db2];
		p2_data_out[23:16] <= mem_b2[p2_addr[ADDRESS_WIDTH-1:2]];
	end
	//byte 3
	always @(posedge clk) begin
		data_out_b3 <= mem_b3[addr_db3];
		p2_data_out[31:24] <= mem_b3[p2_addr[ADDRESS_WIDTH-1:2]];
	end
	
    //sign extension [1:0] 00 LB(U), 01 LH(U), 10 LW, sign bit if there is any
    assign signbit = ~wfunct3[2] & (wfunct3[0] ? memout[15] : memout[7]);
    assign data_out = (wfunct3[1:0] === 2'b00 ? /*LB*/ {{24{signbit}}, memout[7:0]} : 
                           (wfunct3[1:0] === 2'b01 ? /*LH*/ {{16{signbit}}, memout[15:0]} : memout
                           ));
    
endmodule