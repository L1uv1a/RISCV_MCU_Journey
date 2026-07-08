`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02/07/2026 03:06:19 PM
// Design Name:
// Module Name: riscv_core_LSU_top
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

module riscv_core_LSU_top(
    input logic       ls_sys_clk_i,
    input logic       ls_sys_rst_n_i,

    // Inputs signal from EXU
    input logic [LOAD_STORE_ELEMENT_BIT_WIDTH-1:0] ls_load_store_sel_i,
    input logic [REG_DATA_WIDTH-1:0]               ls_rd_data_i,
    input logic [REG_ADDR_WIDTH-1:0]               ls_rd_addr_i,
    input logic [REG_DATA_WIDTH-1:0]               ls_rs2_data_to_store_i,
    input logic [PC_WIDTH-1:0]                     ls_pc_i,
    input logic [PC_WIDTH-1:0]                     ls_next_pc_i,

    // Signal to WB
    output logic                                   ls_access_wb_req_o,
    input logic                                    ls_access_wb_gnt_i,
    output logic [REG_DATA_WIDTH-1:0]              ls_rd_data_o,
    output logic [REG_ADDR_WIDTH-1:0]              ls_rd_addr_o,

    // Signal to Pipeline Control Unit
    output logic                                   ls_write_valid_o, // Might not use
    output logic                                   ls_write_ready_o,
    output logic                                   ls_read_valid_o,
    output logic                                   ls_read_ready_o,

    // AXI4-Lite interface
    axi4lite_interface.master axi4lite_if
);

/*-----------------------AXI4-Lite Master Write Logic-----------------------*/
typedef enum logic [3:0] {
    WRITE_IDLE,
    WRITE_TRANSACTION,
    WAIT_B
} axi4lite_master_write_state_t;

logic aw_done;
logic w_done;

axi4lite_master_write_state_t axi4lite_master_write_current_state;
axi4lite_master_write_state_t axi4lite_master_write_next_state;

logic [REG_DATA_WIDTH-1:0] ls_rs2_data_to_store_addr;
logic [REG_DATA_WIDTH-1:0] ls_rs2_data_to_store_data;

logic [LOAD_STORE_ELEMENT_BIT_WIDTH-1-2:0] ls_store_sel;


always_ff @(posedge ls_sys_clk_i or negedge ls_sys_rst_n_i) begin
    if (!ls_sys_rst_n_i) begin
        axi4lite_master_write_current_state <= WRITE_IDLE;
    end else begin
        axi4lite_master_write_current_state <= axi4lite_master_write_next_state;
    end
end

always_ff @(posedge ls_sys_clk_i or negedge ls_sys_rst_n_i) begin : Capture_RS2_Data_to_Store
    if (!ls_sys_rst_n_i) begin
        ls_store_sel <= '0;
        ls_rs2_data_to_store_addr <= '0;
        ls_rs2_data_to_store_data <= '0;
        aw_done <= 1'b0;
        w_done <= 1'b0;
    end else begin
        if (axi4lite_master_write_current_state == WRITE_IDLE) begin
            ls_store_sel <= ls_load_store_sel_i[1:0];
            ls_rs2_data_to_store_addr <= ls_rd_data_i; // EXU calculated the address
            ls_rs2_data_to_store_data <= ls_rs2_data_to_store_i;
            aw_done <= 1'b0;
            w_done <= 1'b0;
        end
        else begin
            if (axi4lite_if.AWREADY) begin
                aw_done <= 1'b1;
            end
            if (axi4lite_if.WREADY) begin
                w_done <= 1'b1;
            end
        end
    end
end

always_comb begin : axi4lite_master_write_fsm_transitions
    case (axi4lite_master_write_current_state)
        WRITE_IDLE: begin
            if ( ( ls_load_store_sel_i[3] == 1) ) begin
                axi4lite_master_write_next_state = WRITE_TRANSACTION;
            end
            else begin
                axi4lite_master_write_next_state = WRITE_IDLE;
            end
        end
        WRITE_TRANSACTION: begin
            if (aw_done && w_done) begin
                axi4lite_master_write_next_state = WAIT_B;
            end
            else begin
                axi4lite_master_write_next_state = WRITE_TRANSACTION;
            end
        end
        WAIT_B: begin
            if (axi4lite_if.BVALID) begin
                axi4lite_master_write_next_state = WRITE_IDLE;
            end
            else begin
                axi4lite_master_write_next_state = WAIT_B;
            end
        end
    endcase
end

always_comb begin : axi4lite_master_write_fsm_output
    axi4lite_if.AWADDR = ls_rs2_data_to_store_addr;
    axi4lite_if.AWPROT = '0;
    axi4lite_if.WDATA = ls_rs2_data_to_store_data;
    case (ls_store_sel [1:0])
        2'b01: axi4lite_if.WSTRB = 4'b0001; // STORE_1BYTE
        2'b10: axi4lite_if.WSTRB = 4'b0011; // STORE_2BYTE
        2'b11: axi4lite_if.WSTRB = 4'b1111; // STORE_4BYTE
        default:     axi4lite_if.WSTRB = 4'b0000;
    endcase
    case (axi4lite_master_write_current_state)
        WRITE_IDLE: begin
            ls_write_ready_o = 1'b1;
            ls_write_valid_o = 1'b0;
            axi4lite_if.AWVALID = 1'b0;
            axi4lite_if.WVALID = 1'b0;
            axi4lite_if.BREADY = 1'b0;
        end
        WRITE_TRANSACTION: begin
            ls_write_ready_o = 1'b0;
            ls_write_valid_o = 1'b0;
            axi4lite_if.AWVALID = !aw_done;
            axi4lite_if.WVALID = !w_done;
            axi4lite_if.BREADY = 1'b0;
        end
        WAIT_B: begin
            ls_write_ready_o = 1'b0;
            ls_write_valid_o = 1'b0;
            axi4lite_if.AWVALID = 1'b0;
            axi4lite_if.WVALID = 1'b0;
            axi4lite_if.BREADY = 1'b1;
        end
        default: begin
            ls_write_ready_o = 1'b0;
            ls_write_valid_o = 1'b0;
            axi4lite_if.AWVALID = 1'b0;
            axi4lite_if.WVALID = 1'b0;
            axi4lite_if.BREADY = 1'b0;
        end
    endcase
end

/*-----------------------AXI4-Lite Master Read Logic-----------------------*/
typedef enum logic [3:0] {
    READ_IDLE,
    READ_TRANSACTION,
    WAIT_R,
    ACCESS_WRITEBACK
} axi4lite_master_read_state_t;

axi4lite_master_read_state_t axi4lite_master_read_current_state;
axi4lite_master_read_state_t axi4lite_master_read_next_state;

always_ff @(posedge ls_sys_clk_i or negedge ls_sys_rst_n_i) begin
    if (!ls_sys_rst_n_i) begin
        axi4lite_master_read_current_state <= READ_IDLE;
    end else begin
        axi4lite_master_read_current_state <= axi4lite_master_read_next_state;
    end
end

always_comb begin : axi4lite_master_read_fsm_transitions
    case (axi4lite_master_read_current_state)
        READ_IDLE: begin
            if ( ( ls_load_store_sel_i[3] == 0) && ls_load_store_sel_i[1:0] != 2'b00 ) begin
                axi4lite_master_read_next_state = READ_TRANSACTION;
            end
            else begin
                axi4lite_master_read_next_state = READ_IDLE;
            end
        end
        READ_TRANSACTION: begin
            if (axi4lite_if.ARREADY) begin
                axi4lite_master_read_next_state = WAIT_R;
            end
            else begin
                axi4lite_master_read_next_state = READ_TRANSACTION;
            end
        end
        WAIT_R: begin
            if (axi4lite_if.RVALID) begin
                axi4lite_master_read_next_state = ACCESS_WRITEBACK;
            end
            else begin
                axi4lite_master_read_next_state = WAIT_R;
            end
        end
        ACCESS_WRITEBACK: begin
            if (ls_access_wb_gnt_i) begin
                axi4lite_master_read_next_state = READ_IDLE;
            end
            else begin
                axi4lite_master_read_next_state = ACCESS_WRITEBACK;
            end
        end
    endcase
end

logic [LOAD_STORE_ELEMENT_BIT_WIDTH-1-1:0] ls_load_sel;
logic [REG_DATA_WIDTH-1:0] ls_address_to_read;
// logic [REG_DATA_WIDTH-1:0] ls_rd_data_o;
// logic [REG_ADDR_WIDTH-1:0] ls_rd_addr_o;

always_ff @(posedge ls_sys_clk_i or negedge ls_sys_rst_n_i) begin : Capture_address_for_read
    if (!ls_sys_rst_n_i) begin
        ls_load_sel <= '0;
        ls_address_to_read <= '0;
        ls_rd_addr_o <= '0;
    end else begin
        if (axi4lite_master_write_current_state == READ_IDLE) begin
            ls_load_sel <= ls_load_store_sel_i[2:0];
            ls_address_to_read <= ls_rd_data_i;
            ls_rd_addr_o <= ls_rd_addr_i;
        end
        else begin
            ls_address_to_read <= ls_address_to_read;
            ls_rd_addr_o <= ls_rd_addr_o;
        end
    end
end

always_comb begin : axi4lite_master_read_fsm_output
    axi4lite_if.ARADDR = ls_address_to_read;
    axi4lite_if.ARPROT = '0;
    case (axi4lite_master_read_current_state)
        READ_IDLE: begin
            ls_access_wb_req_o = 1'b0;
            ls_read_ready_o = 1'b1;
            ls_read_valid_o = 1'b0;
            axi4lite_if.ARVALID = 1'b0;
        end
        READ_TRANSACTION: begin
            ls_access_wb_req_o = 1'b0;
            ls_read_ready_o = 1'b0;
            ls_read_valid_o = 1'b0;
            axi4lite_if.ARVALID = 1'b1;
        end
        WAIT_R: begin
            ls_access_wb_req_o = 1'b0;
            ls_read_ready_o = 1'b0;
            ls_read_valid_o = 1'b0;
            axi4lite_if.ARVALID = 1'b1;
        end
        ACCESS_WRITEBACK: begin
            ls_access_wb_req_o = 1'b1;
            ls_read_ready_o = 1'b0;
            ls_read_valid_o = 1'b0; // Let it 0 for now, we can change it to 1 if needed
            axi4lite_if.ARVALID = 1'b0;
        end
        default: begin
            ls_access_wb_req_o = 1'b0;
            ls_read_ready_o = 1'b0;
            ls_read_valid_o = 1'b0;
            axi4lite_if.ARVALID = 1'b0;
        end
    endcase
end

always_ff @(posedge ls_sys_clk_i or negedge ls_sys_rst_n_i) begin : Capture_Read_Data_from_AXI4Lite
    if (!ls_sys_rst_n_i) begin
        ls_rd_data_o <= '0;
    end else begin
        if ( axi4lite_if.RREADY & axi4lite_if.RVALID ) begin
            case (ls_load_sel)
                3'b000: ls_rd_data_o <= '0; // NONE
                3'b001: ls_rd_data_o <= {{24{axi4lite_if.RDATA[7]}}, axi4lite_if.RDATA[7:0]}; // LOAD_1BYTE
                3'b010: ls_rd_data_o <= {{16{axi4lite_if.RDATA[15]}}, axi4lite_if.RDATA[15:0]}; // LOAD_2BYTE
                3'b011: ls_rd_data_o <= axi4lite_if.RDATA; // LOAD_4BYTE
                3'b101: ls_rd_data_o <= {24'b0, axi4lite_if.RDATA[7:0]}; // LOAD_1BYTE_UNSIGNED
                3'b110: ls_rd_data_o <= {16'b0, axi4lite_if.RDATA[15:0]}; // LOAD_2BYTE_UNSIGNED
                default: ls_rd_data_o <= '0;
            endcase
        end
    end
end


endmodule
