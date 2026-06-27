`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 03/03/2026 09:18:47 PM
// Design Name:
// Module Name: riscv_core_RF_top
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


module riscv_core_RF_top #(
    parameter REG_DATA_WIDTH = 32,
    parameter REG_ADDR_WIDTH = 5
)(
    input logic       rf_clk_i,
    input logic       rf_rst_n_i,

    // Read RS1
    input logic [REG_ADDR_WIDTH-1:0]  rf_rs1_addr_i,
    input logic rf_rs1_en_i,
    output logic [REG_DATA_WIDTH-1:0] rf_rs1_data_o,

    // Read RS2
    input logic [REG_ADDR_WIDTH-1:0]  rf_rs2_addr_i,
    input logic rf_rs2_en_i,
    output logic [REG_DATA_WIDTH-1:0] rf_rs2_data_o,

    // Write RD
    input logic [REG_ADDR_WIDTH-1:0]  rf_rd_addr_i,
    input logic rf_rd_wen_i,
    input logic [REG_DATA_WIDTH-1:0]  rf_rd_data_i
);
    (* ram_style = "distributed" *) logic [REG_DATA_WIDTH-1:0] reg_file [0:(2**REG_ADDR_WIDTH)-1];

    // Read logic
    always_comb begin
        if (rf_rs1_en_i) begin
            rf_rs1_data_o = (rf_rs1_addr_i == 5'd0) ? 32'b0 : reg_file[rf_rs1_addr_i];
        end else begin
            rf_rs1_data_o = 32'b0;
        end
        if (rf_rs2_en_i) begin
            rf_rs2_data_o = (rf_rs2_addr_i == 5'd0) ? 32'b0 : reg_file[rf_rs2_addr_i];
        end else begin
            rf_rs2_data_o = 32'b0;
        end
    end

    // Write logic
    always @(posedge rf_clk_i or negedge rf_rst_n_i) begin
        if (!rf_rst_n_i) begin
            for (int i = 0; i < 2**REG_ADDR_WIDTH; i++) begin
                reg_file[i] <= 32'b0;
            end
        end else if (rf_rd_wen_i && rf_rd_addr_i != 5'd0) begin
            reg_file[rf_rd_addr_i] <= rf_rd_data_i;
        end
    end

endmodule
