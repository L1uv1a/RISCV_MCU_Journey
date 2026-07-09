`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02/07/2026 03:07:41 PM
// Design Name:
// Module Name: riscv_core_WBU_top
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


module riscv_core_WBU_top(
    input logic       wb_sys_clk_i,
    input logic       wb_sys_rst_n_i,

    // signal interface from EXU
    input logic                                    wb_ex_req_i,
    input logic [REG_DATA_WIDTH-1:0]               wb_ex_rd_data_i,
    input logic [REG_ADDR_WIDTH-1:0]               wb_ex_rd_addr_i,
    output logic                                   wb_ex_gnt_o,

    input logic                                    wb_lsu_req_i,
    input logic [REG_DATA_WIDTH-1:0]               wb_lsu_rd_data_i,
    input logic [REG_ADDR_WIDTH-1:0]               wb_lsu_rd_addr_i,
    output logic                                   wb_lsu_gnt_o,

    input logic [PC_WIDTH-1:0]                     wb_pc_i,
    input logic [PC_WIDTH-1:0]                     wb_next_pc_i,

    // Signal to Register File
    output logic [REG_ADDR_WIDTH-1:0]              wb_rf_rd_addr_o,
    output logic                                   wb_rf_rd_wen_o,
    output logic [REG_DATA_WIDTH-1:0]              wb_rf_rd_data_o,
    // Signal to Pipeline Control Unit
    output logic                                   wb_valid_o, // Might not use
    output logic                                   wb_ready_o
);

always_comb begin : rd_selection_logic
    if (wb_lsu_req_i) begin
        wb_rf_rd_addr_o = wb_lsu_rd_addr_i;
        wb_rf_rd_data_o = wb_lsu_rd_data_i;
        wb_rf_rd_wen_o  = 1'b1;
        wb_lsu_gnt_o    = 1'b1;
        wb_ex_gnt_o     = 1'b0;
        wb_valid_o      = 1'b1;
    end else if (wb_ex_req_i) begin
        wb_rf_rd_addr_o = wb_ex_rd_addr_i;
        wb_rf_rd_data_o = wb_ex_rd_data_i;
        wb_rf_rd_wen_o  = 1'b1;
        wb_ex_gnt_o     = 1'b1;
        wb_lsu_gnt_o    = 1'b0;
        wb_valid_o      = 1'b1;
    end else begin
        wb_rf_rd_addr_o = wb_ex_rd_addr_i;
        wb_rf_rd_data_o = wb_ex_rd_data_i;
        wb_rf_rd_wen_o  = 1'b0;
        wb_ex_gnt_o     = 1'b0;
        wb_lsu_gnt_o    = 1'b0;
        wb_valid_o      = 1'b0;
    end
end

endmodule
