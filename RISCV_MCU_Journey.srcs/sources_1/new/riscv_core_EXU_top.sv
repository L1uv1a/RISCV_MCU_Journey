`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02/07/2026 03:05:32 PM
// Design Name:
// Module Name: riscv_core_EXU_top
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

module riscv_core_EXU_top #(

)(
    input logic       ex_sys_clk_i,
    input logic       ex_sys_rst_n_i,

    input logic                             ex_instr_valid_i,
    input logic [PC_WIDTH-1:0]              ex_pc_i,
    input logic [PC_WIDTH-1:0]              ex_next_pc_i,
    // input logic                             ex_jump_taken_i,
    input logic                             ex_branch_detected_i,

    input logic [COMPUTE_ELEMENT_BIT_WIDTH-1:0]                  ex_compute_sel_i,
    input logic [COMPUTE_ELEMENT_SUB_FUNC_CHOICE_BIT_WIDTH-1:0]  ex_sub_func_sel_i,
    input logic [LOAD_STORE_ELEMENT_BIT_WIDTH-1:0]               ex_load_store_sel_i,
    input logic [REG_DATA_WIDTH-1:0]                             ex_rs1_data_i,
    input logic [REG_DATA_WIDTH-1:0]                             ex_rs2_data_i,
    input logic [REG_DATA_WIDTH-1:0]                             ex_rs2_data_to_store_i,
    input logic [REG_ADDR_WIDTH-1:0]                             ex_rd_addr_i,

    // Outputs to the next stage (LSU or WB)
    output logic [LOAD_STORE_ELEMENT_BIT_WIDTH-1:0]              ex_load_store_sel_o,
    output logic [REG_DATA_WIDTH-1:0]                            ex_rd_data_o,
    output logic [REG_ADDR_WIDTH-1:0]                            ex_rd_addr_o,
    output logic [REG_DATA_WIDTH-1:0]                            ex_rs2_data_to_store_o,
    output logic [PC_WIDTH-1:0]                                  ex_pc_o,
    output logic [PC_WIDTH-1:0]                                  ex_next_pc_o,
    // output logic                                                 ex_jump_taken_o,
    output logic                                                 ex_branch_taken_o
);

logic [REG_DATA_WIDTH-1:0] compute_element_adder_output;
logic compute_element_adder_carry_out;
logic compute_element_adder_overflow;
logic [REG_DATA_WIDTH-1:0] compute_element_logic_output;
logic [REG_DATA_WIDTH-1:0] compute_element_shifter_output;

logic [REG_DATA_WIDTH-1:0] ex_rd_data;
logic ex_branch_taken;

// always_comb begin : input_block
//     ex_rd_addr = ex_rd_addr_i;
//     ex_rs2_data_to_store = ex_rs2_data_to_store_i;
//     ex_pc = ex_pc_i;
//     ex_next_pc = ex_next_pc_i;
//     ex_jump_taken = ex_jump_taken_i;
// end

riscv_core_multipurpose_adder adder_inst (
    .sub_func_sel_i(ex_sub_func_sel_i),
    .first_operand_i(ex_rs1_data_i),
    .second_operand_i(ex_rs2_data_i),
    .carry_out_o(compute_element_adder_carry_out),
    .overflow_o(compute_element_adder_overflow),
    .output_value_o(compute_element_adder_output)
);

riscv_core_multipurpose_logic logic_inst (
    .sub_func_sel_i(ex_sub_func_sel_i),
    .first_operand_i(ex_rs1_data_i),
    .second_operand_i(ex_rs2_data_i),
    .output_value_o(compute_element_logic_output)
);

riscv_core_multipurpose_shifter shifter_inst (
    .sub_func_sel_i(ex_sub_func_sel_i),
    .first_operand_i(ex_rs1_data_i),
    .second_operand_i(ex_rs2_data_i),
    .output_value_o(compute_element_shifter_output)
);

always_comb begin : output_selection
    case (ex_compute_sel_i)
        ADDER: begin
            case (ex_sub_func_sel_i)
                ADD: begin
                    ex_rd_data = compute_element_adder_output;
                end
                SUB: begin
                    ex_rd_data = compute_element_adder_output;
                end
                EQUAL: begin
                    ex_rd_data = compute_element_adder_output;
                end
                NOT_EQUAL: begin
                    ex_rd_data = compute_element_adder_output;
                end
                LESS_THAN: begin
                    ex_rd_data = {31'b0, (compute_element_adder_output[0] ^ compute_element_adder_overflow)};
                end
                LESS_THAN_UNSIGNED: begin
                    ex_rd_data = {31'b0, !compute_element_adder_carry_out};
                end
                GREATER_THAN: begin
                    ex_rd_data = {31'b0, !(compute_element_adder_output[0] ^ compute_element_adder_overflow)};
                end
                GREATER_THAN_UNSIGNED: begin
                    ex_rd_data = {31'b0, compute_element_adder_carry_out};
                end
            endcase
        end
        LOGIC: begin
            ex_rd_data = compute_element_logic_output;
        end
        SHIFTER: begin
            ex_rd_data = compute_element_shifter_output;
        end
        default: begin
            ex_rd_data = {REG_DATA_WIDTH{1'b0}};
        end
    endcase
end

always_comb begin : branch_detection
    case (ex_sub_func_sel_i)
        EQUAL: begin
            ex_branch_taken = (compute_element_adder_output == 0);
        end
        NOT_EQUAL: begin
            ex_branch_taken = (compute_element_adder_output != 0);
        end
        LESS_THAN: begin
            ex_branch_taken = (compute_element_adder_output[0] ^ compute_element_adder_overflow) && ex_branch_detected_i;
        end
        LESS_THAN_UNSIGNED: begin
            ex_branch_taken = !compute_element_adder_carry_out && ex_branch_detected_i;
        end
        GREATER_THAN: begin
            ex_branch_taken = !(compute_element_adder_output[0] ^ compute_element_adder_overflow) && ex_branch_detected_i;
        end
        GREATER_THAN_UNSIGNED: begin
            ex_branch_taken = compute_element_adder_carry_out && ex_branch_detected_i;
        end
        default: begin //Pure ADD and SUB operations, no branch detection
            ex_branch_taken = 1'b0;
        end
    endcase
end

always_comb begin : output_block
    ex_load_store_sel_o     = ex_load_store_sel_i;
    ex_rd_data_o            = ex_rd_data;
    ex_rd_addr_o            = ex_rd_addr_i;
    ex_rs2_data_to_store_o  = ex_rs2_data_to_store_i;
    ex_pc_o                 = ex_pc_i;
    ex_next_pc_o            = ex_next_pc_i;
    // ex_jump_taken_o         = ex_jump_taken;
    ex_branch_taken_o       = ex_branch_taken;
end

endmodule
