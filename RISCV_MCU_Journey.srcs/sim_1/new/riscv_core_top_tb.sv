`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02/10/2026 09:53:32 PM
// Design Name:
// Module Name: riscv_core_top_tb
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


`timescale 1ns / 1ps

module riscv_core_top_tb;

    // 1. Parameters

    parameter PC_RESET = 32'h0000_0000;
    parameter INSTR_WIDTH = 32;
    parameter AXI_ADDR_WIDTH = 32;
    parameter BRAM_ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter IMEM_ADDR_WIDTH = BRAM_ADDR_WIDTH;
    parameter INSTR_ADDR_WIDTH = 20;
    parameter CLK_PERIOD       = 10; // 100MHz

    // 2. Signals
    logic clk_i;
    logic rst_n_i;

    // 3. Instantiate the Unit Under Test (UUT)
    riscv_core_top #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i)
    );

    // 4. Clock Generation
    initial begin
        clk_i = 0;
        forever #(CLK_PERIOD/2) clk_i = ~clk_i;
    end

    // 5. Stimulus Procedure
    initial begin
        // Initialize inputs
        rst_n_i = 0;

        // Apply Reset
        $display("[%0t] Stimulus started. Applying reset...", $time);
        repeat (16) @(posedge clk_i);

        // Release Reset
        @(negedge clk_i);
        rst_n_i = 1;
        $display("[%0t] Reset released.", $time);

        // Run simulation for a set time
        // In a real scenario, you'd wait for a 'done' signal or a specific memory write
        repeat (100) @(posedge clk_i);

        $display("[%0t] Simulation finished.", $time);
        $finish;
    end

    // 6. Monitor (Optional)
    // Use hierarchy to peek at internal signals (e.g., Program Counter)
    initial begin
        $monitor("[%0t] Reset: %b", $time, rst_n_i);
    end

    // 7. Waveform Dump (for tools like GTKWave or Vivado)
    initial begin
        $dumpfile("riscv_core_tb.vcd");
        $dumpvars(0, riscv_core_top_tb);
    end

endmodule
