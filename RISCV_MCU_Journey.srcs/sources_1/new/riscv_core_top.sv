`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02/05/2026 09:51:02 PM
// Design Name:
// Module Name: riscv_core_top
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


module riscv_core_top #
  (
    parameter PC_RESET = 32'h0000_0000,
    parameter INSTR_WIDTH = 32,
    parameter AXI_ADDR_WIDTH = 32,
    parameter BRAM_ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter IMEM_ADDR_WIDTH = BRAM_ADDR_WIDTH,
    parameter INSTR_ADDR_WIDTH = 20
  )(
    input logic         clk_i,
    input logic       rst_n_i
  );
  riscv_core_IMEM # (
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  )
  riscv_core_IMEM_inst (
    .s_axi_aclk(s_axi_aclk),
    .s_axi_aresetn(s_axi_aresetn),
    .S_AXI_AWADDR(S_AXI_AWADDR),
    .S_AXI_AWPROT(S_AXI_AWPROT),
    .S_AXI_AWVALID(S_AXI_AWVALID),
    .S_AXI_AWREADY(S_AXI_AWREADY),
    .S_AXI_WDATA(S_AXI_WDATA),
    .S_AXI_WSTRB(S_AXI_WSTRB),
    .S_AXI_WVALID(S_AXI_WVALID),
    .S_AXI_WREADY(S_AXI_WREADY),
    .S_AXI_BRESP(S_AXI_BRESP),
    .S_AXI_BVALID(S_AXI_BVALID),
    .S_AXI_BREADY(S_AXI_BREADY),
    .S_AXI_ARADDR(S_AXI_ARADDR),
    .S_AXI_ARPROT(S_AXI_ARPROT),
    .S_AXI_ARVALID(S_AXI_ARVALID),
    .S_AXI_ARREADY(S_AXI_ARREADY),
    .S_AXI_RDATA(S_AXI_RDATA),
    .S_AXI_RRESP(S_AXI_RRESP),
    .S_AXI_RVALID(S_AXI_RVALID),
    .S_AXI_RREADY(S_AXI_RREADY),
    .imem_bram_clk(imem_bram_clk),
    .imem_bram_en(imem_bram_en),
    .imem_bram_we(imem_bram_we),
    .imem_bram_addr(imem_bram_addr),
    .imem_bram_wrdata(imem_bram_wrdata),
    .imem_bram_rddata(imem_bram_rddata)
  );
  logic s_axi_aclk;
  logic s_axi_aresetn;
  logic imem_bram_clk;
  logic imem_bram_en;
  logic [DATA_WIDTH/8-1:0] imem_bram_we;
  logic [BRAM_ADDR_WIDTH-1:0] imem_bram_addr;
  logic [DATA_WIDTH-1:0] imem_bram_wrdata;
  logic [DATA_WIDTH-1:0] imem_bram_rddata;

  logic [BRAM_ADDR_WIDTH-1:0]   imem_instr_addr_o;
  logic [DATA_WIDTH-1:0]        imem_instr_data_i;
  logic                         imem_instr_en_o;

  assign s_axi_aclk = clk_i;
  assign s_axi_aresetn = rst_n_i;
  assign imem_bram_clk = clk_i;
  assign imem_bram_en = imem_instr_en_o;
  assign imem_bram_we = {DATA_WIDTH/8{1'b0}};
  assign imem_bram_addr = imem_instr_addr_o;
  assign imem_instr_data_i = imem_bram_rddata;

  logic if_clk_i;
  logic if_rst_n_i;
  assign if_clk_i = clk_i;
  assign if_rst_n_i = rst_n_i;

  riscv_core_IFU_top # (
    .PC_RESET(PC_RESET),
    .INSTR_WIDTH(INSTR_WIDTH),
    .IMEM_ADDR_WIDTH(IMEM_ADDR_WIDTH),
    .INSTR_ADDR_WIDTH(INSTR_ADDR_WIDTH)
  )
  riscv_core_IFU_top_inst (
    .if_clk_i(if_clk_i),
    .if_rst_n_i(if_rst_n_i),
    .imem_instr_addr_o(imem_instr_addr_o),
    .imem_instr_data_i(imem_instr_data_i),
    .imem_instr_en_o(imem_instr_en_o),
    .if_stage_stall_i(if_stage_stall_i),
    .if_instr_valid_o(if_instr_valid_o),
    .if_instr_o(if_instr_o),
    .if_pc_o(if_pc_o)
  );
endmodule
