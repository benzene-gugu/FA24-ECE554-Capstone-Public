import m_rv32::*;
module tb_reg_ooo();
    logic clk, rst_n, w_en, r1_d_sel, r2_d_sel;
    logic [4:0] re1_sel, re2_sel, wrt_sel;
    logic [2:0] wrt_src;
    logic [31:0] r1_data, r2_data;
    CDB_t cdb;

    RegFile_ooo myReg(.clk, .rst_n, .re1_sel, .re2_sel, .wrt_sel, .wrt_src, .w_en, .r1_data, .r1_d_sel, .r2_data, .r2_d_sel, .cdb);
    initial begin
        static integer  err = 0;
        //reset
        clk = 0;
        rst_n = 0;
        w_en = 0;
        re1_sel = 0;
        re2_sel = 0;
        wrt_sel = 0;
        wrt_src = 0;
        cdb = 0;
        @(negedge clk)
        rst_n = 1;

        //test 0 write, read
        @(posedge clk);
        re1_sel = 0;
        re2_sel = 0;
        wrt_sel = 0;
        wrt_src = 1;
        w_en = 1;
        @(posedge clk);
        if(r1_data === r2_data && r1_data === 0 && r1_d_sel === r2_d_sel && r1_d_sel === 0) //real data 0
            $display("Read 0 confirmed.");
        else begin 
            err = 1;
            $display("Read 0 err: %b, %h", r1_d_sel, r1_data);
        end

        //write tag test
        //reg tested: 2, 10
        // cdb from 1; write 2, src 1; test read 2 (no bypassing, no tag)
        // cdb from 1; write 10, src 2; test read 2 (bypassing cdb values)
        // read 10, test tag; read 2, test saving
        @(posedge clk);
        re1_sel = 2;
        re2_sel = 10;
        wrt_sel = 2;
        wrt_src = 1;
        w_en = 1;
        cdb.data_src = fu_addr_t'(1);
        cdb.data = 2;
        @(negedge clk);
        #1;
        if(r1_data === r2_data && r1_data === 0 && r1_d_sel === r2_d_sel && r1_d_sel === 0) //real data 0
            $display("write tag before clk confirmed.");
        else begin 
            err = 1;
            $display("write tag before clk err: %b, %h", r1_d_sel, r1_data);
        end

        @(posedge clk);
        wrt_src = 2;
        wrt_sel = 10;
        @(negedge clk);
        #1;
        if(r1_data === 2 && r1_d_sel === 0 && r2_data === 0 && r2_d_sel === 0)
            $display("first write tag, bypassing confirmed.");
        else begin 
            err = 1;
            $display("first write tag err: %b, %h", r1_d_sel, r1_data);
        end

        @(negedge clk);
        #1;
        if(r1_data === 2 && r1_d_sel === 0 && r2_data === 2 && r2_d_sel === 1)
            $display("second write tag confirmed, saving confirmed");
        else begin 
            err = 1;
            $display("second write tag, or saving read err: %b, %h; %b, %h", r1_d_sel, r1_data, r2_d_sel, r2_data);
        end

        if(err === 1) $display("Err found.");
        else $display("PASSED.");
        $finish();
    end

    always
        #5 clk = ~clk;
    
endmodule

module tb_reg();
    parameter XLEN = 32;

    logic clk, rst_n, w_en, r1, r2;
    logic [4:0] re1_sel, re2_sel, wrt_sel;
    logic [XLEN-1:0] w_data;
    logic [XLEN-1:0] r1_data, r2_data;
    logic [XLEN-1:0] sample, sample2;

    logic [5:0] i;

    RegFile myReg(.clk(clk), .rst_n(rst_n), .re1_sel(re1_sel), .re2_sel(re2_sel), .wrt_sel(wrt_sel), .w_data(w_data), .w_en(w_en), .r1_data(r1_data), .r2_data(r2_data), .r1, .r2);
    
    initial begin
        clk = 0;
        rst_n = 0;
        w_en = 0;
        re1_sel = 0;
        re2_sel = 0;
        wrt_sel = 0;
        w_data = 0;
        r1 = 0;
        r2 = 0;
        @(negedge clk)
        rst_n = 1;
        @(negedge clk)
        w_en = 1;
        //assign
        for(i = 0; i < 32; i = i + 1) begin
            wrt_sel = i[4:0];
            w_data[5:0] = i+1;
            @(negedge clk);
        end
        w_en = 0;
        //read
        r1 = 1;
        r2 = 1;
        for(i = 0; i < 32; i = i + 1) begin
            re1_sel = i[4:0];
            re2_sel = 0;
            @(posedge clk);
            sample = r1_data;
            sample2 = r2_data;
            if((sample !== (i === 0 ? 0 : {26'd0,i}+1)) | (sample2 !== 0)) $display("read test port 1 err @ %d, sample %d, sample2 %d", i, sample, sample2);
        end
        for(i = 0; i < 32; i = i + 1) begin
            re2_sel = i[4:0];
            re1_sel = 0;
            @(posedge clk);
            sample = r2_data;
            sample2 = r1_data;
            if((sample !== (i === 0 ? 0 : {26'd0,i}+1)) | (sample2 !== 0)) $display("read test port 2 err @ %d, sample %d, sample2 %d", i, sample, sample2);
        end

        r1 = 1;
        r2 = 1;

        //test bypass
        //x0
        w_data = 128;
        w_en = 1;
        wrt_sel = 0;
        re1_sel = 0;
        re2_sel = 1;
        @(posedge clk);
        sample = r1_data;
        sample2 = r2_data;
        if(sample !== 0) $display("bypass_err1 %d", sample);
        if(sample2 !== 2) $display("bypass_err2 %d", sample2);

        //x1
        sample = r1_data;
        if(sample !== 0) $display("bypass_err3 %d", sample);

        //x1
        @(posedge clk)
        wrt_sel = 1;
        re1_sel = 1;
        re2_sel = 2;
        @(posedge clk);
        sample = r1_data;
        sample2 = r2_data;
        if(sample !== 128) $display("bypass_err4 %d", sample);
        if(sample2 !== 3) $display("bypass_err5 %d", sample2);
        $finish();
    end

    always #5 clk = ~clk;
endmodule