import m_rv32::*;
module Sign_Ext(in, out);
    input logic [19:0] in;
    output logic [31:0] out;
    
    assign out[19:0] = in;
    assign out[31:20] = {12{in[19]}};
endmodule

module U_ext(inst, out);
    input logic [31:0] inst;
    output logic [31:0] out;

    assign out = {inst[31:12], 12'b0};
endmodule

module signext(inst, out, sel);
    input logic [31:0] inst;
    input sext_type_t sel;
    output logic [31:0] out;
    

    always_comb begin
        out[31:11] = {21{inst[31]}};
        out[10:5]  = inst[30:25];
        case(sel)
            SEXT_I: begin
                out[4:1] = inst[24:21];
                out[0] = inst[20];
            end
            SEXT_S: begin
                out[4:0] = inst[11:7];
            end
            SEXT_B: begin
                out[11] = inst[7];
                out[4:0] = {inst[11:8], 1'b0};
            end
            SEXT_J: begin
                out[19:11] = {inst[19:12], inst[20]};
                out[4:0] = {inst[24:21], 1'b0};
            end
        endcase
    end
endmodule