import m_rv32::*;
module decode(clk, rst_n, inst, new_pc_src, alu_opt, reg_wb_src, mw, mr, alu_a_sel, alu_b_sel, sext_sel, rs1_sel, rs2_sel, alu_funct3, re1_ren, re2_ren, inst_ret);
	input clk, rst_n, inst_ret;
	input inst_t inst;
	output new_pc_src_t new_pc_src;
	output reg_wb_src_t reg_wb_src;
	output logic alu_opt, mw, mr;
	output alu_a_sel_t alu_a_sel;
	output alu_b_sel_t alu_b_sel;
	output sext_type_t sext_sel;
	output logic [2:0] alu_funct3;
	output logic [4:0] rs1_sel, rs2_sel;
	output logic re1_ren, re2_ren;

	opcode_t opcode;
	logic [31:0] csr_out;

	assign opcode = opcode_t'(inst[6:0]);

	csr iCSR(.clk, .rst_n, .csr_addr(inst[31:20]), .csr_out, .inst_ret(1'b0), .branch_miss(1'b0));

	always_comb begin
		new_pc_src = PC_FROM_NOC;
		reg_wb_src = REG_FROM_NOC;
		mw = 0;
		mr = 0;
		alu_opt = 0;
		alu_a_sel = alu_a_sel_t'('x);
		alu_b_sel = alu_b_sel_t'('x);
		sext_sel = sext_type_t'('x);
		alu_funct3 = inst[14:12];

		rs1_sel = inst[19:15];
		rs2_sel = inst[24:20];
		re1_ren = 0;
		re2_ren = 0;

		case(opcode)
			NOP:;
			SYSTEM: if(|inst[14:12])begin
				rs1_sel = 0;
				reg_wb_src = REG_FROM_ALU;
				alu_a_sel = ALU_A_R1;
				re1_ren = 1;
				alu_funct3 = 3'b000;
				alu_b_sel = ALU_B_CSR;
			end
			OP_IMM: begin
				reg_wb_src = REG_FROM_ALU;
				alu_opt = inst[14:12] === 3'b101 ? inst[30] : 0;
				alu_a_sel = ALU_A_R1;
				re1_ren = 1;
				alu_b_sel = ALU_B_IMM;
				sext_sel = SEXT_I;
			end
			LUI: begin
				rs1_sel = 0;
				reg_wb_src = REG_FROM_ALU;
				alu_a_sel = ALU_A_R1;
				re1_ren = 1;
				alu_funct3 = 3'b000;
				alu_b_sel = ALU_B_UIMM;
			end
			AUIPC: begin
				reg_wb_src = REG_FROM_ALU;
				alu_a_sel = ALU_A_PC;
				alu_funct3 = 3'b000;
				alu_b_sel = ALU_B_UIMM;
			end
			OP: begin
				alu_opt = inst[30];
				reg_wb_src = REG_FROM_ALU;
				alu_a_sel = ALU_A_R1;
				re1_ren = 1;
				alu_b_sel = ALU_B_R2;
				re2_ren = 1;
			end
			JAL: begin
				sext_sel = SEXT_J;
				reg_wb_src = REG_FROM_PC4;
				alu_a_sel = ALU_A_PC;
				alu_b_sel = ALU_B_IMM;
				alu_funct3 = 3'b000;
				new_pc_src = PC_FROM_ALU;
			end
			JALR: begin
				sext_sel = SEXT_I;
				reg_wb_src = REG_FROM_PC4;
				alu_a_sel = ALU_A_R1;
				re1_ren = 1;
				alu_b_sel = ALU_B_IMM;
				alu_funct3 = 3'b000;
				new_pc_src = PC_FROM_ALU;
			end
			BRANCH: begin
				sext_sel = SEXT_B;
				alu_a_sel = ALU_A_PC;
				alu_b_sel = ALU_B_IMM;
				alu_funct3 = 3'b000;
				new_pc_src = PC_FROM_BRA;
				re1_ren = 1;
				re2_ren = 1;
			end
			LOAD: begin
				reg_wb_src = REG_FROM_MEM;
				sext_sel = SEXT_I;
				alu_a_sel = ALU_A_R1;
				re1_ren = 1;
				alu_b_sel = ALU_B_IMM;
				alu_funct3 = 3'b000;
				mr = 1;
			end
			STORE: begin
				sext_sel = SEXT_S;
				alu_a_sel = ALU_A_R1;
				re1_ren = 1;
				alu_b_sel = ALU_B_IMM;
				alu_funct3 = 3'b000;
				re2_ren = 1;
				mw = 1;
			end
			default:;
		endcase
	end
endmodule

//pure combinational decode, flops are later in RV
module decode_pipe(inst, inst_ready, rst_n, clk, cdb_in, wrong_spec, right_spec, cur_pc, rv_getnext,
				   rec_out, jbr_ext1, jbr_ext2, speculated, mem_ext, stall_out, alu_sel, i_hit, i_miss, d_hit, d_miss);
	parameter XLEN = 32;

	input inst_t inst;
	input logic inst_ready, wrong_spec, right_spec, rst_n, clk, rv_getnext;
	input CDB_t cdb_in;
	input fu_addr_t alu_sel;
	input logic [XLEN-1:0] cur_pc;
	input logic i_hit, i_miss, d_hit, d_miss;

	output logic speculated, stall_out;
	output inst_to_rs_t rec_out;
	output logic [XLEN-1:0] jbr_ext1, jbr_ext2, mem_ext;

	opcode_t opcode;
	sext_type_t sext_sel;

	assign opcode = opcode_t'(inst[6:0]);

	logic [4:0] r1, r2, rd;
	logic [XLEN-1:0] r1_data, r2_data, sext_imm, uimm;
	fu_addr_t wrt_src;
	logic w_en, r1_d_sel, r2_d_sel, speculate_next;
	logic [31:0] csr_out;


	assign r1 = inst[19:15];
	assign r2 = inst[24:20];
	assign rd = inst[11:7];

	assign stall_out = ~rv_getnext; //even nop will be acked, if not, there is a stall.

	//speculation state reg
	always_ff @(posedge clk, negedge rst_n)
		if(~rst_n)
			speculated <= 0;
		else if(speculate_next & rv_getnext)
			speculated <= 1;
		else if(right_spec | wrong_spec)
			speculated <= 0;
	//assign speculated = speculated_reg & ~right_spec; //on right_spec, clear spec bit of current inst

	RegFile_ooo regs(.clk, .rst_n, .re1_sel(r1), .re2_sel(r2), .wrt_sel(rd),
	                 .wrt_src, .w_en, .r1_data, .r1_d_sel, .r2_data, .r2_d_sel, .cdb(cdb_in));

	signext sext(.inst, .out(sext_imm), .sel(sext_sel));
	U_ext uimm_e(.inst, .out(uimm));

	csr iCSR(.clk, .rst_n, .csr_addr(inst[31:20]), .csr_out, .inst_ret(|(cdb_in.data_src)), .branch_miss(1'b0), .i_hit, .i_miss, .d_hit, .d_miss);
	always_comb begin
		w_en = 0;
		rec_out = 'x;
		rec_out.exec_addr = FU_NULL;
		rec_out.oper1_sel = OP_VAL;
		rec_out.oper2_sel = OP_VAL;
		wrt_src = fu_addr_t'('x);
		sext_sel = sext_type_t'('x);
		jbr_ext1 = 0;
		jbr_ext2 = 0;
		mem_ext = 0;
		speculate_next = 0;

		if(inst_ready & ~wrong_spec) case(opcode) //wrong spec: discard current inst
			OP_IMM: begin
				w_en = 1'b1 & rv_getnext;
				wrt_src = alu_sel;

				rec_out.exec_addr = FU_ALU0;
				rec_out.funct3 = inst[14:12];
				rec_out.ext_bits = inst[14:12] === 3'b101 ? inst[30] : 0;
				rec_out.oper1_sel = op_sel_t'(r1_d_sel);
				rec_out.operand_1 = r1_data;
				rec_out.oper2_sel = OP_VAL;
				rec_out.operand_2 = sext_imm;
				sext_sel = SEXT_I;
			end
			LUI: begin
				w_en = 1'b1 & rv_getnext;
				wrt_src = alu_sel;

				rec_out.exec_addr = FU_ALU0;
				rec_out.funct3 = 3'b000;
				rec_out.ext_bits = 0;
				rec_out.oper1_sel = OP_VAL;
				rec_out.operand_1 = 0;
				rec_out.oper2_sel = OP_VAL;
				rec_out.operand_2 = uimm;
			end
			AUIPC: begin
				w_en = 1'b1 & rv_getnext;
				wrt_src = alu_sel;

				rec_out.exec_addr = FU_ALU0;
				rec_out.funct3 = 3'b000;
				rec_out.ext_bits = 0;
				rec_out.oper1_sel = OP_VAL;
				rec_out.operand_1 = cur_pc;
				rec_out.oper2_sel = OP_VAL;
				rec_out.operand_2 = uimm;
			end
			OP: begin
				w_en = 1'b1 & rv_getnext;
				wrt_src = inst[25] ? (inst[14] ? FU_DIV : FU_MUL) : alu_sel;
				
				rec_out.exec_addr = inst[25] ? (inst[14] ? FU_DIV : FU_MUL) : FU_ALU0; 
				rec_out.funct3 = inst[14:12];
				rec_out.ext_bits = inst[30];
				rec_out.oper1_sel = op_sel_t'(r1_d_sel);
				rec_out.operand_1 = r1_data;
				rec_out.oper2_sel = op_sel_t'(r2_d_sel);
				rec_out.operand_2 = r2_data;
			end
			//jal(r) reg/pc => rec, imm => extra
			JAL: begin
				w_en = 1'b1 & rv_getnext;
				wrt_src = FU_JBR;

				speculate_next = 1;

				sext_sel = SEXT_J;
				rec_out.exec_addr = FU_JBR;
				rec_out.ext_bits = 0;
				rec_out.oper1_sel = OP_VAL;
				rec_out.operand_1 = cur_pc;
				jbr_ext1 = sext_imm;
			end
			JALR: begin
				w_en = 1'b1 & rv_getnext;
				wrt_src = FU_JBR;

				speculate_next = 1;

				sext_sel = SEXT_I;
				rec_out.exec_addr = FU_JBR;
				rec_out.ext_bits = 0;
				rec_out.oper1_sel = op_sel_t'(r1_d_sel);
				rec_out.operand_1 = r1_data;
				jbr_ext1 = sext_imm;
			end

			//branch reg1, reg2 => rec, pc&imm => extra
			BRANCH: begin
				speculate_next = 1;
				
				sext_sel = SEXT_B;
				rec_out.exec_addr = FU_JBR;
				rec_out.ext_bits = 1;
				rec_out.funct3 = inst[14:12];
				rec_out.oper1_sel = op_sel_t'(r1_d_sel);
				rec_out.operand_1 = r1_data;
				rec_out.oper2_sel = op_sel_t'(r2_d_sel);
				rec_out.operand_2 = r2_data;

				jbr_ext1 = sext_imm;
				jbr_ext2 = cur_pc;
			end
			LOAD: begin
				w_en = 1'b1 & rv_getnext;
				wrt_src = FU_MEM;

				sext_sel = SEXT_I;
				rec_out.exec_addr = FU_MEM;
				rec_out.ext_bits = 0;//read
				rec_out.funct3 = inst[14:12];
				rec_out.oper1_sel = op_sel_t'(r1_d_sel);
				rec_out.operand_1 = r1_data;
				mem_ext = sext_imm;
			end
			STORE: begin
				sext_sel = SEXT_S;
				rec_out.exec_addr = FU_MEM;
				rec_out.ext_bits = 1;//write
				rec_out.funct3 = inst[14:12];
				rec_out.oper1_sel = op_sel_t'(r1_d_sel);
				rec_out.operand_1 = r1_data;
				rec_out.oper2_sel = op_sel_t'(r2_d_sel);
				rec_out.operand_2 = r2_data;
				mem_ext = sext_imm;
			end
			SYSTEM: if(|inst[14:12] & (inst[31:20] >= 12'hc00 && inst[31:20] <= 12'hc9f))begin
				w_en = 1'b1 & rv_getnext;
				wrt_src = alu_sel;

				rec_out.exec_addr = FU_ALU0;
				rec_out.funct3 = 3'b000;
				rec_out.ext_bits = 0;
				rec_out.oper1_sel = OP_VAL;
				rec_out.operand_1 = 0;
				rec_out.oper2_sel = OP_VAL;
				rec_out.operand_2 = csr_out;
			end
			default:;
		endcase
	end
endmodule
