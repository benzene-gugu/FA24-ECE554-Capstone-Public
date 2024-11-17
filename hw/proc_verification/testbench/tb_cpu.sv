module tb_cpu ();
    integer  n_half_cycles = 0;
    integer fail = 0;
    logic clk, rst_n;
    cpu iDUT(.clk, .rst_n);

    initial begin
        clk = 0;
        rst_n = 0;
        @(posedge clk);
        @(negedge clk);
        rst_n = 1;        
    end

    always begin
        #5 clk = ~clk;
        n_half_cycles += 1;
        if(n_half_cycles >= 1e8)begin
            $display("TIME OUT!");
            $finish();
        end
        if(iDUT.ireg.regfile[10] !== 0 && iDUT.ireg.regfile[17] === 93 && !(iDUT.ireg.wrt_sel === 10 && iDUT.ireg.w_en)) begin
            $display("FAIL. TEST: %d, at %h", iDUT.ireg.regfile[10][31:1], iDUT.fetch_curr_pc_out); 
            fail = 1;
        end
        if(iDUT.ifetch.halt) begin
            $display("DONE.");
            if(fail === 0)
                $display("PASS.");
            $finish();
            //check x10=0d, x17=93d
        end
    end

endmodule