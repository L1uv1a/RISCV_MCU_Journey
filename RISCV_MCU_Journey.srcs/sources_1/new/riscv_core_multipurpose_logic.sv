`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 06/28/2026 03:54:46 PM
// Design Name:
// Module Name: riscv_core_multipurpose_logic
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


module riscv_core_multipurpose_logic#(

)(
    input logic [COMPUTE_ELEMENT_SUB_FUNC_CHOICE_BIT_WIDTH-1:0]  sub_func_sel_i,
    input logic [REG_DATA_WIDTH-1:0] first_operand_i,
    input logic [REG_DATA_WIDTH-1:0] second_operand_i,
    output logic [REG_DATA_WIDTH-1:0] output_value_o
);

always_comb begin : logic_block
    case (sub_func_sel_i)
        AND: output_value_o = first_operand_i & second_operand_i;
        OR: output_value_o = first_operand_i | second_operand_i;
        XOR: output_value_o = first_operand_i ^ second_operand_i;
        default: output_value_o = {REG_DATA_WIDTH{1'b0}}; // Default case
    endcase
end
endmodule
