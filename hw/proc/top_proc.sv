import m_rv32::*;
import SDRAM_params::*; // Import the SDRAM parameters
module top_proc(rst_n, clk, peri_r, peri_w, peri_addr, peri_wdata, peri_rdata, led, clk100m,
                addr_SDRAM, request_SDRAM, ack_SDRAM, write_SDRAM, data_read_SDRAM, data_write_SDRAM, valid_SDRAM);
    input logic clk, rst_n, clk100m;

    input logic [31:0] peri_rdata;
    output peri_r, peri_w;
    output logic [27:0] peri_addr; //only lower 28 bits are used for peripherals
    output logic [31:0] peri_wdata;
    output logic [7:0] led;

    // SDRAM side signals
    output logic [23:0] addr_SDRAM; // Address signal for the SDRAM
    output logic [31:0] data_write_SDRAM; // Data write for the SDRAM
    output logic write_SDRAM; // Write signal for the SDRAM
    output logic request_SDRAM; // Request signal for the SDRAM
    input logic ack_SDRAM; // Acknowledge signal for the SDRAM
    input logic valid_SDRAM; // Valid signal indicating that the read/write data is valid
    input logic [31:0] data_read_SDRAM; // Data read for the SDRAM

    logic inst_out_ready, get_next, wrong_spec, right_spec;
    logic speculated, stall;

    logic [31:0] inst_out;

    logic [31:0] next_pc_in, pc_out, jbr_ext1, jbr_ext2, cur_pc_rv, spec_pc;
    logic [31:0] jbr_ext1_out, jbr_ext2_out, jbr_spec_pc_out, jbr_out;
    logic jbr_ack, inv_inst;

    logic [31:0] alu_out;
    logic alu_done, alu_ack, alu_init;

    logic mem_init, mem_ack, mem_done, mem_valid;
    logic [31:0] mem_out, mem_ext, mem_ext_out;

    logic [31:0] mul_out;
    logic mul_done, mul_ack, mul_init;

    logic [31:0] div_out;
    logic div_done, div_ack, div_init;

    logic [31:0] imem_addr, imem_data; //inst->rom

    logic jbr_init, jbr_done;
    inst_to_rs_t rec_out, jbr_rec_out, alu_rec_out, mul_rec_out, div_rec_out, mem_rec_out;

    fu_addr_t alu_addr, alu_addr_out, alu_sel;

    CDB_t cdb;

    //dram signals
    logic [PHYSICAL_ADDR_BITS-1:0] dc_addr, ic_addr;
    logic dc_mr, dc_mw, ic_mr, ic_inready, dc_inready;
    logic [XLEN-1:0] dc_wordin, ic_wordin, dc_wordout;

    logic comm_re, comm_we, comm_valid;
    logic [31:0] comm_addr, comm_read_data, comm_write_data;

    logic i_hit, i_miss, d_hit, d_miss;


    fetch_pipelined iFetch(.spec_pc, .next_pc_in, .pc_out, .inst_out, .inst_out_ready, .stall, .override_next_pc(wrong_spec), .clk, .rst_n, .imem_addr, .imem_data,
                           .maddr_out(ic_addr), .mr_out(ic_mr), .mword_in(ic_wordin), .min_ready(ic_inready), .inv_inst, .i_miss, .i_hit);

    decode_pipe iDec(.inst(inst_out), .inst_ready(inst_out_ready), .rst_n, .clk, .cdb_in(cdb), .wrong_spec, .right_spec, .rv_getnext(get_next),
                .cur_pc(pc_out), .rec_out(rec_out), .jbr_ext1, .jbr_ext2, .speculated, .mem_ext, .stall_out(stall), .alu_sel,
                .i_hit, .i_miss, .d_hit, .d_miss);
    
    reservation_station iRes(.rec_in(rec_out), .consume_out(get_next), .cdb_in(cdb), .rst_n, .clk, .speculated, .right_spec, .wrong_spec,
                           .alu_rec_out, .alu_init, .mem_rec_out, .mem_init, .alu_ack, .mem_ack, .mem_ext, .mem_ext_out,
                           .jbr_ext1, .jbr_ext1_out, .jbr_ext2, .jbr_ext2_out, .cur_pc(pc_out), .cur_pc_out(cur_pc_rv), .mem_valid, 
                           .mul_rec_out, .mul_init, .mul_ack, .div_rec_out, .div_init, .div_ack,
                           .jbr_rec_out, .jbr_spec_pc(spec_pc), .jbr_spec_pc_out, .jbr_init, .jbr_ack, .led, .alu_addr, .alu_sel);
    
    br_jmp iBJP(.rec_in(jbr_rec_out), .ext1(jbr_ext1_out), .ext2(jbr_ext2_out), .spec_pc(jbr_spec_pc_out), .pc_out(next_pc_in),
           .right(right_spec), .wrong(wrong_spec), .out(jbr_out), .init(jbr_init), .done(jbr_done), .cur_pc(cur_pc_rv),
           .ack(jbr_ack), .clk, .rst_n);

    alu_latched iALU(.in_a(alu_rec_out.operand_1), .in_b(alu_rec_out.operand_2), .funct3(alu_rec_out.funct3),
                .opt(alu_rec_out.ext_bits), .fu_out(alu_out), .done(alu_done), .ack(alu_ack), .init(alu_init), .clk, .rst_n,
                .alu_addr_in(alu_addr), .alu_addr_out);
    
    multiply #(.OP_LN(32)) iMul(.clk, .rst_n, .op1(mul_rec_out.operand_1), .op2(mul_rec_out.operand_2), .funct3(mul_rec_out.funct3), 
                    .start(mul_init), .ack(mul_ack), .result(mul_out), .done(mul_done));

    import divide_multi_doomed_params_pkg::*;
    divide_multi #(.OP_LN(32), .NUM_ITER(NUM_ITER), .XP_LN(XP_LEN)) iDiv(.clk, .rst_n, .op1(div_rec_out.operand_1), .op2(div_rec_out.operand_2), 
                    .funct3(div_rec_out.funct3), .start(div_init), .ack(div_ack), .result(div_out), .done(div_done));

    sysbus_pipdram iMEM(.funct3(mem_rec_out.funct3), .rst_n, .clk, .init(mem_init), .base(mem_rec_out.operand_1), .off(mem_ext_out),
                     .ack(mem_ack), .done(mem_done), .wdata(mem_rec_out.operand_2), .re(mem_valid&(~mem_rec_out.ext_bits)),
                     .wr(mem_valid&mem_rec_out.ext_bits), .rdata(mem_out), .inv_inst, .d_hit, .d_miss,
                     .imem_addr, .imem_data, .peri_r, .peri_w, .peri_addr, .peri_wdata, .peri_rdata,
                     .maddr_out(dc_addr), .mr_out(dc_mr), .mw_out(dc_mw), .mword_in(dc_wordin), .mword_out(dc_wordout), .min_ready(dc_inready));
              
    cdb_drv iCDB(.cdb_out(cdb), .alu0_in(alu_out), .alu0_done(alu_done), .mul_in(mul_out), .mul_done, .div_in(div_out), .div_done, 
                    .mem_in(mem_out), .mem_done, .jbr_done, .jbr_in(jbr_out), .alu0_addr(alu_addr_out));

    //model_sdram_ctrl_rw data_ram(.clk, .addr(dc_addr), .dataout(dc_wordin), .datain(dc_wordout), .mr(dc_mr), .mw(dc_mw), .gready(dc_inready), .rst_n);
    //model_sdram_ctrl_rw inst_ram(.clk, .addr(ic_addr), .dataout(ic_wordin), .datain(0), .mr(ic_mr), .mw(0), .gready(ic_inready), .rst_n);
    
    cache_bus icdc_bus(.inst_re(ic_mr), .inst_addr({{XLEN-PHYSICAL_ADDR_BITS{1'b0}},ic_addr}), .inst_data(ic_wordin), .inst_valid(ic_inready),
              .data_re(dc_mr), .data_we(dc_mw), .data_addr({{XLEN-PHYSICAL_ADDR_BITS{1'b0}},dc_addr}), .data_read(dc_wordin), .data_write(dc_wordout), .data_valid(dc_inready), 
              .comm_re, .comm_we, .comm_addr, .comm_read_data, .comm_write_data, .comm_valid, .clk, .rst_n);
    
     sdram_comm sdramcom(.re_CPU(comm_re), .we_CPU(comm_we), .addr_CPU(comm_addr), .data_read_CPU(comm_read_data), .data_write_CPU(comm_write_data), .valid_CPU(comm_valid), 
                         .clk_SDRAM(clk100m), .clk_CPU(clk), .rst_n,
                         .addr_SDRAM, .request_SDRAM, .ack_SDRAM, .write_SDRAM, .data_read_SDRAM, .data_write_SDRAM, .valid_SDRAM);
    
    //test sdram model for simulation only
    //model_sdram_ctrl_rw sdram(.clk, .addr(comm_addr), .dataout(comm_read_data), .datain(comm_write_data), .mr(comm_re), .mw(comm_we), .gready(comm_valid), .rst_n);
endmodule
