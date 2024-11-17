import m_rv32::*;
//operate system bus, addr mapping
module sysbus(addr, wdata, re, wr, rdata,
              o_maddr, o_mwdata, o_mre, o_mwr, i_mrdata, i_mbusy,
              o_saddr, o_swdata, o_sre, o_swr, i_srdata,
              o_busy);
    parameter XLEN = 32;

    input logic [XLEN-1:0] addr, wdata, i_mrdata, i_srdata;
    input logic re, wr, i_mbusy;
    output logic o_mre, o_mwr, o_sre, o_swr, o_busy;
    output logic [XLEN-1:0] o_maddr, o_mwdata, o_saddr, o_swdata, rdata;

    //now all map to ram model

    assign o_saddr = 32'hzzzz;
    assign o_swdata = 32'hzzzz;
    assign o_sre = 1'b0;
    assign o_swr = 1'b0;

    assign o_maddr = addr;
    assign o_mwdata = wdata;
    assign o_mre = re;
    assign o_mwr = wr;
    assign o_busy = i_mbusy;

    assign rdata = i_mrdata;
endmodule

module addr_calc(rst_n, clk, init, base, off, addr_out, done_1clk, ack);
    parameter XLEN = 32;

    input logic rst_n, clk, init, ack;
    input logic [XLEN-1:0] base, off;

    output logic [XLEN-1:0] addr_out;
    output logic done_1clk;//for single cycle use this, multicycle use to supress done

    assign addr_out = base + off;

    //output done for single cycle memories
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            done_1clk <= 0;
        else if(init)
            done_1clk <= 1;
        else if(ack)
            done_1clk <= 0;

endmodule
//operate system bus, addr mapping
module sysbus_pipnodram(funct3, rst_n, clk, init, base, off, ack, done, wdata, re, wr, rdata,
         peri_r, peri_w, peri_addr, peri_wdata, peri_rdata,
/*TEST*/ imem_addr, imem_data);
    parameter XLEN = 32;
    parameter PHYSICAL_ADDR_BITS = 26;

    input logic [31:0] peri_rdata;
    output logic peri_r, peri_w;
    output logic [27:0] peri_addr; //only lower 28 bits are used for peripherals
    output logic [31:0] peri_wdata;

    input logic [XLEN-1:0] base, off, wdata;
    input logic [2:0] funct3;
    input logic re, wr, rst_n, clk, init, ack;
    output logic done;
    output logic [XLEN-1:0] rdata;

    input logic [31:0] imem_addr;
    output logic [31:0] imem_data;

    logic [XLEN-1:0] addr_out, dmem_rdata, rom_a, rom_b, ram_b;
    logic dmem_re, dmem_wr;
    logic done_1clk, done_active; //done_active selects which done signal to use

    assign peri_wdata = wdata;
    assign peri_addr = addr_out[27:0];

    //data side access
    always_comb begin
        if(addr_out[28]) begin //condition for peripheral access
            done_active = 1;
            rdata = peri_rdata;
            dmem_re = 1'b0;
            dmem_wr = 1'b0;
            peri_r = re & init; //op only lasts for one cycle
            peri_w = wr & init;
        end
        else if({addr_out[31:PHYSICAL_ADDR_BITS+2], addr_out[PHYSICAL_ADDR_BITS+1]} === 1) begin//from rom
            done_active = 1;
            rdata = rom_a;
            dmem_re = 1'b0;
            dmem_wr = 1'b0;
            peri_r = 1'b0;
            peri_w = 1'b0;
        end
        else begin //main ram access
            done_active = 1; //current memory is single clk
            rdata = dmem_rdata;
            dmem_re = re & init; //op only lasts for one cycle
            dmem_wr = wr & init;
            peri_r = 1'b0;
            peri_w = 1'b0;
        end
    end

    addr_calc addrgen(.rst_n, .clk, .init, .base, .off, .addr_out, .done_1clk, .ack);
    
    Dummy_Mem_aligned dmem(.addr(addr_out), .data_in(wdata), .data_out(dmem_rdata), .mr(dmem_re), .mw(dmem_wr), //no wr to lower addr
                   .clk, .rst_n, .busy(), .wfunct3(funct3), .p2_addr(imem_addr), .p2_data_out(ram_b), .p2_mr());//single cycle
    //rom
    dual_port_rom rom(.iaddr(addr_out), .data_out(rom_a), .clk, .rst_n, .wfunct3(funct3), .ip2_addr(imem_addr), .p2_data_out(rom_b));

    assign imem_data = ({imem_addr[31:PHYSICAL_ADDR_BITS+2], imem_addr[PHYSICAL_ADDR_BITS+1]} === 1) ? rom_b : ram_b; //now no icache. inst is comming from both dmem and rom

    //done logic. for single, follow done_1clk, for multicycle, 
    assign done = done_1clk & done_active; //&(addr_out === ? fu_done) after ack, has to be low

endmodule

//operate system bus, addr mapping
module sysbus_pipdram(funct3, rst_n, clk, init, base, off, ack, done, wdata, re, wr, rdata,
         peri_r, peri_w, peri_addr, peri_wdata, peri_rdata, imem_addr, imem_data,
         maddr_out, mr_out, mw_out, mword_in, mword_out, min_ready, inv_inst,
         d_miss, d_hit);

    input logic [31:0] peri_rdata;
    output logic peri_r, peri_w;
    output logic [27:0] peri_addr; //only lower 28 bits are used for peripherals
    output logic [31:0] peri_wdata;

    input logic [XLEN-1:0] base, off, wdata;
    input logic [2:0] funct3;
    input logic re, wr, rst_n, clk, init, ack;
    output logic done, inv_inst;
    output logic [XLEN-1:0] rdata;
    output logic d_miss, d_hit;

    input logic [31:0] imem_addr;
    output logic [31:0] imem_data;

    //dram cmds
    input logic min_ready;
    input logic [XLEN-1:0] mword_in;
    output logic [XLEN-1:0] mword_out;
    output logic [PHYSICAL_ADDR_BITS-1:0] maddr_out;
    output logic mr_out, mw_out;

    logic [XLEN-1:0] addr_out, dmem_rdata, rom_a;
    logic dmem_re, dmem_wr;
    logic done_1clk, done_active, dram_ready; //done_active selects which done signal to.idram_addr, .idram_ready use


    assign peri_wdata = wdata;
    assign peri_addr = addr_out[27:0];

    //data side access
    always_comb begin
        if(addr_out[28]) begin //condition for peripheral access
            done_active = 1;
            rdata = peri_rdata;
            dmem_re = 1'b0;
            dmem_wr = 1'b0;
            peri_r = re & init; //op only lasts for one cycle
            peri_w = wr & init;
        end
        else if({addr_out[31:PHYSICAL_ADDR_BITS+2], addr_out[PHYSICAL_ADDR_BITS+1]} === 1) begin//from rom
            done_active = 1;
            rdata = rom_a;
            dmem_re = 1'b0;
            dmem_wr = 1'b0;
            peri_r = 1'b0;
            peri_w = 1'b0;
        end
        else begin //main ram access, now from dcache
            done_active = dram_ready; //current memory is single clk
            rdata = dmem_rdata;
            dmem_re = re; //op only lasts for one cycle
            dmem_wr = wr;
            peri_r = 1'b0;
            peri_w = 1'b0;
        end
    end

    addr_calc addrgen(.rst_n, .clk, .init, .base, .off, .addr_out, .done_1clk, .ack);
    
    // Dummy_Mem_aligned dmem(.addr(addr_out), .data_in(wdata), .data_out(dmem_rdata), .mr(dmem_re), .mw(dmem_wr), //no wr to lower addr
    //                .clk, .rst_n, .busy(), .wfunct3(funct3), .p2_addr(imem_addr), .p2_data_out(ram_b), .p2_mr());//single cycle
    // cpu_direct_bus sdram_arbiter(.clk, .stall, .PC(({imem_addr[31:PHYSICAL_ADDR_BITS+2], imem_addr[PHYSICAL_ADDR_BITS+1]} === 1/*check if is a rom*/) ? 32'b0 : imem_addr), 
    //                .inst(ram_b), .ready_inst(idram_ready), .inst_addr(idram_addr),
    //                .data_addr(addr_out), .data_re(dmem_re), .data_we(dmem_wr), .data_read(dmem_rdata), .data_write(wdata), .data_ready(dram_ready), .data_ack(ack),
    //                .re_CPU, .we_CPU, .addr_CPU, .data_read_CPU, .data_write_CPU, .valid_CPU);
    
    mem_dcache_intf #(.WORD_BITS(4), .SET_BITS(10))
    dcache(.wfunct3(funct3), .rst_n, .clk, .data_in(wdata), .data_out(dmem_rdata), .we(dmem_wr), .re(dmem_re), .init(init & (dmem_wr|dmem_re)), 
           .addr(addr_out), .ready(dram_ready), .ack, .maddr_out, .mr_out, .mw_out, .mword_in, .mword_out, .min_ready, .inv_inst, .hit(d_hit), .miss(d_miss));
    //rom
    dual_port_rom #(.BANK0("../firmwarehex/firmware.hexb0.vh"), .BANK1("../firmwarehex/firmware.hexb1.vh"),
                    .BANK2("../firmwarehex/firmware.hexb2.vh"), .BANK3("../firmwarehex/firmware.hexb3.vh"))
    rom(.iaddr(addr_out), .data_out(rom_a), .clk, .rst_n, .wfunct3(funct3), .ip2_addr(imem_addr), .p2_data_out(imem_data));

    //done logic. for single, follow done_1clk, for multicycle, 
    assign done = done_1clk & done_active; //&(addr_out === ? fu_done) after ack, has to be low

endmodule