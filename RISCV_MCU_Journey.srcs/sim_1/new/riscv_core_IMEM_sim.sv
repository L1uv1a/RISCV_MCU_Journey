`timescale 1ns / 1ps

module tb_riscv_core_IMEM();

    // Parameters
    parameter AXI_ADDR_WIDTH = 15;
    parameter BRAM_ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter CLK_PERIOD = 10;

    // --- Signals Matching Module Ports Exactly ---
    logic s_axi_aclk = 0;
    logic s_axi_aresetn = 0;

    // AXI4-Lite Slave Interface (Inputs to DUT)
    logic [AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR = 0;
    logic [2:0]                S_AXI_AWPROT = 0;
    logic                      S_AXI_AWVALID = 0;
    logic [DATA_WIDTH-1:0]     S_AXI_WDATA = 0;
    logic [DATA_WIDTH/8-1:0]   S_AXI_WSTRB = 0;
    logic                      S_AXI_WVALID = 0;
    logic                      S_AXI_BREADY = 0;
    logic [AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR = 0;
    logic [2:0]                S_AXI_ARPROT = 0;
    logic                      S_AXI_ARVALID = 0;
    logic                      S_AXI_RREADY = 0;

    // AXI4-Lite Slave Interface (Outputs from DUT)
    logic                      S_AXI_AWREADY;
    logic                      S_AXI_WREADY;
    logic [1:0]                S_AXI_BRESP;
    logic                      S_AXI_BVALID;
    logic                      S_AXI_ARREADY;
    logic [DATA_WIDTH-1:0]     S_AXI_RDATA;
    logic [1:0]                S_AXI_RRESP;
    logic                      S_AXI_RVALID;

    // BRAM Interface (Side B - "The CPU Fetch Side")
    logic                      imem_bram_clk;
    logic                      imem_bram_en;
    logic [DATA_WIDTH/8-1:0]   imem_bram_we;
    logic [BRAM_ADDR_WIDTH-1:0] imem_bram_addr;
    logic [DATA_WIDTH-1:0]     imem_bram_wrdata;
    logic [DATA_WIDTH-1:0]     imem_bram_rddata = 32'h0;

    // --- Instantiate DUT ---
    // Using .* now works because all signals above match the module port names
    riscv_core_IMEM #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (.*);

    // --- Clock Generation ---
    always #(CLK_PERIOD/2) s_axi_aclk = ~s_axi_aclk;
    assign imem_bram_clk = s_axi_aclk;

// --- Task: AXI Read ---
    task axi_read(input [AXI_ADDR_WIDTH-1:0] addr);
        begin
            @(posedge s_axi_aclk);
            // 1. Address Phase
            S_AXI_ARADDR  <= addr;
            S_AXI_ARVALID <= 1;
            S_AXI_RREADY  <= 1; // Master is ready to receive

            // Wait for Slave to acknowledge address
            wait(S_AXI_ARREADY);
            @(posedge s_axi_aclk);
            S_AXI_ARVALID <= 0;

            // 2. Data Phase
            // Wait for Slave to provide valid data
            wait(S_AXI_RVALID);
            $display("[AXI READ]  Addr: 0x%h | Data: 0x%h", addr, S_AXI_RDATA);

            @(posedge s_axi_aclk);
            S_AXI_RREADY  <= 0;
        end
    endtask
    // --- Task: AXI Write ---
    task axi_write(input [AXI_ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        begin
            @(posedge s_axi_aclk);
            // 1. Address & Data Phase
            S_AXI_AWADDR  <= addr;
            S_AXI_AWVALID <= 1;
            S_AXI_WDATA   <= data;
            S_AXI_WVALID  <= 1;
            S_AXI_WSTRB   <= 4'hF; // Write all 4 bytes
            S_AXI_BREADY  <= 1;    // Ready for response

            // Wait for Slave to accept Address and Data
            // In AXI-Lite, these can happen simultaneously
            fork
                wait(S_AXI_AWREADY);
                wait(S_AXI_WREADY);
            join

            @(posedge s_axi_aclk);
            S_AXI_AWVALID <= 0;
            S_AXI_WVALID  <= 0;

            // 2. Response Phase
            wait(S_AXI_BVALID);
            $display("[AXI WRITE] Addr: 0x%h | Data: 0x%h | Resp: %b", addr, data, S_AXI_BRESP);

            @(posedge s_axi_aclk);
            S_AXI_BREADY  <= 0;
        end
    endtask
    // --- Stimulus Block ---
    initial begin
        // 1. Initial State
        s_axi_aresetn = 0;
        imem_bram_en = 0;
        imem_bram_we = 0;
        imem_bram_addr = 0;
        imem_bram_wrdata = 0;

        // 2. Release Reset
        #(CLK_PERIOD * 10);
        s_axi_aresetn = 1;
        #(CLK_PERIOD * 10);

        $display("--------------------------------------------------");
        $display("Starting IMEM BRAM Read (Instruction Fetch) Test");
        $display("--------------------------------------------------");

        // 3. Simulate CPU fetching 8 instructions
        // We assume the BRAM is pre-loaded with data via .coe or .mem file
        for (int i = 0; i < 8; i++) begin
            @(posedge s_axi_aclk);
            imem_bram_en   <= 1;
            imem_bram_addr <= i * 4; // Word-aligned addresses (0, 4, 8, C...)

            // BRAM Latency:
            // T0: Address is set
            // T1: BRAM samples address
            // T2: Data is available on imem_bram_rddata
            repeat(2) @(posedge s_axi_aclk);

            $display("Time: %0t | PC: 0x%h | Instr: 0x%h",
                     $time, imem_bram_addr, imem_bram_rddata);
        end
        // 4. Simulate AXI Writes and Reads to IMEM
        for (int i = 0; i < 8; i++) begin
            logic [AXI_ADDR_WIDTH-1:0] test_addr;
            logic [DATA_WIDTH-1:0]     new_data;

            test_addr = i * 4;          // 0x0, 0x4, 0x8...
            new_data  = 32'hAAAA_0000 + i; // Unique data for each address

            $display("\n--- Testing Address: 0x%h ---", test_addr);

            // A. Read the "Old" data (initialized from .coe/.mem)
            axi_read(test_addr);

            // B. Write "New" data over it
            axi_write(test_addr, new_data);

            // C. Read again to verify the write was successful
            axi_read(test_addr);

            // D. Small gap between iterations for waveform clarity
            repeat(2) @(posedge s_axi_aclk);
        end

        #(CLK_PERIOD * 10);
        $display("--------------------------------------------------");
        $display("Simulation Finished");
        $finish;
    end
endmodule
