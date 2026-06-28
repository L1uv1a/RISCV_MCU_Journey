`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02/07/2026 03:04:50 PM
// Design Name:
// Module Name: riscv_core_IDU_top
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

import rv32i_instr_pkg::*;

module riscv_core_IDU_top #(

)(
    input logic       id_sys_clk_i,
    input logic       id_sys_rst_n_i,

    // Input from IFU
    input logic                          id_instr_valid_i,
    input logic [INSTR_DATA_WIDTH-1:0]   id_instr_i,
    input logic [PC_WIDTH-1:0]           id_pc_i,
    input logic [PC_WIDTH-1:0]           id_next_pc_i,

    // Output to EXU
    output logic                                                  id_instr_valid_o,
    output logic [COMPUTE_ELEMENT_BIT_WIDTH-1:0]                  id_compute_sel_o,
    output logic [COMPUTE_ELEMENT_SUB_FUNC_CHOICE_BIT_WIDTH-1:0]  id_sub_func_sel_o,
    output logic [LOAD_STORE_ELEMENT_BIT_WIDTH-1:0]               id_load_store_sel_o,
    // output logic [INSTR_DATA_WIDTH-1:0]          id_instr_o,
    output logic [REG_DATA_WIDTH-1:0]                             id_rs1_data_o,
    output logic [REG_DATA_WIDTH-1:0]                             id_rs2_data_o,
    output logic [REG_DATA_WIDTH-1:0]                             id_rs2_data_to_store_o,
    output logic [REG_ADDR_WIDTH-1:0]                             id_rd_addr_o,
    output logic [PC_WIDTH-1:0]                                   id_pc_o,
    output logic [PC_WIDTH-1:0]                                   id_next_pc_o,

    output logic                                                  id_jump_taken_o,
    output logic                                                  id_branch_detected_o,

    // Data from RF
    input logic [REG_DATA_WIDTH-1:0]     id_rs1_data_i,
    input logic [REG_DATA_WIDTH-1:0]     id_rs2_data_i,
    // Control signals to RF
    output logic                         id_rs1_en_o,
    output logic [REG_ADDR_WIDTH-1:0]    id_rs1_addr_o,
    output logic                         id_rs2_en_o,
    output logic [REG_ADDR_WIDTH-1:0]    id_rs2_addr_o
    );


    logic                          id_instr_valid;
    logic                          id_jump_taken;
    logic                          id_branch_detected;
    // logic [INSTR_DATA_WIDTH-1:0]   id_instr;
    logic [REG_DATA_WIDTH-1:0]     id_rs1_data;
    logic [REG_DATA_WIDTH-1:0]     id_rs2_data;
    logic [REG_DATA_WIDTH-1:0]     id_rs2_data_to_store;
    logic [REG_ADDR_WIDTH-1:0]     id_rd_addr;
    logic [PC_WIDTH-1:0]           id_pc;
    logic [PC_WIDTH-1:0]           id_pc_jump;
    logic [PC_WIDTH-1:0]           id_next_pc;
    opcode_enum_t                  opcode;

    rv32_instruction_t      decoded_instr; // Decoded instruction fields
    id_compute_sel_enum     id_compute_sel;
    id_sub_func_sel_enum_t  id_sub_func_sel;
    id_load_store_sel_enum  id_load_store_sel;
    assign decoded_instr    = id_instr_i;
    assign opcode           = decoded_instr.r_type.opcode;
    logic [REG_DATA_WIDTH-1:0] imm_value; // Immediate value extracted from instruction
    always_comb begin
        case (opcode)
            OP_LUI: begin
                id_jump_taken           = 1'b0; // LUI does not cause a jump
                id_branch_detected      = 1'b0; // LUI does not cause a branch

                imm_value               = {decoded_instr.u_type.imm, 12'b0}; // U-type immediate is upper 20 bits
                id_rs1_en_o             = 1'b1;     // Dummy read to take reg 0 is always 0
                id_rs1_addr_o           = 5'b0;   // Dummy read to take reg 0 is always 0
                id_rs2_en_o             = 1'b0;     // No second source register
                id_rs2_addr_o           = 5'b0;   // No second source register
                id_rs2_data_to_store    = '0; // No data to store
                id_compute_sel          = LOGIC;
                id_sub_func_sel         = OR;
                id_load_store_sel       = NONE;
                id_rs1_data             = id_rs1_data_i; // Dummy read to take reg 0 is always 0
                id_rs2_data             = imm_value;
                id_rd_addr              = decoded_instr.u_type.rd;

                id_pc                   = id_pc_i;
                id_pc_jump              = 32'd4; // Default next PC is current PC + 4
            end
            OP_AUIPC: begin
                id_jump_taken           = 1'b0; // AUIPC does not cause a jump
                id_branch_detected      = 1'b0; // AUIPC does not cause a branch

                imm_value = {decoded_instr.u_type.imm, 12'b0}; // U-type immediate is upper 20 bits
                id_rs1_en_o             = 1'b0;     // Read PC as rs1
                id_rs1_addr_o           = 5'b0;   // Dummy read to take reg 0 is always 0
                id_rs2_en_o             = 1'b0;     // No second source register
                id_rs2_addr_o           = 5'b0;   // No second source register
                id_rs2_data_to_store    = '0; // No data to store
                id_compute_sel          = ADDER;
                id_sub_func_sel         = ADD;
                id_load_store_sel       = NONE;
                id_rs1_data             = id_pc_i;
                id_rs2_data             = imm_value;
                id_rd_addr              = decoded_instr.u_type.rd;

                id_pc                   = id_pc_i;
                id_pc_jump              = 32'd4;

            end
            OP_IMM: begin
                id_jump_taken           = 1'b0; // OP-IMM does not cause a jump
                id_branch_detected      = 1'b0; // OP-IMM does not cause a branch

                imm_value = {{20{decoded_instr.i_type.imm[11]}}, decoded_instr.i_type.imm}; // Sign-extend 12-bit immediate
                id_rs1_en_o             = 1'b1;     // Enable rs1
                id_rs1_addr_o           = decoded_instr.i_type.rs1;
                id_rs1_data             = id_rs1_data_i;
                id_rs2_en_o             = 1'b0;     // No second source register
                id_rs2_addr_o           = 5'b0;   // No second source register
                id_rs2_data             = imm_value;
                id_rs2_data_to_store    = '0;
                id_rd_addr              = decoded_instr.i_type.rd;
                id_load_store_sel       = NONE;

                id_pc                   = id_pc_i;
                id_pc_jump              = 32'd4;
                case (decoded_instr.i_type.funct3)
                    FUNCT3_ADDI: begin
                        id_compute_sel = ADDER;
                        id_sub_func_sel = ADD;
                    end
                    FUNCT3_SLTI: begin
                        id_compute_sel = ADDER;
                        id_sub_func_sel = LESS_THAN;
                    end
                    FUNCT3_SLTIU: begin
                        id_compute_sel = ADDER;
                        id_sub_func_sel = LESS_THAN_UNSIGNED;
                    end
                     FUNCT3_XORI: begin
                        id_compute_sel = LOGIC;
                        id_sub_func_sel = XOR;
                    end
                    FUNCT3_ORI: begin
                        id_compute_sel = LOGIC;
                        id_sub_func_sel = OR;
                    end
                    FUNCT3_ANDI: begin
                        id_compute_sel = LOGIC;
                        id_sub_func_sel = AND;
                    end
                    FUNCT3_SLLI: begin
                        id_compute_sel = SHIFTER;
                        id_sub_func_sel = LEFT_LOGIC_SHIFT;
                    end
                    FUNCT3_SRLI_SRAI: begin
                        id_compute_sel = SHIFTER;
                        if (imm_value[10]) begin
                            id_sub_func_sel = RIGHT_ARITHMETIC_SHIFT;
                        end
                        else begin
                            id_sub_func_sel = RIGHT_LOGIC_SHIFT;
                        end
                    end
                    default: begin
                        id_compute_sel = LOGIC; // Default to LOGIC for unsupported funct3
                        id_sub_func_sel = OR; // Default to OR for unsupported funct3
                    end
                endcase
            end
            OP_REG: begin
                id_jump_taken           = 1'b0; // OP-REG does not cause a jump
                id_branch_detected      = 1'b0; // OP-REG does not cause a branch

                imm_value               = 32'd0; // No immediate value for OP-REG instructions
                id_rs1_en_o             = 1'b1;     // Enable rs1
                id_rs1_addr_o           = decoded_instr.r_type.rs1;
                id_rs1_data             = id_rs1_data_i;
                id_rs2_en_o             = 1'b1;     // Enable rs2
                id_rs2_addr_o           = decoded_instr.r_type.rs2;
                id_rs2_data             = id_rs2_data_i;
                id_rs2_data_to_store    = '0;
                id_rd_addr              = decoded_instr.r_type.rd;
                id_load_store_sel       = NONE;

                id_pc                   = id_pc_i;
                id_pc_jump              = 32'd4;
                case (decoded_instr.r_type.funct3)
                    FUNCT3_ADD_SUB: begin
                        id_compute_sel = ADDER;
                        id_sub_func_sel = (decoded_instr.r_type.funct7[5]) ? SUB : ADD; // Use funct7 to differentiate between ADD and SUB
                    end
                    FUNCT3_SLT: begin
                        id_compute_sel = ADDER;
                        id_sub_func_sel = LESS_THAN;
                    end
                    FUNCT3_SLTU: begin
                        id_compute_sel = ADDER;
                        id_sub_func_sel = LESS_THAN_UNSIGNED;
                    end
                     FUNCT3_XOR: begin
                        id_compute_sel = LOGIC;
                        id_sub_func_sel = XOR;

                    end
                    FUNCT3_OR: begin
                        id_compute_sel = LOGIC;
                        id_sub_func_sel = OR;
                    end
                    FUNCT3_AND: begin
                        id_compute_sel = LOGIC;
                        id_sub_func_sel = AND;
                    end
                    FUNCT3_SLL: begin
                        id_compute_sel = SHIFTER;
                        id_sub_func_sel = LEFT_LOGIC_SHIFT;
                    end
                    FUNCT3_SRL_SRA: begin
                      id_compute_sel = SHIFTER;
                        if (imm_value[10]) begin
                            id_sub_func_sel = RIGHT_ARITHMETIC_SHIFT;
                        end
                        else begin
                            id_sub_func_sel = RIGHT_LOGIC_SHIFT;
                        end
                    end
                    default: begin
                        id_compute_sel = LOGIC; // Default to LOGIC for unsupported funct3
                        id_sub_func_sel = XOR; // Default to XOR for unsupported funct3
                    end
                endcase
            end
            OP_FENCE: begin // FENCE instruction is not implemented in this design
                id_jump_taken           = 1'b0; // Default to no jump
                id_branch_detected      = 1'b0; // Default to no branch

                imm_value               = 32'd0; // No immediate value for FENCE instruction
                id_rs1_en_o             = 1'b0;     // Disable rs1
                id_rs1_addr_o           = 5'b0;
                id_rs1_data             = '0;
                id_rs2_en_o             = 1'b0;     // Disable rs2
                id_rs2_addr_o           = 5'b0;
                id_rs2_data             = '0;
                id_rs2_data_to_store    = '0;
                id_rd_addr              = 5'b0;
                id_compute_sel          = LOGIC; // Default to LOGIC for unsupported opcode
                id_sub_func_sel         = OR;   // Default to OR for unsupported opcode
                id_load_store_sel       = NONE; // Default to NONE for unsupported opcode

                id_pc                   = id_pc_i;
                id_pc_jump              = 32'd4;
            end
            OP_SYSTEM: begin // SYSTEM instruction is not implemented in this design (FUTURE PLAN)
                id_jump_taken           = 1'b0; // Default to no jump
                id_branch_detected      = 1'b0; // Default to no branch

                imm_value               = 32'd0; // No immediate value for SYSTEM instruction
                id_rs1_en_o             = 1'b0;     // Disable rs1
                id_rs1_addr_o           = 5'b0;
                id_rs1_data             = '0;
                id_rs2_en_o             = 1'b0;     // Disable rs2
                id_rs2_addr_o           = 5'b0;
                id_rs2_data             = '0;
                id_rs2_data_to_store    = '0;
                id_rd_addr              = 5'b0;
                id_compute_sel          = LOGIC; // Default to LOGIC for unsupported opcode
                id_sub_func_sel         = OR;   // Default to OR for unsupported opcode
                id_load_store_sel       = NONE; // Default to NONE for unsupported opcode

                id_pc                   = id_pc_i;
                id_pc_jump              = 32'd4;
            end
            OP_LOAD: begin // LOAD instruction has the same format as I type instructions
                id_jump_taken           = 1'b0; // LOAD does not cause a jump
                id_branch_detected      = 1'b0; // LOAD does not cause a branch

                imm_value               = {{20{decoded_instr.i_type.imm[11]}}, decoded_instr.i_type.imm};
                id_rs1_en_o             = 1'b1;     // Enable rs1
                id_rs1_addr_o           = decoded_instr.i_type.rs1;
                id_rs1_data             = id_rs1_data_i;
                id_rs2_en_o             = 1'b0;     // No second source register
                id_rs2_addr_o           = 5'b0;   // No second source register
                id_rs2_data             = imm_value;
                id_rd_addr              = decoded_instr.i_type.rd;
                id_compute_sel          = ADDER;
                id_sub_func_sel         = ADD;
                id_rs2_data_to_store    = '0;

                id_pc                   = id_pc_i;
                id_pc_jump              = 32'd4;
                case (decoded_instr.i_type.funct3)
                    FUNCT3_LB: begin
                        id_load_store_sel   = LOAD_1BYTE;
                    end
                    FUNCT3_LH: begin
                        id_load_store_sel   = LOAD_2BYTE;
                    end
                    FUNCT3_LW: begin
                        id_load_store_sel   = LOAD_4BYTE;
                    end
                    FUNCT3_LBU: begin
                        id_load_store_sel   = LOAD_1BYTE_UNSIGNED;
                    end
                    FUNCT3_LHU: begin
                        id_load_store_sel   = LOAD_2BYTE_UNSIGNED;
                    end
                    default: begin
                        id_load_store_sel   = LOAD_1BYTE;
                    end
                endcase
            end
            OP_STORE: begin
                id_jump_taken           = 1'b0; // STORE does not cause a jump
                id_branch_detected      = 1'b0; // STORE does not cause a branch
                id_pc_jump              = 32'd4; // Default next PC is current PC + 4

                imm_value               = {{20{decoded_instr.s_type.imm_high[11]}},
                                            decoded_instr.s_type.imm_high,
                                            decoded_instr.s_type.imm_low}; // S-type immediate is split between two fields
                id_rs1_en_o             = 1'b1;     // Enable rs1
                id_rs1_addr_o           = decoded_instr.s_type.rs1;
                id_rs1_data             = id_rs1_data_i;
                id_rs2_en_o             = 1'b1;     // Enable rs2
                id_rs2_addr_o           = decoded_instr.s_type.rs2;   // Source register for store instruction
                id_rs2_data             = imm_value; // Use id_rs2_data to use the same adder for address calculation
                id_rs2_data_to_store    = id_rs2_data_i; // Data to be stored in memory
                id_rd_addr              = '0; // No destination register for store instructions
                id_compute_sel          = ADDER;
                id_sub_func_sel         = ADD;

                id_pc                   = id_pc_i;
                id_pc_jump              = 32'd4;
                case (decoded_instr.s_type.funct3)
                    FUNCT3_SB: begin
                        id_load_store_sel = STORE_1BYTE;
                    end
                    FUNCT3_SH: begin
                        id_load_store_sel = STORE_2BYTE;
                    end
                    FUNCT3_SW: begin
                        id_load_store_sel = STORE_4BYTE;
                    end
                    default: begin
                        id_load_store_sel = STORE_1BYTE;
                    end
                endcase
            end
            OP_JAL: begin
                id_jump_taken           = 1'b1; // JAL causes a jump
                id_branch_detected      = 1'b0; // JAL does not cause a branch
                imm_value               = {{12{decoded_instr.j_type.imm_20}},
                                            decoded_instr.j_type.imm_20,
                                            decoded_instr.j_type.imm_19_12,
                                            decoded_instr.j_type.imm_11,
                                            decoded_instr.j_type.imm_10_1}; // Reconstruct J-type offset from its fields
                id_rs1_en_o             = 1'b0;     // Disable rs1
                id_rs1_addr_o           = 5'b0;
                id_rs1_data             = id_pc_i;  // Use current PC as rs1 data for ADDER
                id_rs2_en_o             = 1'b0;     // Disable rs2
                id_rs2_addr_o           = 5'b0;     // Source register for store instruction
                id_rs2_data             = 32'd4;    // PC = PC + 4 for JAL will be calculate in Execution stage
                id_rs2_data_to_store    = '0;
                id_rd_addr              = decoded_instr.j_type.rd;
                id_compute_sel          = ADDER;
                id_sub_func_sel         = ADD;
                id_load_store_sel       = NONE;

                id_pc                   = id_pc_i;
                id_pc_jump              = imm_value;
            end
            OP_JALR: begin // JALR instruction has the same format as I type instructions
                id_jump_taken           = 1'b1; // JALR causes a jump
                id_branch_detected      = 1'b0; // JAL does not cause a branch
                id_pc_jump              = {{20{decoded_instr.i_type.imm[11]}}, decoded_instr.i_type.imm};
                id_rs1_en_o             = 1'b1;     // Enable rs1
                id_rs1_addr_o           = decoded_instr.i_type.rs1;
                id_rs1_data             = id_rs1_data_i;
                id_rs2_en_o             = 1'b0;     // Disable rs2
                id_rs2_addr_o           = 5'b0;
                id_rs2_data             = 32'd4;    // PC = PC + 4 for JALR will be calculate in Execution stage
                id_rs2_data_to_store    = '0;
                id_rd_addr              = decoded_instr.j_type.rd;
                id_pc                   = id_rs1_data;
                id_compute_sel          = ADDER;
                id_sub_func_sel         = ADD;
                id_load_store_sel       = NONE;

                id_pc                   = id_pc_i;
                id_pc_jump              = 32'd4;
            end
            OP_BRANCH: begin
                id_jump_taken           = 1'b0; // OP-BRANCH does not cause a jump
                id_branch_detected      = 1'b1; // OP-BRANCH might cause a branch

                imm_value               = {{20{decoded_instr.b_type.imm_12}},
                                            decoded_instr.b_type.imm_12,
                                            decoded_instr.b_type.imm_11,
                                            decoded_instr.b_type.imm_10_5,
                                            decoded_instr.b_type.imm_4_1}; // Reconstruct B-type offset from its fields
                id_rs1_en_o             = 1'b1;     // Enable rs1
                id_rs1_addr_o           = decoded_instr.b_type.rs1;
                id_rs1_data             = id_rs1_data_i;
                id_rs2_en_o             = 1'b1;     // Enable rs2
                id_rs2_addr_o           = decoded_instr.b_type.rs2;
                id_rs2_data             = id_rs2_data_i;
                id_rs2_data_to_store    = '0;
                id_rd_addr              = '0; // No destination register for branch instructions
                id_compute_sel          = ADDER;
                id_load_store_sel       = NONE;

                id_pc                   = id_pc_i;
                id_pc_jump              = imm_value;
                case (decoded_instr.b_type.funct3)
                    FUNCT3_BEQ: begin
                        id_sub_func_sel = EQUAL;
                    end
                    FUNCT3_BNE: begin
                        id_sub_func_sel = NOT_EQUAL;
                    end
                    FUNCT3_BLT: begin
                        id_sub_func_sel = LESS_THAN;
                    end
                    FUNCT3_BGE: begin
                        id_sub_func_sel = GREATER_THAN;
                    end
                    FUNCT3_BLTU: begin
                        id_sub_func_sel = LESS_THAN_UNSIGNED;
                    end
                    FUNCT3_BGEU: begin
                        id_sub_func_sel = GREATER_THAN_UNSIGNED;
                    end
                    default: begin
                        id_sub_func_sel = EQUAL; // Default to EQUAL for unsupported funct3
                    end
                endcase
            end
            default: begin
                id_jump_taken       = 1'b0; // Default to no jump
                id_branch_detected  = 1'b0; // Default to no branch
                id_pc_jump          = 32'd4; // Default next PC is current PC + 4
                id_rs1_en_o         = 1'b0;     // Disable rs1
                id_rs1_addr_o       = 5'b0;
                id_rs1_data         = '0;
                id_rs2_en_o         = 1'b0;     // Disable rs2
                id_rs2_addr_o       = 5'b0;
                id_rs2_data         = '0;
                id_rs2_data_to_store = '0;
                id_rd_addr          = 5'b0;
                id_compute_sel      = LOGIC; // Default to LOGIC for unsupported opcode
                id_sub_func_sel     = OR;   // Default to OR for unsupported opcode
                id_load_store_sel   = NONE; // Default to NONE for unsupported opcode
                id_pc               = id_pc_i;
            end
        endcase
    end

    assign id_next_pc               = id_pc + id_pc_jump; // Default next PC is current PC + 4, will be updated for jump/branch instructions
    assign id_instr_valid_o         = id_instr_valid_i;
    assign id_compute_sel_o         = id_compute_sel;
    assign id_sub_func_sel_o        = id_sub_func_sel;
    assign id_load_store_sel_o      = id_load_store_sel;
    assign id_rs1_data_o            = id_rs1_data;
    assign id_rs2_data_o            = id_rs2_data;
    assign id_rs2_data_to_store_o   = id_rs2_data_to_store;
    assign id_rd_addr_o             = id_rd_addr;
    assign id_pc_o                  = id_pc;
    assign id_next_pc_o             = id_next_pc;
    assign id_jump_taken_o          = id_jump_taken;
    assign id_branch_detected_o     = id_branch_detected;
endmodule
