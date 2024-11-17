import m_rv32::*;

/*
mr_out high for one cycle to send a memory read command. Once in_ready is issued externally,
word_in will be load to the cache.
*/
module mem_icache (done_addr, rst_n, clk, data_out, addr, ready, addr_out, mr_out, word_in, in_ready, en, inv_inst, hit, miss);
    parameter STRT_ADDR = 0;
    parameter WORD_BITS = 4; //8 words
    parameter SET_BITS = 6;//5; //1k sets
    parameter TAG_BITS = PHYSICAL_ADDR_BITS - WORD_BITS - SET_BITS - 2;

    localparam LINE_SIZE = 2**WORD_BITS;
    localparam SET_SIZE = 2**SET_BITS;

    input logic rst_n, clk, in_ready, en, inv_inst;
    input mem_addr_t addr;
    input logic [XLEN-1:0] word_in;
    output logic [PHYSICAL_ADDR_BITS-1:0] done_addr;
    output [PHYSICAL_ADDR_BITS-1:0] addr_out;
    output inst_t data_out;
    output logic ready, mr_out;
    output logic hit, miss;

    //logic [LINE_SIZE-1:0]word_ready;
    logic [LINE_SIZE-1:0]word_ready_ff;
    
    logic [TAG_BITS-1:0] working_tag, in_tag;
    logic [SET_BITS-1:0] working_set, in_set, set_ff, access_set;
    logic [WORD_BITS-1:0] working_word, in_word, word_ff, target_word, working_word_next, access_word;
    assign working_word_next = working_word+1'b1;

    logic data_loading, start_ld, incr_working_word;

    //logic [LINE_SIZE-1:0][XLEN-1:0]data0[SET_SIZE-1:0];
    logic [TAG_BITS-1:0] /*tag0 [SET_SIZE-1:0],*/ tag_ff;
    logic [SET_SIZE-1:0] valid0;

    logic tag_we, v_ff;
    logic [TAG_BITS-1:0] tag_read;

    logic [LINE_SIZE-1:0][XLEN-1:0]line_out;
    logic we_word;

    assign data_out = line_out[word_ff];
    assign done_addr = {tag_ff, set_ff, word_ff, 2'b00};

    assign {in_tag, in_set, in_word} = addr[PHYSICAL_ADDR_BITS-1:2];
    //ready signal use flopped inputs
    assign ready = v_ff & (tag_read === tag_ff) & ~data_loading/* | (data_loading&word_ready[word_ff]))*/;
    assign addr_out = {working_tag, working_set, working_word, 2'b00};

    assign access_set = data_loading ? working_set : in_set;
    assign access_word = data_loading ? working_word : in_word;

    enum logic [1:0] {IDLE = 2'b0, READ, WRITE, WRITE_PACK} state, nxt_state;

    mem_fixlen_ram #(.ADDRESS_WIDTH(SET_BITS), .DATA_WIDTH(TAG_BITS)) tag_mem(.addr(access_set), .data_in(in_tag), .we(tag_we), .data_out(tag_read), .clk, .rst_n);

    always_ff @(posedge clk, negedge rst_n)
        if(~rst_n)
            v_ff <= 1'b0;
        else v_ff <= valid0[in_set];
    
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            {tag_ff, set_ff, word_ff} = '0;
        else if(~data_loading)
            {tag_ff, set_ff, word_ff} <= {in_tag, in_set, in_word};
    

    //data
    genvar j;
    generate
        for(j = 0; j < LINE_SIZE; ++j) begin: GENDATA
            mem_cacheword_benable #(.WORD_ADDRESS_WIDTH(SET_BITS)) cache_mem(.word_addr(access_set), .be({4{access_word===j}}), .data_in(word_in), 
                                            .we(we_word), .data_out(line_out[j]), .clk, .rst_n);
        end
    endgenerate


    //generate word ready during read-in process
    /*
    genvar i;
	generate
    for(i = 0; i < LINE_SIZE; ++i)begin : ICACHE_GEN
        always_ff @(posedge clk, negedge rst_n) begin
            if(!rst_n)
                word_ready_ff[i] <= 1'b0;
            else if(start_ld)
                word_ready_ff[i] <= 1'b0;
            else if(we_word & working_word === i)
                word_ready_ff[i] <= 1'b1;
        end
        assign word_ready[i] = word_ready_ff[i];
	end
	endgenerate*/

    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            valid0 <= '0;
        else if(inv_inst)
            valid0 <= '0;
        else if(start_ld)
            valid0[in_set] = 1'b1;
    
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)begin
            working_set <= '0;
            working_tag <= '0;
            working_word<= '0;
            target_word<= 0;
        end
        else if(start_ld)begin
            working_set <= in_set;
            working_tag <= in_tag;
            working_word <= '0; //always state from word0
            target_word <= '0;
        end
        else if(incr_working_word)
            working_word <= working_word_next;

    //state machine
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            state <= IDLE;
        else state <= nxt_state;
    
    always_comb begin
        we_word = 1'b0;
        tag_we = 1'b0;
        data_loading = 1'b1;
        start_ld = 1'b0;
        nxt_state = state;
        mr_out = 1'b0;
        incr_working_word = 1'b0;
        hit = 1'b0;
        miss = 1'b0;
        case(state)
            default:begin
                data_loading = 1'b0;
                if(en & (~ready | ~valid0[in_set])) begin
                    start_ld = 1'b1;
                    nxt_state = READ;
                    tag_we = 1;
                    miss = 1'b1;
                end
                else if(en & ready)
                    hit = 1'b1;
            end
            READ: begin
                mr_out = 1;
                nxt_state = WRITE;
            end
            WRITE: begin
                if(in_ready) begin //ready at 0 of the packet
                    we_word = 1'b1;
                    nxt_state = WRITE_PACK;
                    incr_working_word = 1'b1;
                end
                // if(in_ready & (working_word_next !== target_word))begin//write 4 word burst not finished next word in line
                //     we_word = 1;
                //     nxt_state = READ;
                //     incr_working_word = 1;
                // end
                // else if(in_ready & (working_word_next === target_word))begin //finished, load next
                //     nxt_state = IDLE;
                //     we_word = 1;
                // end
            end
            WRITE_PACK: begin //write burst
                we_word = 1;
                incr_working_word = 1'b1;
                if(working_word_next === target_word) //done packet, last packet: finish
                    nxt_state = IDLE;
                else if(working_word_next[1:0] === '0)  //done packet, more to go
                    nxt_state = READ;
            end
        endcase
    end
endmodule