//only allow aligned
module Dummy_Mem_aligned(addr, data_in, data_out, mr, mw, clk, rst_n, busy, wfunct3, p2_addr, p2_data_out, p2_mr);
    parameter XLEN = 32;
	parameter ADDR_WIDTH = 16;

	localparam DEPTH = 2**(ADDR_WIDTH-2);
    
    input  logic mr, mw, clk, rst_n, p2_mr;
    input  logic[XLEN-1:0] data_in;
    input  logic[2:0] wfunct3; 
    input  logic [XLEN-1:0] addr, p2_addr;
    output busy;
    output logic[XLEN-1:0] data_out, p2_data_out;

    logic [7:0] mem_b0 [0:DEPTH-1];
	logic [7:0] mem_b1 [0:DEPTH-1];
	logic [7:0] mem_b2 [0:DEPTH-1];
	logic [7:0] mem_b3 [0:DEPTH-1];
    logic [XLEN-1:0] memout, intermediate, data_in_intr;
    logic signbit;
	logic [3:0] be;
	logic [4:0] bit_offset;

	assign bit_offset = (addr[1:0] * 8);

    assign busy = 0;
	assign data_in_intr = data_in << bit_offset;
	assign be = {(wfunct3[1]), (wfunct3[1]), (|wfunct3), 1'b1} << addr[1:0]; //shift base be to get actual be

	initial begin
		$readmemh("../proc_verification/firmware/firmware.hexb0.vh",mem_b0);
		$readmemh("../proc_verification/firmware/firmware.hexb1.vh",mem_b1);
		$readmemh("../proc_verification/firmware/firmware.hexb2.vh",mem_b2);
		$readmemh("../proc_verification/firmware/firmware.hexb3.vh",mem_b3);
	end

	//byte 0
	always @(posedge clk) begin
		if(mw & be[0])begin
			mem_b0[addr[ADDR_WIDTH-1:2]] <= data_in_intr[7:0];
			memout[7:0] <= data_in_intr[7:0];
		end
		else memout[7:0] <= mem_b0[addr[ADDR_WIDTH-1:2]];
	end
	//byte 1
	always @(posedge clk) begin
		if(mw & be[1])begin
			mem_b1[addr[ADDR_WIDTH-1:2]] <= data_in_intr[15:8];
			memout[15:8] <= data_in_intr[15:8];
		end
		else memout[15:8] <= mem_b1[addr[ADDR_WIDTH-1:2]];
	end
	//byte 2
	always @(posedge clk) begin
		if(mw & be[2])begin
			mem_b2[addr[ADDR_WIDTH-1:2]] <= data_in_intr[23:16];
			memout[23:16] <= data_in_intr[23:16];
		end
		else memout[23:16] <= mem_b2[addr[ADDR_WIDTH-1:2]];
	end
	//byte 3
	always @(posedge clk) begin
		if(mw & be[3])begin
			mem_b3[addr[ADDR_WIDTH-1:2]] <= data_in_intr[31:24];
			memout[31:24] <= data_in_intr[31:24];
		end
		else memout[31:24] <= mem_b3[addr[ADDR_WIDTH-1:2]];
	end
	//read
	assign intermediate = memout >> bit_offset;
    //sign extension [1:0] 00 LB(U), 01 LH(U), 10 LW, sign bit if there is any
    assign signbit = ~wfunct3[2] & (wfunct3[0] ? intermediate[15] : intermediate[7]);
    assign data_out = (wfunct3[1:0] === 2'b00 ? /*LB*/ {{24{signbit}}, intermediate[7:0]} : 
                           (wfunct3[1:0] === 2'b01 ? /*LH*/ {{16{signbit}}, intermediate[15:0]} : intermediate
                           ));
	
	//port 2, only 32bit ops for inst memory

	//byte 0
	always @(posedge clk) begin
		p2_data_out[7:0] <= mem_b0[p2_addr[ADDR_WIDTH-1:2]];
	end
	//byte 1
	always @(posedge clk) begin
		p2_data_out[15:8] <= mem_b1[p2_addr[ADDR_WIDTH-1:2]];
	end
	//byte 2
	always @(posedge clk) begin
		p2_data_out[23:16] <= mem_b2[p2_addr[ADDR_WIDTH-1:2]];
	end
	//byte 3
	always @(posedge clk) begin
		p2_data_out[31:24] <= mem_b3[p2_addr[ADDR_WIDTH-1:2]];
	end
    
endmodule


//allow unaligned
module Dummy_Mem_unaligned(addr, data_in, data_out, mr, mw, clk, rst_n, busy, wfunct3, p2_addr, p2_data_out, p2_mr);
    parameter XLEN = 32;
    
    input  logic mr, mw, clk, rst_n, p2_mr;
    input  logic[XLEN-1:0] data_in;
    input  logic[2:0] wfunct3; 
    input  logic [XLEN-1:0] addr, p2_addr;
    output busy;
    output logic[XLEN-1:0] data_out, p2_data_out;

    logic [7:0] mem_b0 [0:8191];
	logic [7:0] mem_b1 [0:8191];
	logic [7:0] mem_b2 [0:8191];
	logic [7:0] mem_b3 [0:8191];
    logic [XLEN-1:0] memout;
    logic signbit;

    assign busy = 0;

	initial begin
		$readmemh("../proc_verification/firmware/firmware.hexb0.vh",mem_b0);
		$readmemh("../proc_verification/firmware/firmware.hexb1.vh",mem_b1);
		$readmemh("../proc_verification/firmware/firmware.hexb2.vh",mem_b2);
		$readmemh("../proc_verification/firmware/firmware.hexb3.vh",mem_b3);
	end

	logic [12:0] addr_db0, addr_db1, addr_db2, addr_db3, addr_p1;
	logic mwb0, mwb1, mwb2, mwb3;
	logic [7:0] data_in_b0, data_in_b1, data_in_b2, data_in_b3;
	logic [7:0] data_out_b0, data_out_b1, data_out_b2, data_out_b3;
	assign addr_p1 = addr[14:2]+1;

	always_comb begin
		case(addr[1:0])
			2'b00:begin
				data_in_b0 = data_in[7:0];
				data_in_b1 = data_in[15:8];
				data_in_b2 = data_in[23:16];
				data_in_b3 = data_in[31:24];

				mwb0 = mw;
				mwb1 = mw & (|wfunct3);
				mwb2 = mw & wfunct3[1];
				mwb3 = mw & wfunct3[1];

				addr_db0 = addr[14:2];
				addr_db1 = addr[14:2];
				addr_db2 = addr[14:2];
				addr_db3 = addr[14:2];

				memout = {data_out_b3, data_out_b2, data_out_b1, data_out_b0};
			end
			2'b01:begin
				data_in_b1 = data_in[7:0];
				data_in_b2 = data_in[15:8];
				data_in_b3 = data_in[23:16];
				data_in_b0 = data_in[31:24];

				mwb1 = mw;
				mwb2 = mw & (|wfunct3);
				mwb3 = mw & wfunct3[1];
				mwb0 = mw & wfunct3[1];

				addr_db1 = addr[14:2];
				addr_db2 = addr[14:2];
				addr_db3 = addr[14:2];
				addr_db0 = addr_p1;

				memout = {data_out_b0, data_out_b3, data_out_b2, data_out_b1};
			end
			2'b10:begin
				data_in_b2 = data_in[7:0];
				data_in_b3 = data_in[15:8];
				data_in_b0 = data_in[23:16];
				data_in_b1 = data_in[31:24];

				mwb2 = mw;
				mwb3 = mw & (|wfunct3);
				mwb0 = mw & wfunct3[1];
				mwb1 = mw & wfunct3[1];

				addr_db2 = addr[14:2];
				addr_db3 = addr[14:2];
				addr_db0 = addr_p1;
				addr_db1 = addr_p1;

				memout = {data_out_b1, data_out_b0, data_out_b3, data_out_b2};
			end
			2'b11:begin
				data_in_b3 = data_in[7:0];
				data_in_b0 = data_in[15:8];
				data_in_b1 = data_in[23:16];
				data_in_b2 = data_in[31:24];

				mwb3 = mw;
				mwb0 = mw & (|wfunct3);
				mwb1 = mw & wfunct3[1];
				mwb2 = mw & wfunct3[1];

				addr_db3 = addr[14:2];
				addr_db0 = addr_p1;
				addr_db1 = addr_p1;
				addr_db2 = addr_p1;

				memout = {data_out_b2, data_out_b1, data_out_b0, data_out_b3};
			end
		endcase
	end

	//byte 0
	always @(posedge clk) begin
		if(mwb0)begin
			mem_b0[addr_db0] <= data_in_b0;
			data_out_b0 <= data_in_b0;
		end
		else data_out_b0 <= mem_b0[addr_db0];
	end
	//byte 1
	always @(posedge clk) begin
		if(mwb1)begin
			mem_b1[addr_db1] <= data_in_b1;
			data_out_b1 <= data_in_b1;
		end
		else data_out_b1 <= mem_b1[addr_db1];
	end
	//byte 2
	always @(posedge clk) begin
		if(mwb2)begin
			mem_b2[addr_db2] <= data_in_b2;
			data_out_b2 <= data_in_b2;
		end
		else data_out_b2 <= mem_b2[addr_db2];
	end
	//byte 3
	always @(posedge clk) begin
		if(mwb3)begin
			mem_b3[addr_db3] <= data_in_b3;
			data_out_b3 <= data_in_b3;
		end
		else data_out_b3 <= mem_b3[addr_db3];
	end
	
    //sign extension [1:0] 00 LB(U), 01 LH(U), 10 LW, sign bit if there is any
    assign signbit = ~wfunct3[2] & (wfunct3[0] ? memout[15] : memout[7]);
    assign data_out = (wfunct3[1:0] === 2'b00 ? /*LB*/ {{24{signbit}}, memout[7:0]} : 
                           (wfunct3[1:0] === 2'b01 ? /*LH*/ {{16{signbit}}, memout[15:0]} : memout
                           ));
	
	//port 2, read-only 32bit ops for inst memory
	//byte 0
	always @(posedge clk) begin
		p2_data_out[7:0] <= mem_b0[p2_addr[14:2]];
	end
	//byte 1
	always @(posedge clk) begin
		p2_data_out[15:8] <= mem_b1[p2_addr[14:2]];
	end
	//byte 2
	always @(posedge clk) begin
		p2_data_out[23:16] <= mem_b2[p2_addr[14:2]];
	end
	//byte 3
	always @(posedge clk) begin
		p2_data_out[31:24] <= mem_b3[p2_addr[14:2]];
	end
    
endmodule
