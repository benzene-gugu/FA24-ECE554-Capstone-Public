import m_rv32::*;
module tb_resv();
    inst_to_rs_t rec_in;
    inst_to_rs_t alu_rec_out, mem_rec_out;
    logic avail_in, clk, rst_n, speculated, right_spec, wrong_spec;
    logic consume_out, alu_init, mem_init, alu_ack, mem_ack;
    CDB_t cdb_in;
    reservation_station iDUT(.rec_in, .avail_in, .consume_out, .cdb_in, .rst_n, .clk, .speculated, .right_spec, .wrong_spec,
                           .alu_rec_out, .alu_init, .mem_rec_out, .mem_init, .alu_ack, .mem_ack);
    
    initial begin
        //$dumpfile("tb_resv.vcd");
        //$dumpvars(0, myALU);
        static integer err = 0;
        rec_in = 0;
        clk = 0;
        rst_n = 0;
        avail_in = 0;
        speculated = 0;
        cdb_in = 0;
        right_spec = 0;
        wrong_spec = 0;
        @(negedge clk);
        rst_n = 1;
        @(posedge clk);

        //assign alu inst
        rec_in.exec_addr = FU_ALU0;
        rec_in.funct3 = 0;
        rec_in.ext_bits = 0;
        rec_in.oper1_sel = OP1_VAL;
        rec_in.operand_1 = 12;
        rec_in.oper2_sel = OP2_VAL;
        rec_in.operand_2 = 13;
        avail_in = 1;
        @(negedge clk); //check immediate response
        if(consume_out === 1) $display("ALU inst 1 issued.");
        else begin
            $display("First alu failed.");
            $finish();
        end


        //keep checking for duplicated fu
        @(posedge clk);
        rec_in.operand_1 = 128;
        rec_in.operand_2 = 256;
        //check
        @(negedge clk);
        if(alu_init !== 1) begin
            $display("alu not start!");
            err = 1;
        end
        else $display("ALU start pass.");
        
        @(negedge clk);
        if(consume_out === 1) begin
            $display("Occupied alu failed.");
            $finish();
        end
        @(negedge clk); //check out
        if(alu_rec_out.operand_1 !== 12 | alu_rec_out.operand_2 !== 13)begin
            $display("Ocuupied record alu failed.");
            err = 1;
        end
        else $display("Occupied record pass.");
        

        //assign mem inst speculated with pending operands
        @(posedge clk);
        //assign alu inst
        rec_in.exec_addr = FU_MEM;
        rec_in.funct3 = 0;
        rec_in.ext_bits = 0;
        rec_in.oper1_sel = OP1_SRC;
        rec_in.operand_1 = FU_ALU0;
        rec_in.oper2_sel = OP2_SRC;
        rec_in.operand_2 = FU_JBR;
        avail_in = 1;
        speculated = 1;
        @(negedge clk); //check immediate response
        if(consume_out === 1 & mem_init === 0) $display("MEM inst issue pass.");
        else begin
            $display("First alu failed.");
            $finish();
        end
        @(negedge clk);
        //now rv should wait for spec and operands
        avail_in = 0;
        if(mem_init === 0) $display("MEM pending pass.");
        //send first operand
        cdb_in.data_src = FU_ALU0;
        cdb_in.data = 222;
        @(negedge clk);
        //send 2nd operand
        cdb_in.data_src = FU_JBR;
        cdb_in.data = 333;
        if(mem_init === 1) begin
            $display("Not ready but started!!!!");
            err = 1;
        end
        @(negedge clk);
        cdb_in.data_src = FU_ALU0;
        if(mem_init === 1) begin
            $display("Speculation not resolved!!!!");
            err = 1;
        end
        @(negedge clk);
        wrong_spec = 1;
        #1;
        if(mem_init === 0)
            $display("mem_init passed.");
        else begin
            err = 1;
            $display("mem_init failed!!");
        end
        @(negedge clk);
        wrong_spec = 0;
        #16;
        
        if(err === 1)
            $display("ERROR Found.");
        else
            $display("PASSED---");
        $finish();
    end

    always
        #2 clk = ~clk;
endmodule