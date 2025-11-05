`ifndef AXI_4_LITE_CONFIGURATION_V
`define AXI_4_LITE_CONFIGURATION_V

// Data bus details
`define C_AXI_DATA_WIDTH   32
`define C_REGISTERS_NUMBER 32
`define C_AXI_STROBE_WIDTH (`C_AXI_DATA_WIDTH / 8)
`define C_ADDR_LSB $clog2(`C_AXI_DATA_WIDTH / 8)    // bits used for the byte offset
`define C_ADDR_REG_BITS $clog2(`C_REGISTERS_NUMBER) // bits used for register index
`define C_AXI_ADDR_WIDTH (`C_ADDR_LSB + `C_ADDR_REG_BITS)

// BRESP & RRESP flags
`define OKAY   2'b00
`define EXOKAY 2'b01
`define SLVERR 2'b10
`define DECERR 2'b11

`endif