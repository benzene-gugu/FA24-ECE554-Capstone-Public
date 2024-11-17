import m_rv32::*;
module br(re1, re2, pc_sel, funct, out_pc_sel);
    parameter XLEN = 32;
    
    input logic signed [XLEN-1:0] re1, re2;
    input new_pc_src_t pc_sel;
    input logic [2:0] funct;
    output new_pc_src_t out_pc_sel;

    logic br_result;
    logic [XLEN-1:0] u_re1, u_re2;

    assign out_pc_sel = ((pc_sel === PC_FROM_BRA) & br_result) ? PC_FROM_ALU : pc_sel;
    assign u_re1 = re1;
    assign u_re2 = re2;

    always_comb begin
        casez (funct)
            3'b00?: br_result = (re1 === re2)^funct[0];//BEQ/BNE
            3'b1??: br_result = (funct[1] ? u_re1 < u_re2 : re1 < re2)^funct[0];//BLTU/BLT/BGEU/BGE
            default: br_result = 0; //err has minimal impact
        endcase
    end
endmodule

//priority
//jump/branch
//jal(r) reg/imm => rec2, pc => extra
//branch reg1, reg2 => rec, pc&imm => extra
//ext_bits=0 jmp
//ext_bits=1 branch
module br_jmp(rec_in, ext1, ext2, spec_pc, pc_out, right, wrong, out, init, done, cur_pc, clk, rst_n, ack);
    parameter XLEN = 32;

    input inst_to_rs_t rec_in;
    input logic [XLEN-1:0] ext1, ext2, spec_pc, cur_pc;
    input logic init, clk, rst_n, ack;

    output logic [XLEN-1:0] pc_out, out;
    output logic right, wrong, done;

    mem_addr_t target_addr, pc_4;
    logic spec_match, do_transfer;
    logic signed [XLEN-1:0] s_re1, s_re2;
    logic [XLEN-1:0] c_out;

    assign s_re1 = rec_in.operand_1;
    assign s_re2 = rec_in.operand_2;

    assign pc_4 = cur_pc + 4;
    assign target_addr = do_transfer ? ((rec_in.ext_bits===0 ? rec_in.operand_1 : ext2) + ext1)
                                     : pc_4;//trade time for area?
    assign pc_out = target_addr; //fine to always have a output, since not always take output
    assign spec_match = target_addr === spec_pc;

    assign c_out = pc_4;

    always_comb begin
        right = 0;
        wrong = 0;
        do_transfer = 0;
        if(init & ~rec_in.ext_bits)begin //jump
            do_transfer = 1; //always jump
            wrong = ~spec_match;
            right = spec_match;
        end
        else if(init & rec_in.ext_bits)begin//branch
            casez (rec_in.funct3)
                3'b00?: do_transfer = (rec_in.operand_1 === rec_in.operand_2)^rec_in.funct3[0];//BEQ/BNE
                3'b1??: do_transfer = (rec_in.funct3[1] ? rec_in.operand_1 < rec_in.operand_2 : s_re1 < s_re2)^rec_in.funct3[0];//BLTU/BLT/BGEU/BGE
                default: do_transfer = 0; //err has minimal impact
            endcase
            wrong = ~spec_match;
            right = spec_match;
        end
    end
    //flops
    always_ff @(posedge clk, negedge rst_n)
        if(~rst_n)begin
            done <= 0;
            out <= 0;
        end
        else if(init) begin
            done <= 1;
            out <= c_out;
        end
        else if(ack) //no new task, reset
            done <= 0;
endmodule