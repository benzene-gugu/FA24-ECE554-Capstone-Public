import m_rv32::*;
module tb_fetch();
    mem_addr_t spec_pc, next_pc_in, pc_out;
    logic [31:0] inst_out, pc;
    logic inst_out_ready, stall, override_next_pc, clk, rst_n;
    int test_num, err, clk_num;

    assign pc = pc_out;

    fetch_pipelined idut(spec_pc, next_pc_in, pc_out, inst_out, inst_out_ready, stall, override_next_pc, clk, rst_n);


    initial begin
        for(int i = 0; i < 16; i += 1)
            idut.i_mem.mem[i] = i*4;
        
        test_num = 0;
        clk_num = 0;
        err = 0;

        rst_n = 0;
        clk = 0;
        next_pc_in = 0;
        stall = 0;
        override_next_pc = 0;

        @(negedge clk);
        @(negedge clk);
        rst_n = 1;

        @(negedge clk);//test0 pc 0;
        wait(inst_out_ready);
        if(inst_out !== 0 || inst_out !== pc_out || spec_pc !== pc+4) begin
            $display("err on test %d", test_num);
            err = 1;
        end
        test_num += 1;

        @(negedge clk);//test1 pc 1;
        wait(inst_out_ready);
        if(inst_out !== 4 || inst_out !== pc_out || spec_pc !== pc+4) begin
            $display("err on test %d", test_num);
            err = 1;
        end
        test_num += 1;

        stall = 1;
        @(negedge clk);//test2 stall;
        wait(inst_out_ready);
        if(inst_out !== 4 || inst_out !== pc_out || spec_pc !== pc+4) begin
            $display("err on test %d", test_num);
            err = 1;
        end
        stall = 0;
        test_num += 1;

         @(negedge clk);//test3 pc 2;
        wait(inst_out_ready);
        if(inst_out !== 8 || inst_out !== pc_out || spec_pc !== pc+4) begin
            $display("err on test %d", test_num);
            err = 1;
        end
        test_num += 1;

        stall = 1;
        override_next_pc = 1;
        next_pc_in = 16;
        @(posedge clk);
        override_next_pc = 0;
        @(negedge clk);//test4 stall on override;
        wait(inst_out_ready);
        if(inst_out !== 16 || inst_out !== pc_out || spec_pc !== pc+4) begin
            $display("err on test %d", test_num);
            err = 1;
        end
        stall = 0;
        test_num += 1;

        if(err)
            $display("!error detected!");
        else $display("pass.");
        $stop();

    end

    always begin
        #2 clk = ~clk;
        clk_num += 1;
        if(clk_num >= 10000) begin
            $display("timeout.");
            $stop();
        end
    end
endmodule