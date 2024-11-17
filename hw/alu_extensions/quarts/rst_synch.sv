/*
 * Synchronizes reset signal to negative edge of clock
 */
module rst_synch(RST_n, clk, rst_n);

	input wire RST_n, clk; // asynch reset signal, clock
	output reg rst_n; // synch reset signal
	
	//intermediate signal
	reg inter;
	
	always @(negedge clk, negedge RST_n) begin
		if(!RST_n) begin
			inter <= 1'b0;
			rst_n <= 1'b0;
		end else begin
			inter <= 1'b1;
			rst_n <= inter;
		end
	end
	


endmodule