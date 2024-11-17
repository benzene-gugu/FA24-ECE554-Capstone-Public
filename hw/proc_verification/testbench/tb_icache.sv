import m_rv32::*;
module model_sdram_ctrl(clk, addr, dataout, mr, ready, rst_n); //3 cycles delay
    input logic [31:0] addr;
    input logic mr, clk, rst_n;
    output logic [31:0] dataout;
    output logic ready;

    logic sending, allow_in;
    logic [1:0] word_cnt;
    logic [3:0] delay_q;

    reg [7:0] mem[4095:0];
    initial begin
        for(int i = 0; i < 1024; ++i)
            {mem[4*i+3], mem[4*i+2], mem[4*i+1], mem[4*i]} = i;
    end

    always_ff @(posedge clk, negedge rst_n)
        if(~rst_n)
            {allow_in, delay_q} <= '0;
        else
            {allow_in, delay_q} <= {delay_q, mr};

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            word_cnt <= '0;
            ready <= '0;
        end
        else if(allow_in) begin
            word_cnt <= '0;
            ready <= 1'b1;
        end
        else begin
            word_cnt <= word_cnt + 1;
            ready <= 1'b0;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n)
            sending <= 0;
        else if(allow_in)
            sending <= 1;
        else if(word_cnt === 3)
            sending <= 0;
    end
    assign dataout = sending ? {mem[{addr[31:4], word_cnt, 2'd3}], mem[{addr[31:4], word_cnt, 2'd2}], mem[{addr[31:4], word_cnt, 2'd1}], mem[{addr[31:4], word_cnt, 2'd0}]} : '0;
endmodule

module tb_icache();
    logic rst_n, clk, ready, mr_out, in_ready, err;
    logic [31:0] data_out, addr, addr_out, word_in;
    logic [25:0] done_addr;
    logic allow_mem;
    mem_icache #(.WORD_BITS(3), .SET_BITS(4)) icache(.done_addr, .rst_n, .clk, .data_out, .addr, .ready, .addr_out(addr_out[PHYSICAL_ADDR_BITS-1:0]), .mr_out, .word_in, .in_ready, .en(1'b1));
    model_sdram_ctrl iDRAM_CTRL(.clk, .addr(addr_out), .dataout(word_in), .mr(mr_out), .ready(in_ready), .rst_n);
    assign addr_out[31:PHYSICAL_ADDR_BITS] = 0;
    initial begin
        clk = 0;
        err = 0;
        rst_n = 0;
        addr = 0;
        allow_mem = 0;
        repeat(4) @(negedge clk);
        rst_n = 1;

        //simple seq access
        addr = 4*0;
        for(int i = 0; i < 256; ++i) begin
            @(posedge clk);
            while(ready !== 1 || done_addr !== addr[25:0])
                @(posedge clk);
            @(negedge clk);
            addr = 4*(i+1);
            if(ready !== 1 || done_addr !== (4*i))
             $display("SHOULD NOT CHANGE!!!");
            if(data_out !== i) begin
                $display("err seq @ %d, actual value: %d. %d", i, data_out, $realtime);
                err = 1;
            end
            else $display("seq @%d passed.", i);
        end
        
        //in set access
        repeat(4)
        for(int i = 0; i < 4; ++i) begin
            addr = 4*i;
            @(posedge clk);
            while(ready!== 1 || done_addr !== addr[25:0])
                @(posedge clk);
            if(data_out !== i) begin
                $display("err in set @ %d, actual value: %d. %d", i, data_out, $realtime);
                err = 1;
            end
            else $display("in set @%d passed.", i);
        end

        //full random
        for(int i = 0, w; i < 4096; ++i) begin
            addr = ($urandom % 1024) * 4;
            w = $urandom % 2;
            @(posedge clk);
            for(int j = 0; j < 128*w; ++j)
                @(posedge clk);
            if(ready && done_addr === addr[25:0] & data_out !== addr / 4) begin
                $display("err rand @ %h, actual value: %d. expected: %d. %d", addr, data_out, addr/4, $realtime);
                err = 1;
            end
            else if (ready) $display("rand @%d passed.", i);
        end
        
        if(!err) $display("pass!");
        else $display("FAILED!");
        $stop();
    end

    always
        #2 clk = ~clk;
endmodule