`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 06/28/2026 03:54:46 PM
// Design Name:
// Module Name: riscv_core_multipurpose_adder
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

module riscv_core_multipurpose_adder#(

)(
    input logic [COMPUTE_ELEMENT_SUB_FUNC_CHOICE_BIT_WIDTH-1:0]  sub_func_sel_i,
    input logic [REG_DATA_WIDTH-1:0] first_operand_i,
    input logic [REG_DATA_WIDTH-1:0] second_operand_i,
    output logic [REG_DATA_WIDTH-1:0] carry_out_o,
    output logic [REG_DATA_WIDTH-1:0] overflow_o,
    output logic [REG_DATA_WIDTH-1:0] output_value_o
);

logic [REG_DATA_WIDTH-1:0] first_operand;
logic [REG_DATA_WIDTH-1:0] second_operand;
logic [REG_DATA_WIDTH-1:0] output_value;
logic carry_out;
logic overflow;
logic subtract_selected;
logic operand_sign;

logic operand_in_sign_check;
logic output_value_sign_check;


// ADDER for self implementation of addition and subtraction
always_comb begin : adder_logic
    subtract_selected = (|sub_func_sel_i);
    first_operand = first_operand_i;
    second_operand = subtract_selected ? ~second_operand_i : second_operand_i;
    {carry_out, output_value} = first_operand + second_operand + subtract_selected;
    operand_in_sign_check = first_operand[REG_DATA_WIDTH-1] == second_operand[REG_DATA_WIDTH-1];
    output_value_sign_check = output_value[REG_DATA_WIDTH-1] != first_operand[REG_DATA_WIDTH-1];
    overflow = operand_in_sign_check && output_value_sign_check;
end

// Using Vivado IP Core for addition and subtraction
// always_comb begin : adder_logic
//     subtract_selected = (|sub_func_sel_i);
//     first_operand = first_operand_i;
//     second_operand = second_operand_i;
// end

// c_addsub_0 adder_inst (
//     .A(first_operand_i),
//     .B(second_operand_i),
//     .ADD(!subtract_selected), // Use the least significant bit of sub_func_sel_i to determine addition or subtraction
//     .C_IN('0), // No carry-in for addition/subtraction
//     .S({carry_out, output_value})
// );



// always_comb begin : overflow_logic
//     if (subtract_selected) begin
//         operand_in_sign_check = first_operand[REG_DATA_WIDTH-1] != second_operand[REG_DATA_WIDTH-1];
//     end else begin
//         operand_in_sign_check = first_operand[REG_DATA_WIDTH-1] == second_operand[REG_DATA_WIDTH-1];
//     end
//     output_value_sign_check = output_value[REG_DATA_WIDTH-1] != first_operand[REG_DATA_WIDTH-1];
//     overflow = operand_in_sign_check && output_value_sign_check;
// end


always_comb begin : output_logic
    carry_out_o = carry_out;
    overflow_o = overflow;
    output_value_o = output_value;
end

endmodule
