//only allow aligned
module Dummy_Mem(addr, data_in, data_out, mr, mw, clk, rst_n, busy, wfunct3);
    parameter XLEN = 32;
    
    input  logic mr, mw, clk, rst_n;
    input  logic[XLEN-1:0] data_in;
    input  logic[2:0] wfunct3; 
    input  logic [XLEN-1:0] addr;
    output busy;
    output logic[XLEN-1:0] data_out;

    logic [(XLEN/8)-1:0][7:0] mem [0:8191];
    logic [XLEN-1:0] memout;
    logic signbit;
    /*
    always_comb begin
        casez(wfunct3)
            3'b000: data_in = {mem[addr[17:5]][31:8], data_in_raw[7:0]};//SB
            3'b001: data_in = {mem[addr[17:5]][31:16], data_in_raw[15:0]};//SH
            3'b010: data_in = data_in_raw; //SW
            default: data_in = 'x;
        endcase
    end*/
    assign busy = 0;

    always @(posedge clk) begin
        if(mw) begin//byte enable
			case(addr[1:0])
				2'b00:begin
					mem[addr[14:2]][0] = data_in[7:0]; //SB, SH, SW
					if(|wfunct3) mem[addr[14:2]][1] = data_in[15:8]; //SH, SW
					if(wfunct3[1]) {mem[addr[14:2]][3], mem[addr[14:2]][2]} = data_in[31:16];
				end
				2'b01: begin
					mem[addr[14:2]][1] = data_in[7:0]; //SB, SH, SW
					if(|wfunct3) mem[addr[14:2]][2] = data_in[15:8]; //SH, SW
					if(wfunct3[1]) {mem[addr[14:2]+1][0], mem[addr[14:2]][3]} = data_in[31:16];
				end
				2'b10: begin
					mem[addr[14:2]][2] = data_in[7:0]; //SB, SH, SW
					if(|wfunct3) mem[addr[14:2]][3] = data_in[15:8]; //SH, SW
					if(wfunct3[1]) {mem[addr[14:2]+1][1], mem[addr[14:2]+1][0]} = data_in[31:16];
				end
				2'b11:begin
					mem[addr[14:2]][3] = data_in[7:0]; //SB, SH, SW
					if(|wfunct3) mem[addr[14:2]+1][0] = data_in[15:8]; //SH, SW
					if(wfunct3[1]) {mem[addr[14:2]+1][2], mem[addr[14:2]+1][1]} = data_in[31:16];
				end
			endcase
        end
    end
	//unaligned read
	always @(posedge clk)begin
		if(mr) case(addr[1:0])
			2'b00: memout <= mem[addr[14:2]];
			2'b01: memout <= {mem[addr[14:2]+1][0], mem[addr[14:2]][3:1]};
			2'b10: memout <= {mem[addr[14:2]+1][1:0], mem[addr[14:2]][3:2]};
			2'b11: memout <= {mem[addr[14:2]+1][2:0], mem[addr[14:2]][3]};
		endcase
	end
    //sign extension [1:0] 00 LB(U), 01 LH(U), 10 LW, sign bit if there is any
    assign signbit = ~wfunct3[2] & (wfunct3[0] ? memout[15] : memout[7]);
    assign data_out = (wfunct3[1:0] === 2'b00 ? /*LB*/ {{24{signbit}}, memout[7:0]} : 
                           (wfunct3[1:0] === 2'b01 ? /*LH*/ {{16{signbit}}, memout[15:0]} : memout
                           ));
    
endmodule
