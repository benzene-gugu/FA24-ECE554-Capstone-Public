module model_sdram_ctrl_rw(clk, addr, dataout, datain, mr, mw, gready, rst_n);
    input logic [31:0] addr, datain;
    input logic mr, clk, rst_n, mw;
    output logic [31:0] dataout;
    output logic gready;

    logic rready, wready;

    logic sending, allow_in, write_enable, nxt_write_cnt, swready;
    logic [1:0] word_cnt, word_cnt_write;
    logic [3:0] delay_q, delay_q_w;
    logic [31:0] caddr, caddr_ff;

    enum logic {IDLE, WRITE} state, nxt_state;

    assign gready = rready | wready;
    always @(posedge clk) begin
        if((rready && wready) || (mr && mw) || (gready && mr) || (gready && mw))begin
            $display("ERR in model_sdram_ctrl_rw");
            $stop();
        end
    end

    always_ff @(posedge clk, negedge rst_n)
        if(~rst_n)
            caddr_ff <= 0;
        else if(mw | mr)
            caddr_ff <= addr;
    assign caddr = (mw|mr) ? addr : caddr_ff;

    reg [31:0] mem[0:4095];
    // initial begin
    //     for(int i = 0; i < 1024; ++i)
    //         mem[i] = 'x;//i;
    // end

    always_ff @(posedge clk, negedge rst_n)
        if(~rst_n)
            state <= IDLE;
        else state <= nxt_state;
    
    always @(posedge clk)
        if(write_enable) mem[{caddr[31:4], word_cnt_write}] <= datain;
    
    always_comb begin
        write_enable = 0;
        nxt_write_cnt = 0;
        nxt_state = state;
        swready = 0;
        case (state)
            IDLE: if(mw) begin
                write_enable = 1;
                nxt_write_cnt = 1;
                nxt_state = WRITE;
            end
            WRITE:begin
                write_enable = 1;
                nxt_write_cnt = 1;
                if(word_cnt_write === 2'd3)begin
                    nxt_state = IDLE;
                    swready = 1;
                end
            end
            default:;
        endcase
    end

    always_ff @(posedge clk, negedge rst_n)
        if(~rst_n)begin
            {allow_in, delay_q} <= '0;
            {wready, delay_q_w} <= '0;
        end
        else begin
            {allow_in, delay_q} <= {delay_q, mr};
            {wready, delay_q_w} <= {delay_q_w, swready};
        end

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            word_cnt <= '0;
            rready <= '0;
        end
        else if(allow_in) begin
            word_cnt <= '0;
            rready <= 1'b1;
        end
        else begin
            word_cnt <= word_cnt + 1;
            rready <= 1'b0;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n)
            word_cnt_write <= 0;
        else if(nxt_write_cnt)
            word_cnt_write <= word_cnt_write + 1;
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n)
            sending <= 0;
        else if(allow_in)
            sending <= 1;
        else if(word_cnt === 3)
            sending <= 0;
    end
    assign dataout = sending ? mem[{caddr[31:4], word_cnt}] : '0;

endmodule
/*
module tb_dcache();
    logic rst_n, clk, ready, mr_out, mw_out, min_ready, err, we, re, init, ack;
    logic [31:0] data_out, addr, maddr_out, mword_in, data_in, mword_out;
    mem_dcache #(.WORD_BITS(2), .SET_BITS(4))
        dcache(.rst_n, .clk, .data_in, .data_out, .we, .re, .init, 
               .addr, .ready, .maddr_out(maddr_out[25:0]), .mr_out, .mw_out, .mword_in, .mword_out, .min_ready, .ack);
    model_sdram_ctrl_rw iDRAM_CTRL(.clk, .addr({6'b0, maddr_out[25:0]}), .dataout(mword_in), .datain(mword_out), .mr(mr_out), .mw(mw_out), .gready(min_ready), .rst_n);

    logic [31:0] ref_mem [0:4095];
    logic rw;

    initial begin
        for(int i = 0; i < 1024; ++i)
            ref_mem[i] = i;
        clk = 0;
        err = 0;
        rst_n = 0;
        addr = 0;
        data_in = 0;
        we = 0;
        re = 0;
        init = 0;
        ack = 0;
        repeat(4) @(negedge clk);
        rst_n = 1;

        //full word test
        //simple seq read
        re = 1;
        for(int i = 0; i < 128; ++i) begin
            addr = 4*i;
            init = 1;
            @(posedge clk);
            init = 0;
            while(ready !== 1)
                @(negedge clk);
            ack = 1;
            if(data_out !== ref_mem[i]) begin
                $display("err seq read @ %d, actual value: %d. %d", i, data_out, $realtime);
                err = 1;
            end
            else $display("seq read @%d passed.", i);
            @(posedge clk);
            ack = 0;
        end
        re = 0;
        //simple seq write and read back test
        we = 1;
        for(int i = 0; i < 128; ++i) begin
            addr = 4*i;
            data_in = i+1;
            init = 1;
            @(posedge clk);
            init = 0;
            ref_mem[i] = data_in;
            while(ready !== 1)
                @(negedge clk);
            ack = 1;
            @(posedge clk);
            ack = 0;
        end
        we = 0;
        re = 1;
        for(int i = 0; i < 128; ++i) begin
            addr = 4*i;
            init = 1;
            @(posedge clk);
            init = 0;
            while(ready !== 1)
                @(negedge clk);
            ack = 1;
            if(data_out !== ref_mem[i]) begin
                $display("err seq write @ %d, actual value: %d. %d", i, data_out, $realtime);
                err = 1;
            end
            else $display("seq write @%d passed.", i);
            @(posedge clk);
            ack = 0;
        end
        re = 0;

        //full random
        for(int i = 0, w; i < 1024; ++i) begin
            addr = ($urandom % 1024) * 4;
            data_in = $urandom;
            rw = $urandom % 2;
            if(rw) begin //read
                re = 1;
                init = 1;
                @(posedge clk);
                init = 0;
                while(ready !== 1)
                    @(negedge clk);
                ack = 1;
                if(data_out !== ref_mem[addr/4]) begin
                    $display("err rand read @ %d, actual value: %d. %d", i, data_out, $realtime);
                    err = 1;
                end
                else $display("rand read @%d passed.", i);
                @(posedge clk);
                ack = 0;
                re = 0;
            end
            else begin
                we = 1;
                init = 1;
                @(posedge clk);
                init = 0;
                ref_mem[addr/4] = data_in;
                while(ready !== 1)
                    @(negedge clk);
                ack = 1;
                @(posedge clk);
                ack = 0;
                we = 0;
            end
        end
        if(!err) $display("pass!");
        else $display("FAILED!");
        $stop();
    end

    always
        #2 clk = ~clk;
endmodule
*/
//`define CMP_TO_DRAM
module tb_dcache_intf();
    logic rst_n, clk, ready, mr_out, mw_out, min_ready, err, we, re, init, ack;
    logic [31:0] data_out, addr, maddr_out, mword_in, data_in, mword_out, ref_out;
    logic [2:0] wfunct3;

    `ifndef CMP_TO_DRAM
    mem_dcache_intf #(.WORD_BITS(2), .SET_BITS(4))
        dcache(.wfunct3, .rst_n, .clk, .data_in, .data_out, .we, .re, .init, 
               .addr, .ready, .maddr_out(maddr_out[25:0]), .mr_out, .mw_out, .mword_in, .mword_out, .min_ready, .ack);
    model_sdram_ctrl_rw iDRAM_CTRL(.clk, .addr({6'b0, maddr_out[25:0]}), .dataout(mword_in), .datain(mword_out), .mr(mr_out), .mw(mw_out), .gready(min_ready), .rst_n);
    `else
    model_sdram_ctrl_rw iDRAM_CTRL(.clk, .addr(addr), .dataout(data_out), .datain(data_in), .mr(re&init), .mw(we&init), .gready(ready), .rst_n);
    `endif

    Dummy_Mem_aligned ref_mem(.addr, .data_in, .data_out(ref_out), .mr(), .mw(we & init), .clk, .rst_n, .busy(), .wfunct3, .p2_addr(), .p2_data_out(), .p2_mr());
    
    logic rw, signed_;

    enum logic [1:0] {B, H, W} access_type;

    always_comb begin
        case(access_type)
            B:wfunct3[1:0] = 2'b00;
            H:wfunct3[1:0] = 2'b01;
            W:wfunct3[1:0] = 2'b10;
            default: wfunct3[1:0] = '0;
        endcase
    end
    assign wfunct3[2] = access_type === W ? 1'b0 : signed_;

    int B_acc, H_acc, W_acc, total_clk, nre, nwr;

    initial begin
        total_clk = 0;
        nre = 0;
        nwr = 0;
        B_acc = 0;
        H_acc = 0;
        W_acc = 0;
        clk = 0;
        err = 0;
        rst_n = 0;
        addr = 0;
        data_in = 0;
        we = 0;
        re = 0;
        init = 0;
        ack = 0;
        repeat(4) @(negedge clk);
        rst_n = 1;
        
        //inital write
        @(negedge clk);
        `ifndef CMP_TO_DRAM
        access_type = B;
        `else
        access_type = W;
        `endif
        signed_ = 1'b0;
        for(int i = 0; i < 4096; ++i)
        begin
            we = 1'b1;
            `ifndef CMP_TO_DRAM
            addr = i;
            `else
            addr = i*4;
            `endif
            data_in = i;
            init = 1'b1;
            @(negedge clk)
            init = 1'b0;
            while(ready !== 1)
                @(negedge clk);
            ack = 1;
            @(negedge clk);
            ack = 0;
            we = 0;
        end

        //random op
        @(negedge clk);
        for(int i = 0; i < 4096; ++i) begin
            signed_ = $urandom % 2;

            `ifndef CMP_TO_DRAM
            addr = $urandom % 4096;
            //set access type according to addr
            case(addr % 4)
                0: access_type = $urandom % 3;
                1: access_type = B;
                2: access_type = ($urandom % 2) === 0 ? H : B;
                3: access_type = B;
            endcase
            `else
            access_type = W;
            addr = ($urandom*4) % 4096;
            `endif

            rw = $urandom % 2;
            data_in = $urandom;
            //update ctr
            if(access_type === B) B_acc++;
            else if(access_type === H) H_acc++;
            else W_acc++;

            we = rw;
            re = ~rw;
            init = 1'b1;
            @(negedge clk);
            init = 1'b0;
            while(ready !== 1)
                @(negedge clk);
            ack = 1'b1;
            if(re) begin
                if(data_out !== ref_out) begin
                    $display("err read @%h, readed value: %d, expected value: %d. time: %d", addr, data_out, ref_out, $realtime);
                    err = 1;
                    $stop();
                end
                nre++;
            end
            else nwr++;
            @(negedge clk);
            ack = 0;
            re = 0;
            we = 0;
        end

        //cross compare
        @(negedge clk);
        `ifndef CMP_TO_DRAM
        access_type = B;
        `else
        access_type = W;
        `endif
        signed_ = 1'b0;
        for(int i = 0; i < 1024; ++i) begin
            re = 1;
            init = 1;
            `ifndef CMP_TO_DRAM
            addr = i;
            `else
            addr = i*4;
            `endif
            @(negedge clk);
            init = 0;
            while(ready !== 1)
                @(negedge clk);
            ack = 1;
            if(data_out !== ref_out) begin
                $display("err cmp @%h, readed value: %d, expected value: %d. time: %d", i, data_out, ref_out, $realtime);
                err = 1;
            end
            else $display("cmp @%h passed.", i);
            @(posedge clk);
            ack = 0;
            re = 0;
            @(negedge clk);
        end
        if(!err) $display("pass!, rand acc B H W, R W: %d %d %d, %d %d; total clk: %d", B_acc, H_acc, W_acc, nre, nwr, total_clk);
        else $display("FAILED!");
        $stop();
    end

    always begin
        #2 clk = ~clk;
        if(clk) total_clk++;
    end
endmodule

// @(posedge clk)
//         //dram model write test
//         for(int i = 0; i < 1024; i+=4)begin //word_addr
//             addr = i << 2;
//             data_in = i;
//             we = 1'b1;
//             init = 1'b1;
//             @(posedge clk);
//             init = 1'b0;
//             we = 1'b0;
//             addr = (i+1) << 2;
//             data_in = i+1;
//             @(posedge clk);
//             addr = (i+2) << 2;
//             data_in = i+2;
//             @(posedge clk);
//             addr = (i+3) << 2;
//             data_in = i+3;
//             @(posedge clk)
//             while(~ready)
//                 @(posedge clk);
//             @(posedge clk);
//         end
//         //dram model read test
//         for(int i = 0; i < 1024; i+=4)begin //word_addr
//             addr = i << 2;
//             re = 1'b1;
//             init = 1'b1;
//             @(posedge clk);
//             init = 1'b0;
//             re = 1'b0;
//             while(~ready)
//                 @(posedge clk);
//             if(data_out !== i) $display("ERROR");
//             addr = (i+1) << 2;
//             @(posedge clk);
//             if(data_out !== (i+1)) $display("ERROR");
//             addr = (i+2) << 2;
//             @(posedge clk);
//             if(data_out !== (i+2)) $display("ERROR");
//             addr = (i+3) << 2;
//             @(posedge clk)
//             if(data_out !== (i+3)) $display("ERROR");
//             @(posedge clk);
//         end
//         $stop();