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
    reg [`C_ADDR_REG_BITS-1:0] axi_awaddr_latched; // latched write address
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
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_arready_reg    <= `SLV_AXI_RD_ADDR_NREADY;
            axi_rvalid_reg     <= `SLV_AXI_RD_ADDR_NVALID;

            axi_araddr_latched <= 0;
            axi_rdata_reg      <= 0;
            axi_rresp_reg      <= 2'bx;
        end else begin
            axi_arready_reg    <= `SLV_AXI_RD_ADDR_NREADY;
            axi_rvalid_reg     <= `SLV_AXI_RD_ADDR_NVALID;

            // Read transaction begins: master issues read address and sets S_AXI_ARVALID high
            if (S_AXI_ARVALID == `MS_RD_ADDR_VALID && axi_arready_reg == `SLV_AXI_RD_ADDR_NREADY) begin
                axi_arready_reg    <= `SLV_AXI_RD_ADDR_READY;
                axi_araddr_latched <= read_index;
            end

            // Read handshake: read data will be available in the next clock cycle
            if (S_AXI_ARVALID == `MS_RD_ADDR_VALID && axi_arready_reg == `SLV_AXI_RD_ADDR_READY) begin
                axi_arready_reg <= `SLV_AXI_RD_ADDR_NREADY;
                axi_rvalid_reg  <= `SLV_AXI_RD_ADDR_VALID;
                axi_rresp_reg   <= `OKAY;
                axi_rdata_reg   <= regfile[axi_araddr_latched];
            end

            if (S_AXI_RREADY == `MS_RD_ADDR_READY && axi_rvalid_reg == `SLV_AXI_RD_ADDR_VALID) begin
                axi_rvalid_reg  <= `SLV_AXI_RD_ADDR_NVALID;
                axi_rresp_reg   <= 2'bx;
                axi_rdata_reg   <= 0;
            end
        end
    end

    // Write process
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_awready_reg    <= `SLV_AXI_WRT_ADDR_NREADY;
            axi_wready_reg     <= `SLV_AXI_WRT_DATA_NREADY;
            axi_bvalid_reg     <= `SLV_AXI_WRT_NVALID;

            axi_awaddr_latched <= 0;
            slv_reg_wren       <= 0;
        end else begin
            axi_awready_reg    <= `SLV_AXI_WRT_ADDR_NREADY;
            axi_wready_reg     <= `SLV_AXI_WRT_DATA_NREADY;
            axi_bvalid_reg     <= `SLV_AXI_WRT_NVALID;

            slv_reg_wren       <= 0;

            // Write transaction begins: master issues write addresss and sets S_AXI_AWVALID high
            if (S_AXI_AWVALID == `MS_WRT_ADDR_VALID && axi_awready_reg == `SLV_AXI_WRT_ADDR_NREADY) begin
                axi_awready_reg    <= `SLV_AXI_WRT_ADDR_READY;
                axi_awaddr_latched <= write_index;
            end 

            // Write address handshake is complete 
            if (S_AXI_AWVALID == `MS_WRT_ADDR_VALID && axi_awready_reg == `SLV_AXI_WRT_ADDR_READY) begin
                axi_wready_reg     <= `SLV_AXI_WRT_DATA_READY;   
            end

            // Waiting for the master to issue S_AXI_WVALID high to make sure that there's a write data available
            if (S_AXI_WVALID == `MS_WRT_DATA_NVALID && axi_wready_reg == `SLV_AXI_WRT_DATA_READY) begin
                axi_wready_reg     <= `SLV_AXI_WRT_DATA_READY; 
            end

            // Register file will begin writing in the next clock cycle once this condition is satisfied
            if (S_AXI_WVALID == `MS_WRT_DATA_VALID && S_AXI_BREADY == `MS_WRT_RESP_READY && axi_wready_reg == `SLV_AXI_WRT_DATA_READY) begin
                slv_reg_wren       <= 1;
                axi_bresp_reg      <= `OKAY;
                axi_bvalid_reg     <= `SLV_AXI_WRT_VALID;
            end
        end
    end

    // Register write and reset process
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