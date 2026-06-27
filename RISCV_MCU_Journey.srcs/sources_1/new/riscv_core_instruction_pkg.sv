`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 03/01/2026 09:56:44 PM
// Design Name:
// Module Name: riscv_core_instruction_pkg
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


package rv32i_instr_pkg;

    // RV32I OP code instruction enum
    typedef enum logic [6:0] {
        OP_LUI      = 7'b0110111,
        OP_AUIPC    = 7'b0010111,
        OP_IMM      = 7'b0010011,
        OP_REG      = 7'b0110011,
        OP_FENCE    = 7'b0001111,
        OP_SYSTEM   = 7'b1110011,
        OP_LOAD     = 7'b0000011,
        OP_STORE    = 7'b0100011,
        OP_JAL      = 7'b1101111,
        OP_JALR     = 7'b1100111,
        OP_BRANCH   = 7'b1100011
    } opcode_enum_t;

    // funct3 field enum for OP-REG instructions
    typedef enum logic [2:0] {
        FUNCT3_ADD_SUB = 3'b000,
        FUNCT3_SLL     = 3'b001,
        FUNCT3_SLT     = 3'b010,
        FUNCT3_SLTU    = 3'b011,
        FUNCT3_XOR     = 3'b100,
        FUNCT3_SRL_SRA = 3'b101,
        FUNCT3_OR      = 3'b110,
        FUNCT3_AND     = 3'b111
    } funct3_reg_enum_t;

    // funct3 field enum for OP-IMM instructions
    typedef enum logic [2:0] {
        FUNCT3_ADDI      = 3'b000,
        FUNCT3_SLLI      = 3'b001,
        FUNCT3_SLTI      = 3'b010,
        FUNCT3_SLTIU     = 3'b011,
        FUNCT3_XORI      = 3'b100,
        FUNCT3_SRLI_SRAI = 3'b101,
        FUNCT3_ORI       = 3'b110,
        FUNCT3_ANDI      = 3'b111
    } funct3_imm_enum_t;

    // funct3 field enum for STORE instructions (S-type)
    typedef enum logic [2:0] {
        FUNCT3_SB = 3'b000,
        FUNCT3_SH = 3'b001,
        FUNCT3_SW = 3'b010
    } funct3_store_enum_t;

    // funct3 field enum for LOAD instructions (I-type)
    typedef enum logic [2:0] {
        FUNCT3_LB  = 3'b000,
        FUNCT3_LH  = 3'b001,
        FUNCT3_LW  = 3'b010,
        FUNCT3_LBU = 3'b100,
        FUNCT3_LHU = 3'b101
    } funct3_load_enum_t;

    // funct3 field enum for BRANCH instructions (B-type)
    typedef enum logic [2:0] {
        FUNCT3_BEQ  = 3'b000,
        FUNCT3_BNE  = 3'b001,
        FUNCT3_BLT  = 3'b100,
        FUNCT3_BGE  = 3'b101,
        FUNCT3_BLTU = 3'b110,
        FUNCT3_BGEU = 3'b111
    } funct3_branch_enum_t;

    // funct3 field enum for Zicsr instructions (I-type)
    typedef enum logic [2:0] {
        FUNCT3_CSRRW  = 3'b001,
        FUNCT3_CSRRS  = 3'b010,
        FUNCT3_CSRRC  = 3'b011,
        FUNCT3_CSRRWI = 3'b101,
        FUNCT3_CSRRSI = 3'b110,
        FUNCT3_CSRRCI = 3'b111
    } funct3_csr_enum_t;

    // SYSTEM instructions (ECALL, EBREAK) field
    typedef enum logic [11:0] {
        ECALL  = 12'b000000000000,
        EBREAK = 12'b000000000001,
        URET   = 12'b000000000010,
        SRET   = 12'b000100000010,
        MRET   = 12'b001100000010,
        WFI    = 12'b000100000101
    } system_instr_enum_t;

    // R-type instruction format
    typedef struct packed {
        logic [6:0] funct7;
        logic [4:0] rs2;
        logic [4:0] rs1;
        funct3_imm_enum_t funct3;
        logic [4:0] rd;
        opcode_enum_t opcode;
    } r_type_instr_t;

    // I-type instruction format
    typedef struct packed {
        logic [11:0] imm;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [4:0] rd;
        opcode_enum_t opcode;
    } i_type_instr_t;

    // S-type instruction format
    typedef struct packed {
        logic [11:5] imm_high;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [4:0] imm_low;
        opcode_enum_t opcode;
    } s_type_instr_t;

    // B-type instruction format
    typedef struct packed {
        logic imm_12;
        logic [10:5] imm_10_5;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [3:0] imm_4_1;
        logic imm_11;
        opcode_enum_t opcode;
    } b_type_instr_t;

    // U-type instruction format
    typedef struct packed {
        logic [31:12] imm;
        logic [4:0] rd;
        opcode_enum_t opcode;
    } u_type_instr_t;

    // J-type instruction format
    typedef struct packed {
        logic imm_20;
        logic [10:1] imm_10_1;
        logic imm_11;
        logic [7:0] imm_19_12;
        logic [4:0] rd;
        opcode_enum_t opcode;
    } j_type_instr_t;

    // Union
    typedef union packed {
        logic [31:0] instr;
        r_type_instr_t r_type;
        i_type_instr_t i_type;
        s_type_instr_t s_type;
        b_type_instr_t b_type;
        u_type_instr_t u_type;
        j_type_instr_t j_type;
    } rv32_instruction_t;

endpackage
