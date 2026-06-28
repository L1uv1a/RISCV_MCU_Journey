`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 06/28/2026 06:49:36 PM
// Design Name:
// Module Name: axi4lite_interface_modport
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

interface axi4lite_interface #(

);
    //==========================
    // Write Address Channel
    //==========================
    logic [AXI4LITE_ADDR_WIDTH-1:0] AWADDR;
    logic [2:0]            AWPROT;
    logic                  AWVALID;
    logic                  AWREADY;

    //==========================
    // Write Data Channel
    //==========================
    logic [DATA_WIDTH-1:0]   WDATA;
    logic [DATA_WIDTH/8-1:0] WSTRB;
    logic                    WVALID;
    logic                    WREADY;

    //==========================
    // Write Response Channel
    //==========================
    logic [1:0] BRESP;
    logic       BVALID;
    logic       BREADY;

    //==========================
    // Read Address Channel
    //==========================
    logic [AXI4LITE_ADDR_WIDTH-1:0] ARADDR;
    logic [2:0]            ARPROT;
    logic                  ARVALID;
    logic                  ARREADY;

    //==========================
    // Read Data Channel
    //==========================
    logic [DATA_WIDTH-1:0] RDATA;
    logic [1:0]            RRESP;
    logic                  RVALID;
    logic                  RREADY;

    //----------------------------------
    // AXI Master
    //----------------------------------
    modport master (
        output AWADDR, AWPROT, AWVALID,
        input  AWREADY,

        output WDATA, WSTRB, WVALID,
        input  WREADY,

        input  BRESP, BVALID,
        output BREADY,

        output ARADDR, ARPROT, ARVALID,
        input  ARREADY,

        input  RDATA, RRESP, RVALID,
        output RREADY
    );

    //----------------------------------
    // AXI Slave
    //----------------------------------
    modport slave (
        input  AWADDR, AWPROT, AWVALID,
        output AWREADY,

        input  WDATA, WSTRB, WVALID,
        output WREADY,

        output BRESP, BVALID,
        input  BREADY,

        input  ARADDR, ARPROT, ARVALID,
        output ARREADY,

        output RDATA, RRESP, RVALID,
        input  RREADY
    );

endinterface

