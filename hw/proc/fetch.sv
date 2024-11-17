import m_rv32::*;
module fetch(next_pc_in, curr_pc_out, inst_out, update_next_pc, clk, rst_n);
    input  mem_addr_t next_pc_in;
    input  logic clk, rst_n, update_next_pc;
    output mem_addr_t curr_pc_out;
    output inst_t inst_out;

    logic [31:0] pc;
    logic halt;

    Dummy_Mem i_mem (.addr(pc), .data_in(0), .data_out(inst_out), .mr(1), .mw(0), .clk(clk), .rst_n(rst_n), .busy(), .wfunct3(3'b010));
    assign curr_pc_out = pc;

    always @(posedge clk, negedge rst_n)
        if(!rst_n)
            halt = 0;
        else if(inst_out === 32'hC0001073)
            halt = 1;
    
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            pc <= 0;
        else if(update_next_pc & ~halt)
            pc <= next_pc_in; //external source to update PC
    end
    
endmodule


module fetch_pipelined(spec_pc, next_pc_in, pc_out, inst_out, inst_out_ready, stall, override_next_pc, clk, rst_n, /*rom -->*/imem_addr, imem_data,
                       /*dram*/maddr_out, mr_out, mword_in, min_ready, inv_inst, i_hit, i_miss);
    input  mem_addr_t next_pc_in;
    input  logic clk, rst_n, override_next_pc, stall, inv_inst;
    output mem_addr_t pc_out, spec_pc;
    output inst_t inst_out;
    output logic inst_out_ready;
    output logic i_hit, i_miss;

    input logic [31:0] imem_data;
    output mem_addr_t imem_addr;

    //dram ports
    input  logic min_ready;
    input [XLEN-1:0] mword_in;
    output logic [PHYSICAL_ADDR_BITS-1:0] maddr_out;
    output logic mr_out;

    logic halt, get_next_pc, ready, rom_ready, is_rom, is_rom_read;
    logic cache_ready;

    mem_addr_t pc, next_pc, pc_read;
    logic [PHYSICAL_ADDR_BITS-1:0] cache_addr;
    logic [XLEN-1:0] icache_data;

    assign inst_out_ready = ready;
    assign pc_out = pc;
    assign spec_pc = next_pc;

    assign is_rom = {pc[31:PHYSICAL_ADDR_BITS+2], pc[PHYSICAL_ADDR_BITS+1]} === 5'b1;
    assign is_rom_read = {pc_read[31:PHYSICAL_ADDR_BITS+2], pc_read[PHYSICAL_ADDR_BITS+1]} === 5'b1;

    assign ready = (rom_ready & is_rom) | (cache_ready & ~is_rom & cache_addr === pc);

    assign pc_read = get_next_pc ? next_pc : pc; //read next in advance

    //next pc logic
    //normally, nextpc = pc + 4, if override, next_pc_in
    assign next_pc = override_next_pc ? next_pc_in : pc+4;

    //logic for whether to get next pc
    //only get next pc on ready and no stall (no override)
    //get anyways if override
    assign get_next_pc = override_next_pc | (ready & ~stall);

    //mimc single cycle ready for rom access, (always ready except first cycle after reset)
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            rom_ready <= 0;
        else
            rom_ready <= 1;
    
    mem_icache iCache(.done_addr(cache_addr), .rst_n, .clk, .data_out(icache_data), .addr(pc_read), .ready(cache_ready), 
                      .addr_out(maddr_out), .mr_out, .word_in(mword_in), .in_ready(min_ready), .en(~is_rom_read), .inv_inst, .hit(i_hit), .miss(i_miss));
    
    assign imem_addr = pc_read; //read does not change rom state, free read
    assign inst_out = is_rom ? imem_data : icache_data;

    //halt logic
    always @(posedge clk, negedge rst_n)
        if(!rst_n)
            halt = 0;
        else if(inst_out === 32'hC0001073 & get_next_pc & ~override_next_pc)
            halt = 1;
    
    //pc reg
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
             pc <= 32'h0800_0000; //start at rom place
            //  pc <= '0;
        else if(get_next_pc)
            pc <= next_pc;
    
endmodule