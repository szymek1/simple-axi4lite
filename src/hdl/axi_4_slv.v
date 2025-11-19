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
// Description: AXI 4 Lite Slave. This implementation assumes full-word reads
//              to the embedded register file and byte-writes with the utilization
//              of strobe mechanism.
// 
// Dependencies: axi_4_lite_configuration.vh
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "../include/axi_4_lite_configuration.vh"


module axi_4_slv (
    // Synchornization & reset
    input	wire					               S_AXI_ACLK,
	input	wire					               S_AXI_ARESETN,

	// AXI write address
	input	wire					               S_AXI_AWVALID,  // AXI write address valid
	output	wire					               S_AXI_AWREADY,  // AXI write address ready
	input	wire [`C_AXI_ADDR_WIDTH-1:0]           S_AXI_AWADDR,   // AXI write address
	input	wire [2:0]				               S_AXI_AWPROT,   // AXI write protection

	// AXI write data and write strobe
	input	wire					               S_AXI_WVALID,   // AXI write data valid. This signal indicates that valid write data 
                                                                   // and strobes are available
	output	wire					               S_AXI_WREADY,   // AXI write data ready
	input	wire [`C_AXI_DATA_WIDTH-1:0]		   S_AXI_WDATA,    // AXI write data
	input	wire [`C_AXI_STROBE_WIDTH-1:0]	       S_AXI_WSTRB,    // AXI write strobe. This signal indicates which byte lanes hold valid data

	// AXI write response
	output	wire					               S_AXI_BVALID,   // AXI write response valid. This signal indicates that the channel is signaling 
                                                                   // a valid write response
	input	wire					               S_AXI_BREADY,   // AXI write response ready
	output	wire [1:0]				               S_AXI_BRESP,    // AXI write response. This signal indicates the status of the write transaction
                                                                   // Check axi4_lite_configuration.vh for details

	// AXI read address
	input	wire					               S_AXI_ARVALID,  // AXI read address valid
	output	wire					               S_AXI_ARREADY,  // AXI read address ready
	input	wire [`C_AXI_ADDR_WIDTH-1:0]           S_AXI_ARADDR,   // AXI read address
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

    // Read/Write indexes
    wire [`C_ADDR_REG_BITS-1:0] read_index  = S_AXI_ARADDR[`C_AXI_ADDR_WIDTH-1:`C_ADDR_LSB];
    wire [`C_ADDR_REG_BITS-1:0] write_index = S_AXI_AWADDR[`C_AXI_ADDR_WIDTH-1:`C_ADDR_LSB];

    // Internal registers
    // Write channel internal registers
    reg                         axi_awready_reg;
    reg                         axi_wready_reg;
    reg                         axi_bvalid_reg;
    reg [1:0]                   axi_bresp_reg;
    reg [`C_AXI_ADDR_WIDTH-1:0] axi_awaddr_latched; // latched write address

    // Read channel internal registers
    reg                         axi_arready_reg;
    reg                         axi_rvalid_reg;
    reg [1:0]                   axi_rresp_reg;
    reg [`C_AXI_DATA_WIDTH-1:0] axi_rdata_reg;      // pipelined read data output
    
    // internal write-enable pulse for user logic
    reg                         slv_reg_wren;

    // Output wires
    assign S_AXI_AWREADY = axi_awready_reg;
    assign S_AXI_WREADY  = axi_wready_reg;
    assign S_AXI_BVALID  = axi_bvalid_reg;
    assign S_AXI_BRESP   = axi_bresp_reg;
    
    assign S_AXI_ARREADY = axi_arready_reg;
    assign S_AXI_RVALID  = axi_rvalid_reg;
    assign S_AXI_RRESP   = axi_rresp_reg;
    assign S_AXI_RDATA   = axi_rdata_reg;;

    // Read FSM
    localparam RD_IDLE  = 2'b00;
    localparam RD_DATA  = 2'b01;
    reg [1:0]  rd_state = RD_IDLE;

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_bresp_reg   <= `OKAY;
            axi_arready_reg <= `SLV_AXI_RD_ADDR_NREADY;
            axi_rvalid_reg  <= `SLV_AXI_RD_ADDR_NVALID;

            rd_state        <= RD_IDLE;
            axi_rdata_reg   <= 0;
        end else begin
            case (rd_state) 
                RD_IDLE: begin
                    axi_arready_reg <= `SLV_AXI_RD_ADDR_READY; // slave is ready for a new read address
                    axi_rvalid_reg  <= `SLV_AXI_RD_ADDR_NVALID;

                    if (S_AXI_ARVALID == `MS_RD_ADDR_VALID & axi_arready_reg == `SLV_AXI_RD_ADDR_READY) begin
                        // Master has sent the valid read address
                        rd_state <= RD_DATA;
                        axi_arready_reg <= `SLV_AXI_RD_ADDR_NREADY; // slave is occupied by the currently
                                                                    // issued read address
                        
                        // data will be available in the next cycle
                        axi_rdata_reg <= regfile[read_index]; 
                    end
                end

                RD_DATA: begin
                    axi_rvalid_reg <= `SLV_AXI_RD_ADDR_VALID; // data is avaliable in the pipelined register

                    if (S_AXI_RREADY == `MS_RD_ADDR_READY && axi_rvalid_reg == `SLV_AXI_RD_ADDR_VALID) begin
                        rd_state        <= RD_IDLE;
                        axi_rvalid_reg  <= `SLV_AXI_RD_ADDR_NVALID;
                    end
                end

                default: rd_state <= RD_IDLE;
            endcase
        end
    end

    // Write FSM
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_bresp_reg      <= `OKAY;
            axi_awready_reg    <= `SLV_AXI_WRT_ADDR_NREADY;
            axi_wready_reg     <= `SLV_AXI_WRT_DATA_NREADY;
            axi_bvalid_reg     <= `SLV_AXI_WRT_NVALID;

            axi_awaddr_latched <= 0;
            slv_reg_wren       <= 1'b0;
        end else begin
            axi_awready_reg    <= `SLV_AXI_WRT_ADDR_NREADY;
            axi_wready_reg     <= `SLV_AXI_WRT_DATA_NREADY;
            slv_reg_wren       <= 1'b0;

            if (axi_bvalid_reg == `SLV_AXI_WRT_VALID && S_AXI_BREADY == `MS_WRT_RESP_READY) begin
                // Write request consumed, we are ready for a new one
                axi_bvalid_reg <= `SLV_AXI_WRT_NVALID;
            end

            if (axi_bvalid_reg == `SLV_AXI_WRT_NVALID) begin
                // Ready for address/data
                axi_awready_reg <= `SLV_AXI_WRT_ADDR_READY;
                axi_wready_reg  <= `SLV_AXI_WRT_DATA_READY;
            end

            if (axi_awready_reg == `SLV_AXI_WRT_ADDR_READY && S_AXI_AWVALID == `MS_WRT_ADDR_VALID) begin
                // Latch on the new wrtie address
                axi_awaddr_latched <= S_AXI_AWADDR;
            end

            if (axi_awready_reg == `SLV_AXI_WRT_ADDR_READY && S_AXI_AWVALID == `MS_WRT_ADDR_VALID
            &&  axi_wready_reg  == `SLV_AXI_WRT_DATA_READY && S_AXI_WVALID  == `MS_WRT_DATA_VALID) begin
                slv_reg_wren    <= 1'b1; // singluar inpulse to register write logic
                axi_bvalid_reg  <= `SLV_AXI_WRT_VALID; 
                axi_bresp_reg   <= `OKAY;
                axi_awready_reg <= `SLV_AXI_WRT_ADDR_NREADY; 
                axi_wready_reg  <= `SLV_AXI_WRT_DATA_NREADY;
            end

        end
    end

    // Register reset & write logic
    integer byte_id;
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            for (reg_id = 0; reg_id < `C_REGISTERS_NUMBER; reg_id = reg_id + 1) begin
                regfile[reg_id] <= `C_AXI_DATA_WIDTH'h0;
            end
        end else begin
            if (slv_reg_wren) begin
                for (byte_id = 0; byte_id < `C_AXI_STROBE_WIDTH; byte_id = byte_id + 1) begin
                    if (S_AXI_WSTRB[byte_id]) begin
                        // Example to illustrate how strobe mechanism works:
                        // if byte_id = 0 then [(0*8)+:8] -> [0+:8] this selects [7:0]
                        // the line performs: 
                        // regfile[axi_awaddr_latched][7:0]         <= S_AXI_WDATA[7:0]
                        regfile[axi_awaddr_latched][(byte_id*8)+:8] <= S_AXI_WDATA[(byte_id*8)+:8];
                    end
                end
            end
        end
    end

endmodule