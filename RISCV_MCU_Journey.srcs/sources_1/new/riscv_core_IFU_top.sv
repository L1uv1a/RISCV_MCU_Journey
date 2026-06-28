`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02/07/2026 03:03:43 PM
// Design Name:
// Module Name: riscv_core_IFU_top
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

module riscv_core_IFU_top # (

)(
    // Clock and Reset
    input logic       if_sys_clk_i,
    input logic       if_sys_rst_n_i,

    // Instruction Memory Interface
    output logic [IMEM_ADDR_WIDTH-1:0]    imem_instr_addr_o,
    input  logic [INSTR_WIDTH-1:0]        imem_instr_data_i,
    output logic                          imem_instr_en_o,

    // Control Signals
    input  logic                          if_stage_stall_i,
    input  logic                          if_flush_i,

    // Output to the next stage (IDU)
    output logic                          if_instr_valid_o,
    output logic [INSTR_WIDTH-1:0]        if_instr_o,
    output logic [PC_WIDTH-1:0]           if_pc_o,
    output logic [PC_WIDTH-1:0]           if_next_pc_o
    );

    logic [INSTR_ADDR_WIDTH-1:0]    current_pc;
    logic [INSTR_ADDR_WIDTH-1:0]    next_pc;
    logic [INSTR_ADDR_WIDTH-1:0]    current_pc_reg1;
    logic [INSTR_ADDR_WIDTH-1:0]    current_pc_reg2;
    logic [INSTR_WIDTH-1:0]         imem_instr_data;

    logic                           imem_instr_en_reg;
    logic                           imem_instr_en_reg1;
    logic                           imem_instr_en_reg2;

    always_comb begin
        next_pc = current_pc + 2;   // Increment PC by 4 (32 bit instruction) for the next instruction

        imem_instr_addr_o = { {(IMEM_ADDR_WIDTH - INSTR_ADDR_WIDTH - 1){1'b0}}, current_pc, 1'b0 }; // Align to word boundary
        imem_instr_en_o = imem_instr_en_reg;

        if_instr_valid_o = imem_instr_en_reg2;
        if_instr_o = imem_instr_data_i;
        if_pc_o =  { {(IMEM_ADDR_WIDTH - INSTR_ADDR_WIDTH - 1){1'b0}}, current_pc_reg2, 1'b0 };
        if_next_pc_o = { {(IMEM_ADDR_WIDTH - INSTR_ADDR_WIDTH - 1){1'b0}}, current_pc_reg1, 1'b0 };
    end
    always_ff @( posedge if_sys_clk_i or negedge if_sys_rst_n_i ) begin
        if ( !if_sys_rst_n_i ) begin
            current_pc <= PC_RESET;
            current_pc_reg1 <= 0;
            current_pc_reg2 <= 0;
            imem_instr_en_reg <= 0;
            imem_instr_en_reg1 <= 0;
            imem_instr_en_reg2 <= 0;
        end else begin
            current_pc <= next_pc;
            current_pc_reg1 <= current_pc;
            current_pc_reg2 <= current_pc_reg1;

            imem_instr_en_reg <= 1;
            imem_instr_en_reg1 <= imem_instr_en_reg;
            imem_instr_en_reg2 <= imem_instr_en_reg1;
        end
    end
endmodule
