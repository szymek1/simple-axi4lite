`include "../include/axi_4_lite_configuration.vh"


module axi_4_lite_slv (
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
	output	wire [1:0]				               S_AXI_RRESP,    // AXI read response. This signal indicates the status of the read transfer
                                                                   // Check axi4_lite_configuration.vh for details

    // Debug outputs
    output wire  [`C_ADDR_REG_BITS-1:0]            DEB_READ_INDEX,
    output wire  [`C_ADDR_REG_BITS-1:0]            DEB_WRITE_INDEX                                                             
);

    // Register file definition
    reg [`C_AXI_DATA_WIDTH-1:0] regfile [`C_REGISTERS_NUMBER-1:0];
    integer reg_id;

    // Read/Write indexes (point to specific word)
    wire [`C_ADDR_REG_BITS-1:0] read_index  = S_AXI_ARADDR[`C_AXI_ADDR_WIDTH-1:`C_ADDR_LSB];
    wire [`C_ADDR_REG_BITS-1:0] write_index = S_AXI_AWADDR[`C_AXI_ADDR_WIDTH-1:`C_ADDR_LSB];

    // Assigning debug ports
    assign DEB_READ_INDEX  = read_index;
    assign DEB_WRITE_INDEX = write_index;

    // Internal registers
    // Write channel internal registers
    reg                         axi_awready_reg;
    reg                         axi_wready_reg;
    reg                         axi_bvalid_reg;
    reg [1:0]                   axi_bresp_reg;
    reg [`C_ADDR_REG_BITS-1:0]  axi_awaddr_latched;  // latched write address
    reg                         slv_reg_wren;       // internal write-enable pulse for user logic

    // Read channel internal registers
    reg                         axi_arready_reg;
    reg                         axi_rvalid_reg;
    reg [1:0]                   axi_rresp_reg;
    reg [`C_AXI_DATA_WIDTH-1:0] axi_rdata_reg;      // pipelined read data output
    reg [`C_ADDR_REG_BITS-1:0]  axi_araddr_latched; // latched read address

    // Output wires
    // Write related
    assign S_AXI_AWREADY = axi_awready_reg;
    assign S_AXI_WREADY  = axi_wready_reg;
    assign S_AXI_BVALID  = axi_bvalid_reg;
    assign S_AXI_BRESP   = axi_bresp_reg;

    // Read related
    assign S_AXI_ARREADY = axi_arready_reg;
    assign S_AXI_RVALID  = axi_rvalid_reg;
    assign S_AXI_RRESP   = axi_rresp_reg;
    assign S_AXI_RDATA   = axi_rdata_reg;

    // Read process
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            axi_arready_reg    <= 1'b1; 
            axi_rvalid_reg     <= 1'b0;
            axi_araddr_latched <= 0;
            axi_rdata_reg      <= 0;
            axi_rresp_reg      <= 2'b0;
        end else begin
            if (S_AXI_ARVALID && axi_arready_reg) begin
                // Address handshake: slave is by default ready so the handshake happends immediately
                //                    once the master issue the address
                axi_arready_reg    <= 1'b0; 
                axi_araddr_latched <= read_index;             
                axi_rvalid_reg     <= 1'b1;  // data will be valid in the next cycle
                axi_rresp_reg      <= `AXI_RESP_OKAY;
                axi_rdata_reg      <= regfile[read_index];
            end else if (S_AXI_RREADY && axi_rvalid_reg) begin
                // Transaction complete: master accepts the data
                axi_rvalid_reg     <= 1'b0;
                axi_arready_reg    <= 1'b1;  // heres ready for the new read transaction
            end
        end
    end

    // Write process
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            axi_awready_reg    <= 1'b1; 
            axi_wready_reg     <= 1'b0;
            axi_bvalid_reg     <= 1'b0;
            axi_awaddr_latched <= 0;
            slv_reg_wren       <= 0;
        end else begin
            slv_reg_wren <= 1'b0;

            if (S_AXI_AWVALID && axi_awready_reg) begin
                // Address handshake: slave is by default READY and master has to issue VALID
                axi_awaddr_latched <= write_index;
                axi_awready_reg    <= 1'b0;
                axi_wready_reg     <= 1'b1;  
            end else if (S_AXI_WVALID && axi_wready_reg) begin
                // Data handshake: slave is ready to accept new write data and it's waiting for the master to issue VALID
                axi_wready_reg     <= 1'b0;
                slv_reg_wren       <= 1'b1;                        
                axi_bvalid_reg     <= 1'b1;       
                axi_bresp_reg      <= `AXI_RESP_OKAY;
            end else if (S_AXI_BVALID && S_AXI_BREADY) begin
                // Response
                axi_bvalid_reg     <= 1'b0;
                axi_awready_reg    <= 1'b1; // heres ready for the new write transaction
            end
        end
    end

    // Register write and reset process
    integer byte_id;
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
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