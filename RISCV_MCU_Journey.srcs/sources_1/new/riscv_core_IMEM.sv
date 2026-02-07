`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02/07/2026 02:38:50 PM
// Design Name:
// Module Name: riscv_core_IMEM
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


module riscv_core_IMEM #(
  parameter AXI_ADDR_WIDTH = 15,
  parameter BRAM_ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32
  )(
    input logic s_axi_aclk,
    input logic s_axi_aresetn,
    // AXI4-Lite Slave Interface
    input logic   [AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input logic   [2:0] S_AXI_AWPROT,
    input logic   S_AXI_AWVALID,
    output logic  S_AXI_AWREADY,

    input logic   [DATA_WIDTH-1:0] S_AXI_WDATA,
    input logic   [DATA_WIDTH/8-1:0] S_AXI_WSTRB,
    input logic   S_AXI_WVALID,
    output logic  S_AXI_WREADY,

    output logic  [1:0] S_AXI_BRESP,
    output logic  S_AXI_BVALID,
    input logic   S_AXI_BREADY,

    input logic   [AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input logic   [2:0] S_AXI_ARPROT,
    input logic   S_AXI_ARVALID,
    output logic  S_AXI_ARREADY,

    output logic  [DATA_WIDTH-1:0] S_AXI_RDATA,
    output logic  [1:0] S_AXI_RRESP,
    output logic  S_AXI_RVALID,
    input logic   S_AXI_RREADY,

    // Instruction Fetch Unit Interface
    input logic   imem_bram_clk,
    input logic   imem_bram_en,
    input logic   [DATA_WIDTH/8-1:0] imem_bram_we,
    input logic   [BRAM_ADDR_WIDTH-1:0] imem_bram_addr,
    input logic   [DATA_WIDTH-1:0] imem_bram_wrdata,
    output logic  [DATA_WIDTH-1:0] imem_bram_rddata
    );

  axi_imem_bram_ctrl axi_imem_ctrl_inst (
    .s_axi_aclk(s_axi_aclk),
    .s_axi_aresetn(s_axi_aresetn),
    .s_axi_awaddr(S_AXI_AWADDR),
    .s_axi_awprot(S_AXI_AWPROT),
    .s_axi_awvalid(S_AXI_AWVALID),
    .s_axi_awready(S_AXI_AWREADY),
    .s_axi_wdata(S_AXI_WDATA),
    .s_axi_wstrb(S_AXI_WSTRB),
    .s_axi_wvalid(S_AXI_WVALID),
    .s_axi_wready(S_AXI_WREADY),
    .s_axi_bresp(S_AXI_BRESP),
    .s_axi_bvalid(S_AXI_BVALID),
    .s_axi_bready(S_AXI_BREADY),
    .s_axi_araddr(S_AXI_ARADDR),
    .s_axi_arprot(S_AXI_ARPROT),
    .s_axi_arvalid(S_AXI_ARVALID),
    .s_axi_arready(S_AXI_ARREADY),
    .s_axi_rdata(S_AXI_RDATA),
    .s_axi_rresp(S_AXI_RRESP),
    .s_axi_rvalid(S_AXI_RVALID),
    .s_axi_rready(S_AXI_RREADY),
    .bram_rst_a(bram_rst_a),
    .bram_clk_a(bram_clk_a),
    .bram_en_a(bram_en_a),
    .bram_we_a(bram_we_a),
    .bram_addr_a(bram_addr_a),
    .bram_wrdata_a(bram_wrdata_a),
    .bram_rddata_a(bram_rddata_a)
  );

    logic  bram_rst_a;
    logic  bram_clk_a;
    logic  bram_en_a;
    logic  [DATA_WIDTH/8-1:0] bram_we_a;
    logic  [AXI_ADDR_WIDTH-1:0] bram_addr_a;
    logic  [DATA_WIDTH-1:0] bram_wrdata_a;
    logic  [DATA_WIDTH-1:0] bram_rddata_a;
    logic  rsta_busy;
    logic  rstb_busy;

  blk_mem_gen_imem imem_bram_inst (
    .clka(bram_clk_a),
    .rsta(bram_rst_a),
    .ena(bram_en_a),
    .wea(bram_we_a),
    .addra({17'b0, bram_addr_a}),
    .dina(bram_wrdata_a),
    .douta(bram_rddata_a),

    .clkb(imem_bram_clk),
    .enb(imem_bram_en),
    .web(imem_bram_we),
    .addrb(imem_bram_addr),
    .dinb(imem_bram_wrdata),
    .doutb(imem_bram_rddata),

    .rsta_busy(rsta_busy),
    .rstb_busy(rstb_busy)
  );
endmodule
