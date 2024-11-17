import m_rv32::*;
module reg_wb_mux(wb_src, alu, pc4, mrdata, reg_wb_data, reg_wen);
    parameter XLEN = 32;
    output logic reg_wen;
    output logic [XLEN-1:0] reg_wb_data;
    input reg_wb_src_t wb_src;
    input logic [XLEN-1:0] alu, pc4, mrdata;

    assign reg_wen = |wb_src;

    always_comb begin
        casez (wb_src)
            REG_FROM_ALU: reg_wb_data = alu;
            REG_FROM_MEM: reg_wb_data = mrdata;
            REG_FROM_PC4: reg_wb_data = pc4; 
            default: reg_wb_data = 'x;
        endcase
    end

endmodule

module pc_wb_mux(pc_out, pc_src, pc4, alu);
    parameter XLEN = 32;

    input new_pc_src_t pc_src;
    input logic [XLEN-1:0] pc4, alu;
    output logic [XLEN-1:0] pc_out;

    assign pc_out = pc_src[0] ? alu : pc4;
endmodule