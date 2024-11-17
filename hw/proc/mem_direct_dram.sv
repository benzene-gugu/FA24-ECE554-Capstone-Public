module mem_direct_dram(addr, data_in, data_out, mr, mw, clk, rst_n, busy, wfunct3, p2_addr, p2_data_out, p2_mr);
    parameter XLEN = 32;
    parameter PHYSICAL_ADDR_BITS = 26;
    
    input  logic mr, mw, clk, rst_n, p2_mr;
    input  logic[XLEN-1:0] data_in;
    input  logic[2:0] wfunct3; 
    input  logic [XLEN-1:0] addr, p2_addr;
    output busy;
    output logic[XLEN-1:0] data_out, p2_data_out;


endmodule

