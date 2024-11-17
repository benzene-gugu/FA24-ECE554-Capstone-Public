import m_rv32::*;
//dispatch stage
module reserved_record(busy, rdy_next, dispatch, fu_ack, rec_in, avil_in, next, rec_out, rec_in_cons, initiate, clk, rst_n, speculated, right_spec, wrong_spec, cdb_in, internal_load, led);
    input inst_to_rs_t rec_in;
    input logic avil_in;
    input logic next, dispatch;
    input logic speculated, right_spec, wrong_spec;
    input clk, rst_n;
    input CDB_t cdb_in;
    output inst_to_rs_t rec_out;
    output fu_ack;
    output logic rec_in_cons, led;
    output logic initiate, internal_load;
    output logic rdy_next, busy;


    logic load_rec, ready;
    assign rec_in_cons = load_rec;
    assign ready = ~rec_out.oper1_sel & ~rec_out.oper2_sel; //ops are ready and fu is free
    assign fu_ack = next;
    assign internal_load = load_rec;

    enum logic [1:0] {RC_EMPTY, RC_SPEC, RC_OCCU, RC_WAIT} state, nxt_state;

    always_ff @(posedge clk, negedge rst_n) begin //disable bypassing
        if(!rst_n) begin
            state <= RC_EMPTY;
            rec_out <= 0;
        end
        else begin
            state <= nxt_state;
            if(load_rec) rec_out <= rec_in;
            else begin
                if(rec_out.oper1_sel === OP_SRC & rec_out.operand_1[2:0] === cdb_in.data_src)
                    {rec_out.oper1_sel, rec_out.operand_1} <= {OP_VAL, cdb_in.data};
                if(rec_out.oper2_sel === OP_SRC & rec_out.operand_2[2:0] === cdb_in.data_src)
                    {rec_out.oper2_sel, rec_out.operand_2} <= {OP_VAL, cdb_in.data};
            end
        end
    end

    assign led = state !== RC_EMPTY;

    always_comb begin
        busy = 0;
        initiate = 0;
        load_rec = 0;
        rdy_next = 0;
        nxt_state = state;
        case (state)
            RC_EMPTY:begin
                rdy_next = 1;
                if(avil_in) begin
                    load_rec = 1;
                    if(speculated)
                        nxt_state = RC_SPEC;
                    else
                        nxt_state = RC_WAIT;
                end
            end
            RC_WAIT: if(ready & dispatch) begin
                    initiate = 1;
                    busy = 1;
                    nxt_state = RC_OCCU;
            end
            RC_SPEC:begin
                rdy_next = wrong_spec;
                if(wrong_spec & ~avil_in) //clear record, wrong spec
                    nxt_state = RC_EMPTY;
                else if(wrong_spec & avil_in) begin //clear and update
                    load_rec = 1;
                    if(speculated)
                        nxt_state = RC_SPEC;
                    else
                        nxt_state = RC_WAIT;
                end
                else if(right_spec) begin //resolved correctly, initiate
                    if(ready & dispatch) begin
                        initiate = 1;
                        busy = 1;
                        nxt_state = RC_OCCU;
                    end
                    else nxt_state = RC_WAIT;
                end
            end
            RC_OCCU: begin
                busy = 1;
                rdy_next = next;
                if(next & ~avil_in) //done with no pending, go to empty
                    nxt_state = RC_EMPTY;
                else if(next) begin //done with pending issue
                    load_rec = 1;
                    if(speculated)
                        nxt_state = RC_SPEC;
                    else
                        nxt_state = RC_WAIT;
                end
            end
        endcase
    end
endmodule

//speculation off
module reservation_station(rec_in, consume_out, cdb_in, rst_n, clk, speculated, right_spec, wrong_spec,
                           alu_rec_out, alu_init, mem_rec_out, mem_init, alu_ack, mem_ack, mem_ext, mem_ext_out,
                           mul_rec_out, mul_init, mul_ack, div_rec_out, div_init, div_ack, 
                           jbr_ext1, jbr_ext1_out, jbr_ext2, jbr_ext2_out, cur_pc, cur_pc_out, mem_valid,
                           jbr_rec_out, jbr_spec_pc, jbr_spec_pc_out, jbr_init, jbr_ack, alu_addr, alu_sel,
                           /*FOR test*/led);
    parameter XLEN = 32;

    input logic rst_n, clk;
    input logic [XLEN-1:0] jbr_ext1, jbr_ext2, jbr_spec_pc, cur_pc;
    input logic [XLEN-1:0] mem_ext;
    input inst_to_rs_t rec_in;
    input logic speculated, right_spec, wrong_spec;
    input CDB_t cdb_in;

    output logic consume_out, mem_valid;
    output inst_to_rs_t alu_rec_out, mul_rec_out, div_rec_out, mem_rec_out, jbr_rec_out;
    output logic [XLEN-1:0] jbr_ext1_out, jbr_ext2_out, jbr_spec_pc_out, cur_pc_out;
    output logic [XLEN-1:0] mem_ext_out;
    output logic alu_init, alu_ack, mul_init, mul_ack, div_init, div_ack, mem_init, mem_ack, jbr_init, jbr_ack;
    output fu_addr_t alu_addr, alu_sel;
    output logic [7:0] led;

    logic alu_cons, mul_cons, div_cons, mem_cons, jbr_cons;

    assign consume_out = alu_cons | mul_cons | div_cons | mem_cons | jbr_cons | (rec_in.exec_addr === FU_NULL); //auto consume nop

    assign led[7] = speculated;

    //alu
    logic alu0_rdy_next, alu1_rdy_next, alu0_cons, alu1_cons, alu0_init, alu1_init, alu0_ack, alu1_ack;
    inst_to_rs_t alu0rec, alu1rec;
    assign alu_sel = alu0_rdy_next ? FU_ALU0 : FU_ALU1;
    assign alu_ack = alu0_ack | alu1_ack;
    assign alu_cons = alu0_cons | alu1_cons;
    reserved_record r_alu0(.rdy_next(alu0_rdy_next), .dispatch(1'b1), .rec_in(rec_in), .avil_in(rec_in.exec_addr === FU_ALU0 & alu_sel === FU_ALU0 & ~speculated),
                           .next(cdb_in.data_src === FU_ALU0), .busy(),
                           .rec_out(alu0rec), .rec_in_cons(alu0_cons), .initiate(alu0_init),
                           .clk(clk), .rst_n(rst_n), .speculated, .right_spec, .wrong_spec, .cdb_in, .fu_ack(alu0_ack), .internal_load(), .led(led[0]));
    reserved_record r_alu1(.rdy_next(alu1_rdy_next), .dispatch(~alu0_init), .rec_in(rec_in), .avil_in(rec_in.exec_addr === FU_ALU0 & alu_sel === FU_ALU1 & ~speculated),
                           .next(cdb_in.data_src === FU_ALU1), .busy(),
                           .rec_out(alu1rec), .rec_in_cons(alu1_cons), .initiate(alu1_init),
                           .clk(clk), .rst_n(rst_n), .speculated, .right_spec, .wrong_spec, .cdb_in, .fu_ack(alu1_ack), .internal_load(), .led());
    always_comb begin
        if(alu0_init) begin
            alu_rec_out = alu0rec;
            alu_init = alu0_init;
            alu_addr = FU_ALU0;
        end
        else begin
            alu_rec_out = alu1rec;
            alu_init = alu1_init;
            alu_addr = FU_ALU1;
        end
    end

    // mul
    reserved_record r_mul( .rdy_next(), .rec_in(rec_in), .dispatch(1'b1), .avil_in(rec_in.exec_addr === FU_MUL & ~speculated), .next(cdb_in.data_src === FU_MUL),
                           .rec_out(mul_rec_out), .rec_in_cons(mul_cons), .initiate(mul_init), .busy(),
                           .clk(clk), .rst_n(rst_n), .speculated, .right_spec, .wrong_spec, .cdb_in, .fu_ack(mul_ack), .internal_load(), .led());

    //div
    reserved_record r_div( .rdy_next(), .rec_in(rec_in), .dispatch(1'b1), .avil_in(rec_in.exec_addr === FU_DIV & ~speculated), .next(cdb_in.data_src === FU_DIV),
                           .rec_out(div_rec_out), .rec_in_cons(div_cons), .initiate(div_init), .busy(),
                           .clk(clk), .rst_n(rst_n), .speculated, .right_spec, .wrong_spec, .cdb_in, .fu_ack(div_ack), .internal_load(), .led());
    
    //memory
    logic mem_load;
    reserved_record r_mem( .rdy_next(), .rec_in(rec_in), .dispatch(1'b1), .avil_in(rec_in.exec_addr === FU_MEM & ~speculated), .next(cdb_in.data_src === FU_MEM),
                           .rec_out(mem_rec_out), .rec_in_cons(mem_cons), .initiate(mem_init), .busy(mem_valid),
                           .clk(clk), .rst_n(rst_n), .speculated, .right_spec, .wrong_spec, .cdb_in, .fu_ack(mem_ack), .internal_load(mem_load), .led(led[1]));
    //an extra record for mem write
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n)
            mem_ext_out <= 0;
        else if(mem_load)
            mem_ext_out <= mem_ext;
    end


    //jump/branch
    //branch reg1, reg2 => rec, pc&imm => extra
    //jal(r) reg/pc => rec, imm => extra
    logic jbr_load;
    reserved_record r_jbr( .rdy_next(), .rec_in(rec_in), .dispatch(1'b1), .avil_in(rec_in.exec_addr === FU_JBR & ~speculated), .next(cdb_in.data_src === FU_JBR),
                           .rec_out(jbr_rec_out), .rec_in_cons(jbr_cons), .initiate(jbr_init), .busy(),
                           .clk(clk), .rst_n(rst_n), .speculated, .right_spec, .wrong_spec, .cdb_in, .fu_ack(jbr_ack), .internal_load(jbr_load), .led(led[2]));
    //extra records for jump/branch
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n)begin
            jbr_ext1_out <= 0;
            jbr_ext2_out <= 0;
            jbr_spec_pc_out <= 0;
            cur_pc_out <= 0;
        end
        else if(jbr_load)begin
            jbr_ext1_out <= jbr_ext1;
            jbr_ext2_out <= jbr_ext2;
            jbr_spec_pc_out <= jbr_spec_pc;
            cur_pc_out <= cur_pc;
        end
    end
endmodule

module cdb_drv(cdb_out, alu0_in, alu0_done, alu0_addr, mul_in, mul_done, div_in, div_done, 
                mem_in, mem_done, jbr_done, jbr_in);
    parameter XLEN = 32;

    input [XLEN-1:0] alu0_in, mul_in, div_in, mem_in, jbr_in;
    input fu_addr_t alu0_addr;
    input alu0_done, mul_done, div_done, mem_done, jbr_done; 

    output CDB_t cdb_out;

    //mux
    always_comb begin
        if(jbr_done) //jump,branch has top priority
            {cdb_out.data_src, cdb_out.data} = {FU_JBR, jbr_in};
        else if(alu0_done)
            {cdb_out.data_src, cdb_out.data} = {alu0_addr, alu0_in};
        else if(div_done) // div can be longer, given more priority
            {cdb_out.data_src, cdb_out.data} = {FU_DIV, div_in};
        else if(mem_done)
            {cdb_out.data_src, cdb_out.data} = {FU_MEM, mem_in};
        else if(mul_done)
            {cdb_out.data_src, cdb_out.data} = {FU_MUL, mul_in};
        else cdb_out = 0;
    end
endmodule