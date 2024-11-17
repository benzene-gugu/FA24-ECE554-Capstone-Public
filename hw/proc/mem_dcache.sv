import m_rv32::*;
module mem_dcache_intf (wfunct3, rst_n, clk, data_in, data_out, we, re, init, addr, ready, maddr_out, mr_out, mw_out, mword_in, mword_out, min_ready, ack, inv_inst, 
                        hit, miss);
    parameter WORD_BITS = 4; //16 words
    parameter SET_BITS = 10; //1k sets

    input logic rst_n, clk, min_ready, we, re, ack, init;
    input [XLEN-1:0] data_in, addr, mword_in;
    input [2:0] wfunct3;
    output [XLEN-1:0] data_out, mword_out;
    output logic ready, mr_out, mw_out, inv_inst;
    output [PHYSICAL_ADDR_BITS-1:0] maddr_out;
    output logic hit, miss;

    logic [3:0] be_in;
    logic [4:0] bit_offset;
    logic signbit;

    logic [XLEN-1:0] memout, intermediate, data_in_intr;

    assign bit_offset = (addr[1:0] * 8);
    assign data_in_intr = data_in << bit_offset;
    assign be_in = {(wfunct3[1]), (wfunct3[1]), (|wfunct3), 1'b1} << addr[1:0]; //shift base be to get actual be

    mem_dcache #(.WORD_BITS(WORD_BITS), .SET_BITS(SET_BITS))
    dcache(.be_in, .rst_n, .clk, .data_in(data_in_intr), .data_out(memout), .we, .re, .init, .hit, .miss,
           .addr, .ready, .maddr_out, .mr_out, .mw_out, .mword_in, .mword_out, .min_ready, .ack, .inv_inst);

    assign intermediate = memout >> bit_offset;
    assign signbit = ~wfunct3[2] & (wfunct3[0] ? intermediate[15] : intermediate[7]);
    assign data_out = (wfunct3[1:0] === 2'b00 ? /*LB*/ {{24{signbit}}, intermediate[7:0]} : 
                           (wfunct3[1:0] === 2'b01 ? /*LH*/ {{16{signbit}}, intermediate[15:0]} : intermediate
                           ));
endmodule
/*
mr_out high for one cycle to send a memory read command. Once in_ready is issued externally,
word_in will be load to the cache.
we, re are valid until done operation
all transaction to memory is word based.
*/
module mem_dcache (be_in, rst_n, clk, data_in, data_out, we, re, init, addr, ready, maddr_out, mr_out, mw_out, mword_in, mword_out, min_ready, ack, inv_inst, hit, miss); //defaults to 128K+4k
    parameter WORD_BITS = 4; //16 words
    parameter SET_BITS = 8; //2k sets
    
    localparam TAG_BITS = PHYSICAL_ADDR_BITS - WORD_BITS - SET_BITS - 2;
    localparam LINE_SIZE = 2**WORD_BITS;
    localparam SET_SIZE = 2**SET_BITS;

    input logic rst_n, clk, min_ready, we, re, ack, init;
    input logic [3:0] be_in;
    input [XLEN-1:0] data_in, addr, mword_in;
    output [XLEN-1:0] data_out, mword_out;
    output logic ready, mr_out, mw_out, inv_inst;
    output [PHYSICAL_ADDR_BITS-1:0] maddr_out;
    output logic hit, miss;


    logic [SET_SIZE-1:0] valid0, dirty0;
    logic set_valid, set_dirty, reset_valid, reset_dirty, match, reset_clk_ctr;
    logic [3:0] be;

    logic working, tag_we, word_we, nxt_word, wb;
    logic [SET_BITS-1:0] in_set;
    logic [TAG_BITS-1:0] in_tag, tag_read;
    logic [WORD_BITS-1:0] in_word, working_word;

    logic [LINE_SIZE-1:0][XLEN-1:0]line_out;
    logic [4:0] clk_ctr;

    always_ff @(posedge clk, negedge rst_n)
        if(~rst_n)
            clk_ctr <= '0;
        else if(reset_clk_ctr)
            clk_ctr <= '0;
        else
            clk_ctr <= clk_ctr + 1;

    assign be = working ? '1 : be_in;

    assign {in_tag, in_set, in_word} = addr[PHYSICAL_ADDR_BITS-1:2]; //addr stays the same before done

    assign match = valid0[in_set] & (tag_read === in_tag);

    assign maddr_out = {wb ? tag_read : in_tag, in_set, working_word, 2'b00}; //dram acc is always through working word
    assign data_out = line_out[in_word];
    assign mword_out = line_out[working_word];

    //dirty
    always_ff @(posedge clk, negedge rst_n)
        if(~rst_n)
            dirty0 <= '0;
        else if(set_dirty)
            dirty0[in_set] <= 1'b1;
        else if(reset_dirty)
            dirty0[in_set] <= 1'b0;
    //valid
    always_ff @(posedge clk, negedge rst_n)
        if(~rst_n)
            valid0 <= '0;
        else if(set_valid)
            valid0[in_set] <= 1'b1;
        else if(reset_valid)
            valid0[in_set] <= 1'b0;
    //tag
    mem_fixlen_ram #(.ADDRESS_WIDTH(SET_BITS), .DATA_WIDTH(TAG_BITS)) tag_mem(.addr(in_set), .data_in(in_tag), .we(tag_we), .data_out(tag_read), .clk, .rst_n);

    //data
    genvar j;
    generate
        for(j = 0; j < LINE_SIZE; ++j) begin: GENDATA_LINE
            mem_cacheword_benable #(.WORD_ADDRESS_WIDTH(SET_BITS)) cache_mem(.word_addr(in_set), .be, .data_in(working ? mword_in : data_in), 
                                            .we(word_we & (working ? working_word : in_word)===j), .data_out(line_out[j]), .clk, .rst_n);//write to one word a time
        end
    endgenerate

    enum logic [3:0] {IDLE, DONE_MATCHING, READY, WAIT_MR, WAIT_MW, WRITE_CACHE, MREAD, MWRITE, BEGIN_MWRITE} state, nxt_state;

    always_ff @(posedge clk, negedge rst_n)
        if(~rst_n)
            working_word <= '0;
        else if(nxt_word) working_word <= working_word + 1;

    always_ff @(posedge clk, negedge rst_n)
        if(~rst_n)
            state <= IDLE;
        else
            state <= nxt_state;
    
    always_comb begin
        ready = 1'b0;
        working = 1'b1;
        mr_out = 1'b0;
        mw_out = 1'b0;
        nxt_state = state;
        nxt_word = 1'b0;
        word_we = 1'b0;
        set_dirty = 1'b0;
        set_valid = 1'b0;
        reset_dirty = 1'b0;
        reset_valid = 1'b0;
        tag_we = 1'b0;
        wb = 1'b0;
        inv_inst = 1'b0;
        reset_clk_ctr = 1'b0;
        hit = 1'b0;
        miss = 1'b0;
        case (state)
            IDLE: begin //WAIT FOR CMD
                working = 1'b0;
                reset_clk_ctr = 1'b1;
                if(addr[PHYSICAL_ADDR_BITS] & init)begin
                    inv_inst = 1'b1;
                    nxt_state = READY;
                end
                else if(~valid0[in_set] & init)begin //not valid, directly go to read
                    nxt_state = WAIT_MR;
                    mr_out = 1'b1;
                    working = 1'b1;
                    tag_we = 1'b1; //update tage before going to WAIT_MR
                end
                else if(valid0[in_set] & init)begin //valid, go to match
                    nxt_state = DONE_MATCHING;
                end
            end
            DONE_MATCHING: begin //now tag is ready, check for match
                working = 1'b0;
                if(match & re) begin //hit read
                    nxt_state = READY;
                end
                else if (match & we) begin//hit write
                    set_dirty = 1'b1;//perform write
                    word_we = 1'b1;
                    nxt_state = READY;
                    if(clk_ctr === '0) hit = 1'b1;
                    else miss = 1'b1;
                end
                else if(~match & dirty0[in_set]) begin//miss, writeback, evict
                    working = 1'b1;
                    wb = 1'b1; //write back started
                    mw_out = 1'b1; //working word = 0, first word write
                    nxt_state = MWRITE;
                    nxt_word = 1'b1; //pre incr for faster read from cache
                end 
                else begin//miss, no wb, evict
                    nxt_state = WAIT_MR;
                    mr_out = 1'b1;
                    working = 1'b1;
                    tag_we = 1'b1; //update tage before going to WAIT_MR
                end
            end
            READY: begin
                working = 1'b0;
                ready = 1'b1;
                if(ack) nxt_state = IDLE;
            end
            MWRITE: begin
                wb = 1'b1;
                nxt_word = 1'b1;
                if(working_word[1:0] === '1)begin //last word of packet, wait for done
                    nxt_state = WAIT_MW;
                end
            end
            WAIT_MW: begin
                wb = 1'b1;
                if(min_ready & working_word === '0)begin //done last packet, finish
                    nxt_state = MREAD;
                    wb = 1'b0;//writeback stopped
                    tag_we = 1'b1;
                end
                else if(min_ready & working_word[1:0] === '0) begin //done last work of packet, write next
                    nxt_state = BEGIN_MWRITE;
                end
            end
            BEGIN_MWRITE:begin
                wb = 1'b1;
                mw_out = 1'b1;
                nxt_state = MWRITE;
                nxt_word = 1'b1;
            end
            WAIT_MR: begin
                if(min_ready)begin //mem finished reading, word 0 ready
                    nxt_state = WRITE_CACHE;
                    word_we = 1'b1; //write current word
                    nxt_word = 1'b1;
                end
            end
            WRITE_CACHE: begin //4 word burst
                word_we = 1'b1;
                nxt_word = 1'b1;
                if(working_word === '1)begin //done packet, last packet, finish
                    nxt_state = DONE_MATCHING;
                    set_valid = 1'b1;
                    reset_dirty = 1'b1;
                end
                else if(working_word[1:0] === '1)//done packet, more to go
                    nxt_state = MREAD;
                // if(working_word==='0)begin //done fetching, go to match and do ops
                //     nxt_state = DONE_MATCHING;
                //     set_valid = 1'b1; //done, set valid and clear dirty
                //     reset_dirty = 1'b1;
                // end
                // else begin //not yet finished
                //     mr_out = 1'b1;
                //     nxt_state = WAIT_MR;
                // end
            end
            MREAD: begin
                mr_out = 1'b1;
                nxt_state = WAIT_MR;
            end
            default: nxt_state = IDLE;
        endcase
    end

endmodule