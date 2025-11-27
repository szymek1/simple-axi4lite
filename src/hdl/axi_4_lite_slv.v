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
    reg                         S_AXI_AWREADY_;
    reg                         S_AXI_WREADY_;
    reg                         S_AXI_BVALID_;
    reg [1:0]                   S_AXI_BRESP_;
    reg [`C_ADDR_REG_BITS-1:0]  axi_awaddr_latched;  // latched write address
    reg                         slv_reg_wren;       // internal write-enable pulse for user logic

    // Read channel internal registers
    reg                         S_AXI_ARREADY_;
    reg                         S_AXI_RVALID_;
    reg [1:0]                   S_AXI_RRESP_;
    reg [`C_AXI_DATA_WIDTH-1:0] S_AXI_RDATA_;      // pipelined read data output
    reg [`C_ADDR_REG_BITS-1:0]  axi_araddr_latched; // latched read address

    // Output wires
    // Write related
    assign S_AXI_AWREADY = S_AXI_AWREADY_;
    assign S_AXI_WREADY  = S_AXI_WREADY_;
    assign S_AXI_BVALID  = S_AXI_BVALID_;
    assign S_AXI_BRESP   = S_AXI_BRESP_;

    // Read related
    assign S_AXI_ARREADY = S_AXI_ARREADY_;
    assign S_AXI_RVALID  = S_AXI_RVALID_;
    assign S_AXI_RRESP   = S_AXI_RRESP_;
    assign S_AXI_RDATA   = S_AXI_RDATA_;

    // Read process
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_ARREADY_     <= 1'b1; 
            S_AXI_RVALID_      <= 1'b0;
            axi_araddr_latched <= 0;
            S_AXI_RDATA_       <= 0;
            S_AXI_RRESP_       <= `AXI_RESP_OKAY;
        end else begin
            if (S_AXI_ARVALID && S_AXI_ARREADY_) begin
                // Address handshake: slave is by default ready so the handshake happends immediately
                //                    once the master issue the address
                S_AXI_ARREADY_     <= 1'b0; 
                axi_araddr_latched <= read_index;             
                S_AXI_RVALID_      <= 1'b1;  // data will be valid in the next cycle
                S_AXI_RRESP_       <= `AXI_RESP_OKAY;
                S_AXI_RDATA_       <= regfile[read_index];
            end else if (S_AXI_RREADY && S_AXI_RVALID_) begin
                // Transaction complete: master accepts the data
                S_AXI_RVALID_      <= 1'b0;
                S_AXI_ARREADY_     <= 1'b1;  // heres ready for the new read transaction
            end
        end
    end

    // Write process
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_AWREADY_     <= 1'b1; 
            S_AXI_WREADY_      <= 1'b0;
            S_AXI_BVALID_      <= 1'b0;
            S_AXI_BRESP_       <= `AXI_RESP_OKAY;
            axi_awaddr_latched <= 0;
            slv_reg_wren       <= 0;
        end else begin
            slv_reg_wren       <= 1'b0;

            if (S_AXI_AWVALID && S_AXI_AWREADY_) begin
                // Address handshake: slave is by default READY and master has to issue VALID
                axi_awaddr_latched <= write_index;
                S_AXI_AWREADY_     <= 1'b0;
                S_AXI_WREADY_      <= 1'b1;  
            end else if (S_AXI_WVALID && S_AXI_WREADY_) begin
                // Data handshake: slave is ready to accept new write data and it's waiting for the master to issue VALID
                S_AXI_WREADY_      <= 1'b0;
                slv_reg_wren       <= 1'b1;                        
                S_AXI_BVALID_      <= 1'b1;       
                S_AXI_BRESP_       <= `AXI_RESP_OKAY;
            end else if (S_AXI_BVALID && S_AXI_BREADY) begin
                // Response
                S_AXI_BVALID_      <= 1'b0;
                S_AXI_AWREADY_     <= 1'b1; // heres ready for the new write transaction
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