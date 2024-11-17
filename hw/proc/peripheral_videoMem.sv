//dual port mem
module peripheral_videoMem(clk,we,waddr,wdata, wrdata, raddr,rdata);

  input clk;
  input we;
  input [18:0] waddr;
  input [23:0] wdata;
  input [18:0] raddr;
  output reg [23:0] rdata;
  output reg [23:0] wrdata;

  logic [18:0] scaled_raddr, x, y;
  
  reg [23:0]mem[0:76799];

  assign x = raddr % 19'd640;
  assign y = raddr / 19'd640;

  assign scaled_raddr = (x[18:1] + (y[18:1] * 18'd320));
  
  // Video controller r port
  always @(posedge clk) begin
	  rdata <= mem[scaled_raddr];
  end
  
  //Host w/r port
  always @(posedge clk) begin
    if (we) begin
	    mem[waddr] <= wdata;
	    wrdata <= wdata;
    end
    else wrdata <= mem[waddr];
  end

endmodule
