import m_rv32::*;
module ALU_a_mux (r1, pc, sel, out);
    input alu_a_sel_t sel;    
    input  logic [31:0] pc, r1;
    output logic [31:0] out;

    assign out = sel === ALU_A_R1 ? r1 : pc;
endmodule
module ALU_b_mux (sel, r2, imm, uimm, out);
    input alu_b_sel_t sel;    
    input  logic [31:0] r2, imm, uimm;
    output logic [31:0] out;
    
    always_comb begin
        casez (sel)
            ALU_B_R2: out = r2; 
            ALU_B_IMM: out = imm;
            ALU_B_UIMM: out = uimm;
            default:  out = 'x;
        endcase
    end
endmodule

module ALU(in_a, in_b, funct3, opt, out);
    parameter XLEN = 32;

    input  logic signed [XLEN-1:0] in_a;
    input  logic signed [XLEN-1:0] in_b;
    input  logic [2:0]  funct3;
    input  logic        opt;
    output logic signed [XLEN-1:0] out;

    logic signed [XLEN-1:0] b; //for add|sub
    logic unsigned [XLEN-1:0] unsigned_in_b;
    logic unsigned [XLEN-1:0] unsigned_in_a;

    assign b = {XLEN{opt}}^in_b;
    assign unsigned_in_a = in_a;
    assign unsigned_in_b = in_b;

    always_comb begin
        case(funct3)
            3'b000: out = in_a + b + {{XLEN-1{1'd0}}, opt}; //ADD[I] SUB
            3'b010: out = in_a<in_b ? 1 : 0; //SLT[I]
            3'b011: out = unsigned_in_a<unsigned_in_b ? 1 : 0; //SLT[I]U
            3'b100: out = in_a^in_b; //XOR[I]
            3'b110: out = in_a|in_b; //OR[I]
            3'b111: out = in_a&in_b; //AND[I]

            3'b001: out = in_a << in_b[4:0]; //SLL[I]
            3'b101: out = opt===1 ? in_a >>> in_b[4:0] : in_a >> in_b[4:0]; //SRL[I] SRA[I]
        endcase
    end
endmodule

module alu_latched(in_a, in_b, funct3, opt, fu_out, done, ack, init, clk, rst_n, alu_addr_in, alu_addr_out);
    parameter XLEN = 32;

    input  logic signed [XLEN-1:0] in_a;
    input  logic signed [XLEN-1:0] in_b;
    input  logic [2:0]  funct3;
    input  logic        opt;
    input  logic        ack, init, clk, rst_n;
    input  fu_addr_t alu_addr_in;
    output logic signed [XLEN-1:0] fu_out;
    output logic done;
    output fu_addr_t alu_addr_out;

    logic signed [XLEN-1:0] b; //for add|sub
    logic unsigned [XLEN-1:0] unsigned_in_b;
    logic unsigned [XLEN-1:0] unsigned_in_a;
    logic signed [XLEN-1:0] out;

    assign b = {XLEN{opt}}^in_b;
    assign unsigned_in_a = in_a;
    assign unsigned_in_b = in_b;

    always_comb begin
        case(funct3)
            3'b000: out = in_a + b + {{XLEN-1{1'd0}}, opt}; //ADD[I] SUB
            3'b010: out = in_a<in_b ? 1 : 0; //SLT[I]
            3'b011: out = unsigned_in_a<unsigned_in_b ? 1 : 0; //SLT[I]U
            3'b100: out = in_a^in_b; //XOR[I]
            3'b110: out = in_a|in_b; //OR[I]
            3'b111: out = in_a&in_b; //AND[I]

            3'b001: out = in_a << in_b[4:0]; //SLL[I]
            3'b101: out = opt===1 ? in_a >>> in_b[4:0] : in_a >> in_b[4:0]; //SRL[I] SRA[I]
        endcase
    end

    //flops
    always_ff @(posedge clk, negedge rst_n)
        if(~rst_n)begin
            done <= 0;
            fu_out <= 0;
            alu_addr_out <= FU_NULL;
        end
        else if(init) begin
            done <= 1;
            fu_out <= out;
            alu_addr_out <= alu_addr_in;
        end
        else if(ack) //no new task, reset
            done <= 0;

endmodule