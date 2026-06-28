`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 06/28/2026 03:54:46 PM
// Design Name:
// Module Name: riscv_core_multipurpose_shifter
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


module riscv_core_multipurpose_shifter#(

)(
    input logic [COMPUTE_ELEMENT_SUB_FUNC_CHOICE_BIT_WIDTH-1:0]  sub_func_sel_i,
    input logic [REG_DATA_WIDTH-1:0] first_operand_i,
    input logic [REG_DATA_WIDTH-1:0] second_operand_i,
    output logic [REG_DATA_WIDTH-1:0] output_value_o
);

logic [REG_DATA_WIDTH-1:0] first_operand;
logic [REG_DATA_WIDTH-1:0] second_operand;
logic [REG_DATA_WIDTH-1:0] output_value;

logic [REG_DATA_WIDTH-1:0] first_operand_reversed;
logic                      signed_fill;
logic [REG_DATA_WIDTH-1:0] shift_stage_value [0:$clog2(REG_DATA_WIDTH)];
logic [REG_DATA_WIDTH-1:0] output_value_reversed;
assign first_operand = first_operand_i;
assign second_operand = second_operand_i;
generate
    for (genvar i = 0; i < REG_DATA_WIDTH; i = i + 1) begin : reverse_operand_loop
        assign first_operand_reversed[i] = first_operand[REG_DATA_WIDTH - 1 - i];
    end
endgenerate

always_comb begin : fill_sign_bit
    signed_fill = first_operand[REG_DATA_WIDTH-1] && (sub_func_sel_i == RIGHT_ARITHMETIC_SHIFT); // Check if it's an arithmetic right shift
end

always_comb begin : shift_logic
    shift_stage_value[0] = (sub_func_sel_i == LEFT_LOGIC_SHIFT) ? first_operand_reversed : first_operand; // For left shift, use reversed bits; for right shifts, use original bits
    // shift_stage_value[1] = second_operand[0] ? ({{1{signed_fill}}, shift_stage_value[0][REG_DATA_WIDTH-1:1]}) : shift_stage_value[0];
    // shift_stage_value[2] = second_operand[1] ? ({{2{signed_fill}}, shift_stage_value[1][REG_DATA_WIDTH-1:2]}) : shift_stage_value[1];
    // shift_stage_value[3] = second_operand[2] ? ({{4{signed_fill}}, shift_stage_value[2][REG_DATA_WIDTH-1:4]}) : shift_stage_value[2];
    // shift_stage_value[4] = second_operand[3] ? ({{8{signed_fill}}, shift_stage_value[3][REG_DATA_WIDTH-1:8]}) : shift_stage_value[3];
    // shift_stage_value[5] = second_operand[4] ? ({{16{signed_fill}}, shift_stage_value[4][REG_DATA_WIDTH-1:16]}) : shift_stage_value[4];
    // For 32-bit, we only need 5 shift stages
end

generate
    for (genvar i = 1; i <= $clog2(REG_DATA_WIDTH); i++) begin : shift_logic_loop
        localparam int SHIFT = 1 << (i - 1);
        always_comb begin
            shift_stage_value[i] =
                second_operand[i-1]
                    ? {{SHIFT{signed_fill}},
                       shift_stage_value[i-1][REG_DATA_WIDTH-1:SHIFT]}
                    : shift_stage_value[i-1];
        end
    end
endgenerate

generate
    for (genvar i = 0; i < REG_DATA_WIDTH; i = i + 1) begin : reverse_output_loop
        assign output_value_reversed[i] = shift_stage_value[5][REG_DATA_WIDTH - 1 - i];
    end
endgenerate

always_comb begin : output_logic
    output_value = shift_stage_value[5];
    output_value_o = (sub_func_sel_i == LEFT_LOGIC_SHIFT) ? output_value_reversed : output_value;
end

endmodule
