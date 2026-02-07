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


module riscv_core_IFU_top # (
    localparam PC_RESET = 32'h0000_0000,
    parameter INSTR_WIDTH = 32,
    parameter INSTR_ADDR = 32
)(
    // Clock and Reset
    input logic         clk_i,
    input logic       rst_n_i,

    // Instruction Memory Interface
    output logic [INSTR_ADDR-1:0]   imem_instr_addr_o,
    input  logic [INSTR_WIDTH-1:0]  imem_instr_data_i,
    output logic                    imem_instr_req_o,
    output logic                    imem_instr_rst_i,

    // Control Signals
    input  logic                    if_stage_stall_i,

    // Output to the next stage
    output logic                    instr_valid_id_o,
    output logic [INSTR_WIDTH-1:0]  instr_data_id_o,
    output logic [INSTR_ADDR-1:0]   pc
    );

    logic [INSTR_ADDR-1:0]   imem_instr_addr;
    logic [INSTR_WIDTH-1:0]  imem_instr_data;
    logic                    imem_instr_req;
    logic                    imem_instr_rst;

    always_comb begin
        pc = instruct_addr_o;
    end

    always_ff @(posedge clk_i) begin
        if (!rst_n_i) begin
            imem_instr_addr  <= PC_RESET;
            imem_instr_req   <= 1'b0;
            instr_valid_id   <= 1'b0;
            instr_data_id    <= '0;
        end else begin
            imem_instr_addr  <= imem_instr_addr + 4;
            imem_instr_req   <= 1'b1;
            instr_valid_id   <= instr_valid_id;
            instr_data_id    <= imem_instr_data;
        end
    end
endmodule
