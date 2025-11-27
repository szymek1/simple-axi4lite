`ifndef AXI_4_LITE_CONFIGURATION_V
`define AXI_4_LITE_CONFIGURATION_V

// Data bus details
`define C_AXI_DATA_WIDTH   32
`define C_REGISTERS_NUMBER 32
`define C_AXI_STROBE_WIDTH (`C_AXI_DATA_WIDTH / 8)
`define C_ADDR_LSB $clog2(`C_AXI_DATA_WIDTH / 8)    // bits used for the byte offset
`define C_ADDR_REG_BITS $clog2(`C_REGISTERS_NUMBER) // bits used for register index
`define C_AXI_ADDR_WIDTH (`C_ADDR_LSB + `C_ADDR_REG_BITS)

// AXI write flags
// output by the slave

// BRESP & RRESP flags
`define OKAY   2'b00
`define EXOKAY 2'b01
`define SLVERR 2'b10
`define DECERR 2'b11

// for S_AXI_AWREADY
`define SLV_AXI_WRT_ADDR_READY  1'b1
`define SLV_AXI_WRT_ADDR_NREADY 1'b0

// for S_AXI_WREADY
`define SLV_AXI_WRT_DATA_READY  1'b1
`define SLV_AXI_WRT_DATA_NREADY 1'b0

// for S_AXI_BVALID
`define SLV_AXI_WRT_VALID       1'b1
`define SLV_AXI_WRT_NVALID      1'b0

// for S_AXI_ARREADY
`define SLV_AXI_RD_ADDR_READY   1'b1
`define SLV_AXI_RD_ADDR_NREADY  1'b0

// for S_AXI_RVALID
`define SLV_AXI_RD_ADDR_VALID   1'b1
`define SLV_AXI_RD_ADDR_NVALID  1'b0

// output by master

// for S_AXI_AWVALID
`define MS_WRT_ADDR_VALID  1'b1
`define MS_WRT_ADDR_NVALID 1'b0

// for S_AXI_WVALID
`define MS_WRT_DATA_VALID  1'b1
`define MS_WRT_DATA_NVALID 1'b0

// for S_AXI_BREADY
`define MS_WRT_RESP_READY  1'b1
`define MS_WRT_RESP_NREADY 1'b0

// for S_AXI_ARVALID
`define MS_RD_ADDR_VALID   1'b1
`define MS_RD_ADDR_NVALID  1'b0

// for S_AXI_RREADY
`define MS_RD_ADDR_READY   1'b1
`define MS_RD_ADDR_NREADY  1'b0

`endif