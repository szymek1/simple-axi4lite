`ifndef AXI_4_LITE_CONFIGURATION_V
`define AXI_4_LITE_CONFIGURATION_V

// Data bus details
`define C_AXI_DATA_WIDTH   32
`define C_REGISTERS_NUMBER 32

// BRESP & RRESP flags
`define OKAY   2'b00
`define EXOKAY 2'b01
`define SLVERR 2'b10
`define DECERR 2'b11

`endif