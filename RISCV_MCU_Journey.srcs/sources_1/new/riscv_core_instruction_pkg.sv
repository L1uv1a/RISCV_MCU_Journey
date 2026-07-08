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
    /*------------PARAMETERS FOR RISCV CORE USE------------*/
    parameter PC_RESET = 32'h0000_0000;
    // Parameters for IMEM interfaces
    parameter INSTR_WIDTH = 32;
    parameter IMEM_ADDR_WIDTH = 32;
    parameter PC_WIDTH = 32;
    // Parameters for internal IFU signals
    parameter INSTR_DATA_WIDTH = 32;
    parameter INSTR_ADDR_WIDTH = 20;
    parameter REG_DATA_WIDTH = 32;
    parameter REG_ADDR_WIDTH = 5;
    // Parameters for internal IDU and EXU signals
    parameter COMPUTE_ELEMENT_LIST = 3;
    parameter COMPUTE_ELEMENT_BIT_WIDTH = $clog2(COMPUTE_ELEMENT_LIST);
    parameter COMPUTE_ELEMENT_SUB_FUNC_CHOICE = 8;
    parameter COMPUTE_ELEMENT_SUB_FUNC_CHOICE_BIT_WIDTH = $clog2(COMPUTE_ELEMENT_SUB_FUNC_CHOICE);
    parameter LOAD_STORE_ELEMENT_LIST = 9;
    parameter LOAD_STORE_ELEMENT_BIT_WIDTH = $clog2(LOAD_STORE_ELEMENT_LIST);

    parameter AXI4LITE_ADDR_WIDTH = 32;
    parameter AXI4LITE_DATA_WIDTH = 32;
    /*------------ENUMERATIONS FOR RISCV FORMAT------------*/
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
        logic [REG_ADDR_WIDTH-1:0] rs2;
        logic [REG_ADDR_WIDTH-1:0] rs1;
        funct3_imm_enum_t funct3;
        logic [REG_ADDR_WIDTH-1:0] rd;
        opcode_enum_t opcode;
    } r_type_instr_t;

    // I-type instruction format
    typedef struct packed {
        logic [11:0] imm;
        logic [REG_ADDR_WIDTH-1:0] rs1;
        logic [2:0] funct3;
        logic [REG_ADDR_WIDTH-1:0] rd;
        opcode_enum_t opcode;
    } i_type_instr_t;

    // S-type instruction format
    typedef struct packed {
        logic [11:5] imm_high;
        logic [REG_ADDR_WIDTH-1:0] rs2;
        logic [REG_ADDR_WIDTH-1:0] rs1;
        logic [2:0] funct3;
        logic [REG_ADDR_WIDTH-1:0] imm_low;
        opcode_enum_t opcode;
    } s_type_instr_t;

    // B-type instruction format
    typedef struct packed {
        logic imm_12;
        logic [10:5] imm_10_5;
        logic [REG_ADDR_WIDTH-1:0] rs2;
        logic [REG_ADDR_WIDTH-1:0] rs1;
        logic [2:0] funct3;
        logic [3:0] imm_4_1;
        logic imm_11;
        opcode_enum_t opcode;
    } b_type_instr_t;

    // U-type instruction format
    typedef struct packed {
        logic [31:12] imm;
        logic [REG_ADDR_WIDTH-1:0] rd;
        opcode_enum_t opcode;
    } u_type_instr_t;

    // J-type instruction format
    typedef struct packed {
        logic imm_20;
        logic [10:1] imm_10_1;
        logic imm_11;
        logic [7:0] imm_19_12;
        logic [REG_ADDR_WIDTH-1:0] rd;
        opcode_enum_t opcode;
    } j_type_instr_t;

    // Union
    typedef union packed {
        logic [INSTR_DATA_WIDTH-1:0] instr;
        r_type_instr_t r_type;
        i_type_instr_t i_type;
        s_type_instr_t s_type;
        b_type_instr_t b_type;
        u_type_instr_t u_type;
        j_type_instr_t j_type;
    } rv32_instruction_t;

    /*------------ENUMERATIONS AND PARAMETERS FOR INTERNAL CORE USE------------*/
    typedef enum logic [COMPUTE_ELEMENT_BIT_WIDTH-1:0] {
        ADDER, // 0
        LOGIC,
        SHIFTER
        // XOR_GATE, // 1
        // OR_GATE, // 2
        // AND_GATE, // 3
        // COMPARATOR, // 4
        // LEFT_LOGIC_SHIFTER, // 5
        // RIGHT_LOGIC_SHIFTER, // 6
        // RIGHT_ARITHMETIC_SHIFTER // 7
    } id_compute_sel_enum;

    typedef enum logic [COMPUTE_ELEMENT_SUB_FUNC_CHOICE_BIT_WIDTH-1:0] {
        ADD,
        SUB,
        EQUAL,
        NOT_EQUAL,
        LESS_THAN, // <
        LESS_THAN_UNSIGNED, // <
        GREATER_THAN, // >=
        GREATER_THAN_UNSIGNED // >=
    } id_adder_sub_func_enum;

    typedef enum logic [COMPUTE_ELEMENT_SUB_FUNC_CHOICE_BIT_WIDTH-1:0] {
        XOR,
        OR,
        AND
    } id_logic_sub_func_enum;

    typedef enum logic [COMPUTE_ELEMENT_SUB_FUNC_CHOICE_BIT_WIDTH-1:0] {
        LEFT_LOGIC_SHIFT,
        RIGHT_LOGIC_SHIFT,
        RIGHT_ARITHMETIC_SHIFT
    } id_shift_sub_func_enum;

    typedef union packed {
        logic [COMPUTE_ELEMENT_SUB_FUNC_CHOICE_BIT_WIDTH-1:0] sub_func_sel;
        id_adder_sub_func_enum adder_choose;
        id_logic_sub_func_enum logic_choose;
        id_shift_sub_func_enum shifter_choose;
    } id_sub_func_sel_enum_t;

    typedef enum logic [LOAD_STORE_ELEMENT_BIT_WIDTH-1:0] { // First 2 bit: number of bytes, 3rd bit: signed/unsigned, 4th bit: load/store
        NONE = 4'b0000,
        LOAD_1BYTE = 4'b0001,
        LOAD_2BYTE = 4'b0010,
        LOAD_4BYTE = 4'b0011,
        LOAD_1BYTE_UNSIGNED = 4'b0101,
        LOAD_2BYTE_UNSIGNED = 4'b0110,
        STORE_1BYTE = 4'b1001,
        STORE_2BYTE = 4'b1010,
        STORE_4BYTE = 4'b1011
    } id_load_store_sel_enum;
endpackage
