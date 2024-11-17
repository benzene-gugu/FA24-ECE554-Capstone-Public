import m_rv32::*;
//make sure all out signals after fetch are transparent read ??? or should not
module cpu(clk, rst_n);
    parameter XLEN = 32;

    input logic clk, rst_n;


    logic [31:0] fetch_curr_pc_out, fetch_inst_out;
    new_pc_src_t dec_new_pc_src;
    reg_wb_src_t dec_reg_wb_src;
    logic dec_alu_opt, dec_mw, dec_mr, dec_re1_ren, dec_re2_ren;
    alu_a_sel_t dec_alu_a_sel;
    alu_b_sel_t dec_alu_b_sel;
    sext_type_t dec_sext_sel;
    logic [4:0] dec_rs1_sel, dec_rs2_sel;
    logic [2:0] dec_alu_funct3;
    logic [XLEN-1:0] dec_r1_data, dec_r2_data, dec_uimm, dec_imm;

    logic [XLEN-1:0] ex_alu_out;
    new_pc_src_t ex_new_pc_sel;
    
    logic [4:0] wb_reg_sel;
    logic [XLEN-1:0] wb_reg_data;

    logic [XLEN-1:0] mem_rdata;

    logic wb_reg_wen;
    logic [XLEN-1:0] wb_next_pc_in2fetch;

    assign wb_reg_sel = fetch_inst_out[11:7];
    
    //fetch
    fetch ifetch(.next_pc_in(wb_next_pc_in2fetch), .curr_pc_out(fetch_curr_pc_out), .inst_out(fetch_inst_out),
                 .update_next_pc(1), .clk, .rst_n);
    //decode
    decode idec(.inst(fetch_inst_out), .new_pc_src(dec_new_pc_src), .alu_opt(dec_alu_opt), .reg_wb_src(dec_reg_wb_src),
                .mw(dec_mw), .mr(dec_mr), .alu_a_sel(dec_alu_a_sel), .alu_b_sel(dec_alu_b_sel), .sext_sel(dec_sext_sel),
                .rs1_sel(dec_rs1_sel), .rs2_sel(dec_rs2_sel), .alu_funct3(dec_alu_funct3), .re1_ren(dec_re1_ren), .re2_ren(dec_re2_ren));
    RegFile ireg(.clk, .rst_n, .re1_sel(dec_rs1_sel), .re2_sel(dec_rs2_sel), .wrt_sel(wb_reg_sel), .w_data(wb_reg_data),
                 .w_en(wb_reg_wen), .r1_data(dec_r1_data), .r2_data(dec_r2_data), .r1(dec_re1_ren), .r2(dec_re2_ren));
    signext isext(.inst(fetch_inst_out), .out(dec_imm), .sel(dec_sext_sel));
    U_ext iUext(.inst(fetch_inst_out), .out(dec_uimm));
    //execute
    logic [XLEN-1:0] ex_alu_a, ex_alu_b;
    ALU_b_mux amuxa(.r2(dec_r2_data), .imm(dec_imm), .uimm(dec_uimm), .sel(dec_alu_b_sel), .out(ex_alu_b));
    ALU_a_mux amuxb(.r1(dec_r1_data), .pc(fetch_curr_pc_out), .sel(dec_alu_a_sel), .out(ex_alu_a));
    ALU ialu(.in_a(ex_alu_a), .in_b(ex_alu_b), .funct3(dec_alu_funct3), .opt(dec_alu_opt), .out(ex_alu_out));
    br ibr(.re1(dec_r1_data), .re2(dec_r2_data), .pc_sel(dec_new_pc_src), .funct(fetch_inst_out[14:12]), .out_pc_sel(ex_new_pc_sel));
    //memory
    logic [XLEN-1:0] mem_maddr, mem_mrdata, mem_mwdata;
    logic mem_mre, mem_mwr, mem_mbusy;
    Dummy_Mem dmem(.addr(mem_maddr), .data_in(mem_mwdata), .data_out(mem_mrdata), .mr(mem_mre), .mw(mem_mwr),
                   .clk, .rst_n, .busy(mem_mbusy), .wfunct3(fetch_inst_out[14:12]));
    sysbus ibus(.addr(ex_alu_out), .wdata(dec_r2_data), .re(dec_mr), .wr(dec_mw), .rdata(mem_rdata),
                .o_maddr(mem_maddr), .o_mwdata(mem_mwdata), .o_mre(mem_mre), .o_mwr(mem_mwr), .i_mrdata(mem_mrdata), .i_mbusy(mem_mbusy),
                .o_saddr(), .o_swdata(), .o_sre(), .o_swr(), .i_srdata(0),
                .o_busy());
    //writeback
    reg_wb_mux rwb(.wb_src(dec_reg_wb_src), .alu(ex_alu_out), .pc4(fetch_curr_pc_out+4), .mrdata(mem_rdata), .reg_wb_data(wb_reg_data), .reg_wen(wb_reg_wen));
    pc_wb_mux pcwb(.pc_out(wb_next_pc_in2fetch), .pc_src(ex_new_pc_sel), .pc4(fetch_curr_pc_out+4), .alu(ex_alu_out));
endmodule