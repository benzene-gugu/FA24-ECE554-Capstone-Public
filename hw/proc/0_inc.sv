//littleendian
`ifndef INC_MRV32
`define INC_MRV32

package m_rv32;
	typedef logic [31:0] mem_addr_t;
	typedef logic [4:0] reg_sel_t;

	//peripherals address mapping, high 4bits are omitted
	parameter MMAP_UARTCTL = 28'h000_0000;
	parameter MMAP_UART_TR = 28'h000_0004;
	parameter MMAP_LED     = 28'h000_0010;
	parameter MMAP_HIN     = 28'h000_0020;
	parameter MMAP_SPI     = 28'h100_0000;
	parameter MMAP_FRAMEBF = 28'h200_0000;

	parameter SIZE_FRAMEBF = 28'h012_C000;

	parameter PHYSICAL_ADDR_BITS = 26;
	parameter XLEN = 32;

	typedef enum logic { OP_SRC = 1'b1, OP_VAL = 1'b0} op_sel_t;

	typedef enum  logic [2:0] { FU_NULL = 3'd0, FU_ALU0 = 3'd1, FU_ALU1 = 3'd2, FU_MEM = 3'd3, FU_JBR=3'd4, FU_MUL = 3'd5, FU_DIV = 3'd6} fu_addr_t;

	typedef struct packed {
		fu_addr_t exec_addr; //0 is invalid addr
		logic [2:0] funct3;
		logic [0:0] ext_bits;
		op_sel_t oper1_sel; //0: value, 1:renamed reg
		logic [31:0]operand_1; //regs: [6:0], [6]: special reg
		op_sel_t oper2_sel;
		logic [31:0]operand_2;
	} inst_to_rs_t;

	typedef struct packed {
		fu_addr_t data_src;
		logic [31:0]data;
	} CDB_t;
//synthesis translate_off
//synthesis translate_on


	typedef enum logic [1:0]
	{
		SEXT_I,
		SEXT_S,
		SEXT_B,
		SEXT_J
	} sext_type_t;
	//Type for opcodes
	typedef enum logic [6:0]
	{
		NOP     = 7'b000_0000,//OP_IMM
		OP_IMM  = 7'b001_0011,
		LUI     = 7'b011_0111,
		AUIPC   = 7'b001_0111,
		OP      = 7'b011_0011,

		BRANCH  = 7'b110_0011,

		JAL     = 7'b110_1111,
		JALR    = 7'b110_0111,		

		LOAD    = 7'b000_0011,
		STORE   = 7'b010_0011,

		FENCE   = 7'b000_1111,
		SYSTEM  = 7'b111_0011
	}opcode_t;

	typedef struct packed {
		logic [24:0] others;
		opcode_t opcode;
	}inst_t;

	//type for selecting new pc source
	typedef enum logic [1:0]
	{
		PC_FROM_NOC = 2'b00, //not changing new pc
		PC_FROM_ALU = 2'b01,
		PC_FROM_BRA = 2'b10
	} new_pc_src_t;

	//type from selecting reg write source
	typedef enum logic [1:0]
	{
		REG_FROM_NOC = 2'b0,
		REG_FROM_ALU,
		REG_FROM_PC4,
		REG_FROM_MEM
	} reg_wb_src_t;

	typedef enum logic
	{
		ALU_A_R1,
		ALU_A_PC
	} alu_a_sel_t;
	typedef enum logic [1:0]
	{
		ALU_B_R2,
		ALU_B_IMM,
		ALU_B_UIMM,
		ALU_B_CSR
	} alu_b_sel_t;

	//Type for funct
	/*
	 typedef enum logic [2:0]
	 {
	 ADDI,
	 SLTI,
	 SLTIU,
	 ANDI,
	 ORI,
	 XORI,
	 SRLI,
	 SRAI,

	 ADD,
	 SLT,
	 SLTU,
	 AND,
	 OR,
	 XOR,
	 SLL,
	 SRL,
	 SUB,//rs1 - rs2
	 SRA,

	 BEQ,
	 BNE,
	 BLT,
	 BLTU,
	 BGE,
	 BGEU,

	 W,
	 H,
	 HU,
	 B,
	 BU
	 }funct3_t;*/

	typedef enum logic [11:0]
	{
		ECALL,
		EBREAK
	}funct12_t;

	/*
	 typedef struct packed
	 {
	 logic [6:0] funct7;
	 reg_t rs2;
	 reg_t rs1;
	 logic [2:0] funct3;
	 reg_t rd;
	 opcode_t opcode;
	 }inst_R_t;
	 typedef struct packed
	 {
	 logic [11:0] imm;
	 reg_t rs1;
	 logic [2:0] funct3;
	 reg_t rd;
	 opcode_t opcode;
	 }inst_I_t;
	 typedef struct packed
	 {
	 logic [6:0] imm11_5;
	 reg_t rs2;
	 reg_t rs1;
	 logic [2:0] funct3;
	 logic [4:0] imm4_0;
	 opcode_t opcode;
	 }inst_S_t;
	 typedef struct packed
	 {
	 logic [19:0] imm31_12;
	 reg_t rd;
	 opcode_t opcode;
	 }inst_U_t;
	 */

endpackage
`endif
