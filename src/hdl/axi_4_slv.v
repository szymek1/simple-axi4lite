`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ISAE
// Engineer: Szymon Bogus
// 
// Create Date: 11/03/2025
// Design Name: 
// Module Name: axi_4_slv
// Project Name: simple-axi4litr
// Target Devices: Zybo Z7-20
// Tool Versions: 
// Description: AXI 4 Lite Slave
// 
// Dependencies: axi_4_lite_configuration.vh
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "../include/axi4_lite_configuration.vh"


module axi_4_slv (
    // Synchornization & reset
    input	wire					               S_AXI_ACLK,
	input	wire					               S_AXI_ARESETN,

	// AXI write address
	input	wire					               S_AXI_AWVALID,  // AXI write address valid
	output	wire					               S_AXI_AWREADY,  // AXI write address ready
	input	wire [$clog2(`C_REGISTERS_NUMBER)-1:0] S_AXI_AWADDR,   // AXI write address
	input	wire [2:0]				               S_AXI_AWPROT,   // AXI write protection

	// AXI write data and write strobe
	input	wire					               S_AXI_WVALID,   // AXI write data valid. This signal indicates that valid write data 
                                                                   // and strobes are available
	output	wire					               S_AXI_WREADY,   // AXI write data ready
	input	wire [`C_AXI_DATA_WIDTH-1:0]		   S_AXI_WDATA,    // AXI write data
	input	wire [`C_AXI_DATA_WIDTH/8-1:0]	       S_AXI_WSTRB,    // AXI write strobe. This signal indicates which byte lanes hold valid data

	// AXI write response
	output	wire					               S_AXI_BVALID,   // AXI write response valid. This signal indicates that the channel is signaling 
                                                                   // a valid write response
	input	wire					               S_AXI_BREADY,   // AXI write response ready
	output	wire [1:0]				               S_AXI_BRESP,    // AXI write response. This signal indicates the status of the write transaction
                                                                   // Check axi4_lite_configuration.vh for details

	// AXI read address
	input	wire					               S_AXI_ARVALID,  // AXI read address valid
	output	wire					               S_AXI_ARREADY,  // AXI read address ready
	input	wire [$clog2(`C_REGISTERS_NUMBER)-1:0] S_AXI_ARADDR,   // AXI read address
	input	wire [2:0]				               S_AXI_ARPROT,   // AXI read protection

	// AXI read data and response
	output	wire					               S_AXI_RVALID,   // AXI read address valid
	input	wire					               S_AXI_RREADY,   // AXI read address ready
	output	wire [`C_AXI_DATA_WIDTH-1:0]		   S_AXI_RDATA,    // AXI read data issued by slave
	output	wire [1:0]				               S_AXI_RRESP     // AXI read response. This signal indicates the status of the read transfer
                                                                   // Check axi4_lite_configuration.vh for details
);

    // Register file definition
    reg [`C_AXI_DATA_WIDTH-1:0] regfile [`C_REGISTERS_NUMBER-1:0];
    integer reg_id;

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            // Initilly S_AXI_ARESETN is assumed active low and the reset
            // zeroes all registers
            for (reg_id = 0; reg_id < `C_REGISTERS_NUMBER; reg_id = reg_id + 1) begin
                regfile <= 0;
            end
        end
    end


endmodule