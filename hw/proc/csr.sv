import m_rv32::*;
module csr(clk, rst_n, csr_addr, csr_out, inst_ret, branch_miss,
           i_hit, i_miss, d_hit, d_miss);
    input logic clk, rst_n, inst_ret, branch_miss;
    input logic i_hit, i_miss, d_hit, d_miss;
    input logic [11:0] csr_addr;
    output logic [31:0] csr_out;

    logic [63:0] cycle_ctr, inst_ret_ctr, i_hit_ctr, i_miss_ctr, d_hit_ctr, d_miss_ctr;

    //cycle counter
    always_ff @(posedge clk, negedge rst_n)
        if(~rst_n)
            cycle_ctr <= '0;
        else
            cycle_ctr <= cycle_ctr + 1;
    
    //inst ret counter
    always_ff @(posedge clk, negedge rst_n)
        if(~rst_n)
            inst_ret_ctr <= '0;
        else if(inst_ret)
            inst_ret_ctr <= inst_ret_ctr + 1;
    
    always_ff @(posedge clk, negedge rst_n)
        if(~rst_n)
            i_hit_ctr <= '0;
        else if(i_hit)
            i_hit_ctr <= i_hit_ctr + 1;
    always_ff @(posedge clk, negedge rst_n)
        if(~rst_n)
            i_miss_ctr <= '0;
        else if(i_miss)
            i_miss_ctr <= i_miss_ctr + 1;
    
    always_ff @(posedge clk, negedge rst_n)
        if(~rst_n)
            d_hit_ctr <= '0;
        else if(d_hit)
            d_hit_ctr <= d_hit_ctr + 1;
    always_ff @(posedge clk, negedge rst_n)
        if(~rst_n)
            d_miss_ctr <= '0;
        else if(d_miss)
            d_miss_ctr <= d_miss_ctr + 1;
    
    always_comb begin
        case (csr_addr)
            default: csr_out = cycle_ctr[31:0];
            12'hc00: csr_out = cycle_ctr[31:0];
            12'hc02: csr_out = inst_ret_ctr[31:0];
            12'hc03: csr_out = i_hit_ctr[31:0];
            12'hc04: csr_out = i_miss_ctr[31:0];
            12'hc05: csr_out = d_hit_ctr[31:0];
            12'hc06: csr_out = d_miss_ctr[31:0];

            12'hc80: csr_out = cycle_ctr[63:32];
            12'hc82: csr_out = inst_ret_ctr[63:32];
            12'hc83: csr_out = i_hit_ctr[63:32];
            12'hc84: csr_out = i_miss_ctr[63:32];
            12'hc85: csr_out = d_hit_ctr[63:32];
            12'hc86: csr_out = d_miss_ctr[63:32];
        endcase
    end

endmodule