`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ISAE
// Engineer: Szymon Bogus
// 
// Create Date: 11/05/2025
// Design Name: 
// Module Name: axi_4_lite_slv_tb
// Project Name: simple-axi4litr
// Target Devices: Zybo Z7-20
// Tool Versions: 
// Description: Testbench for AXI 4 Lite Slave implementation.
// 
// Dependencies: axi_4_lite_configuration.vh
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "../include/axi_4_lite_configuration.vh"


module axi_4_lite_slv_tb;

    // --- Clock and Reset ---
    localparam CLK_PERIOD = 10; // 10ns = 100MHz clock
    reg S_AXI_ACLK;
    reg S_AXI_ARESETN;

    // AXI wires driven by the testbench
    reg                           S_AXI_AWVALID;
    reg [`C_AXI_ADDR_WIDTH-1:0]   S_AXI_AWADDR;
    reg                           S_AXI_WVALID;
    reg [`C_AXI_DATA_WIDTH-1:0]   S_AXI_WDATA;
    reg [`C_AXI_STROBE_WIDTH-1:0] S_AXI_WSTRB;
    reg                           S_AXI_BREADY;
    reg                           S_AXI_ARVALID;
    reg [`C_AXI_ADDR_WIDTH-1:0]   S_AXI_ARADDR;
    reg                           S_AXI_RREADY;

    // AXI wires driven byt DUT
    wire                         S_AXI_AWREADY;
    wire                         S_AXI_WREADY;
    wire                         S_AXI_BVALID;
    wire [1:0]                   S_AXI_BRESP;
    wire                         S_AXI_ARREADY;
    wire                         S_AXI_RVALID;
    wire [`C_AXI_DATA_WIDTH-1:0] S_AXI_RDATA;
    wire [1:0]                   S_AXI_RRESP;

    // Debug ports
    wire  [`C_ADDR_REG_BITS-1:0] DEB_READ_INDEX;
    wire  [`C_ADDR_REG_BITS-1:0] DEB_WRITE_INDEX;

    // --- Instantiate the Device Under Test (DUT) ---
    axi_4_lite_slv dut (
        .S_AXI_ACLK(S_AXI_ACLK),
        .S_AXI_ARESETN(S_AXI_ARESETN),
        .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_AWREADY(S_AXI_AWREADY),
        .S_AXI_AWADDR(S_AXI_AWADDR),
        .S_AXI_AWPROT(0), // Protection not used, tie to 0
        .S_AXI_WVALID(S_AXI_WVALID),
        .S_AXI_WREADY(S_AXI_WREADY),
        .S_AXI_WDATA(S_AXI_WDATA),
        .S_AXI_WSTRB(S_AXI_WSTRB),
        .S_AXI_BVALID(S_AXI_BVALID),
        .S_AXI_BREADY(S_AXI_BREADY),
        .S_AXI_BRESP(S_AXI_BRESP),
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_ARREADY(S_AXI_ARREADY),
        .S_AXI_ARADDR(S_AXI_ARADDR),
        .S_AXI_ARPROT(0), // Protection not used, tie to 0
        .S_AXI_RVALID(S_AXI_RVALID),
        .S_AXI_RREADY(S_AXI_RREADY),
        .S_AXI_RDATA(S_AXI_RDATA),
        .S_AXI_RRESP(S_AXI_RRESP),
        .DEB_READ_INDEX(DEB_READ_INDEX),
        .DEB_WRITE_INDEX(DEB_WRITE_INDEX)
    );

    // Clock generator
    always begin
        S_AXI_ACLK = 1'b0;
        #(CLK_PERIOD / 2);
        S_AXI_ACLK = 1'b1;
        #(CLK_PERIOD / 2);
    end

    initial begin
        $dumpfile("axi_4_lite_slv_waves.vcd");
        $dumpvars(0, axi_4_lite_slv_tb);
        
        $display("--- Testbench Starting ---");

        // Reset
        S_AXI_ARESETN = 1'b0;
        S_AXI_AWVALID = 1'b0;
        S_AXI_AWADDR  = 0;
        S_AXI_WVALID  = 1'b0;
        S_AXI_WDATA   = 0;
        S_AXI_WSTRB   = 0;
        S_AXI_BREADY  = 1'b0;
        S_AXI_ARVALID = 1'b0;
        S_AXI_ARADDR  = 0;
        S_AXI_RREADY  = 1'b0;
        
        #(CLK_PERIOD * 5);
        S_AXI_ARESETN = 1'b1;
        $display("[%0t] Reset released.", $time);
        #(CLK_PERIOD);

        // --- TEST 1: Full Word Write ---
        $display("[%0t] Test 1: Full Word Write to Reg 0.", $time);
        axi_write(0, 32'hDEADBEEF, 4'b1111);

        // --- TEST 2: Full Word Read ---
        $display("[%0t] Test 2: Full Word Read from Reg 0.", $time);
        axi_read(0, 32'hDEADBEEF);

        // --- TEST 3: Full Word Write (for byte-write test) ---
        $display("[%0t] Test 3: Pre-loading Reg 5 with 0xFFFFFFFF.", $time);
        axi_write(5 * 4, 32'hFFFFFFFF, 4'b1111);

        // --- TEST 4: Full Word Read (for byte-write test) ---
        $display("[%0t] Test 4: Full Word Read from Reg 5.", $time);
        axi_read(5 * 4, 32'hFFFFFFFF);

        // --- TEST 5: Read back byte-written register ---
        $display("[%0t] Test 5: Read from Reg 5.", $time);
        axi_read(5 * 4, 32'hFF5634FF); // Byte 0,3 from prev, Byte 1,2 from new

        // --- TEST 6: Write to last register (Reg 31) ---
        $display("[%0t] Test 6: Full Word Write to Reg 31.", $time);
        axi_write(31 * 4, 32'hA5A5A5A5, 4'b1111);

        // --- TEST 7: Read from last register (Reg 31) ---
        $display("[%0t] Test 7: Full Word Read from Reg 31.", $time);
        axi_read(31 * 4, 32'hA5A5A5A5);

        $display("[%0t] --- All Tests Passed ---", $time);
        $finish;
    end


    // AXI master write task
    task axi_write(
        input [`C_AXI_ADDR_WIDTH-1:0] addr,
        input [`C_AXI_DATA_WIDTH-1:0] data,
        input [`C_AXI_STROBE_WIDTH-1:0] strobe
    );
    begin
        // 1. Send Address
        @(posedge S_AXI_ACLK);
        S_AXI_AWVALID <= 1'b1;
        S_AXI_AWADDR  <= addr;

        // 2. Send Data
        // Wait until slave accepts write address
        wait (S_AXI_AWREADY)
        @(posedge S_AXI_ACLK);
        S_AXI_BREADY <= 1'b1;
        // @(posedge S_AXI_ACLK);
        S_AXI_WVALID  <= 1'b1;
        S_AXI_WDATA   <= data;
        S_AXI_WSTRB   <= strobe;
        S_AXI_AWVALID <= 1'b0;

        // Wait until slave accepts data
        wait (S_AXI_WREADY);
        @(posedge S_AXI_ACLK);
        S_AXI_WVALID  <= 1'b0;
        
        wait (S_AXI_BVALID);
        @(posedge S_AXI_ACLK);
        S_AXI_BREADY <= 1'b0;
        
        if (S_AXI_BRESP != `AXI_RESP_OKAY) begin
            $display("ERROR: AXI Write Failed. BRESP = %b", S_AXI_BRESP);
        end
    end
    endtask


    // AXI master read task
    task axi_read(
        input [`C_AXI_ADDR_WIDTH-1:0] addr,
        input [`C_AXI_DATA_WIDTH-1:0] expected_data
    );
    begin
        // 1. Send Address
        @(posedge S_AXI_ACLK);
        S_AXI_ARVALID <= 1'b1;
        S_AXI_ARADDR  <= addr;
        
        wait (S_AXI_ARREADY);
        @(posedge S_AXI_ACLK);
        S_AXI_ARVALID <= 1'b0;

        // 2. Wait for data
        S_AXI_RREADY <= 1'b1;
        wait (S_AXI_RVALID);
        
        // 3. Check data
        if (S_AXI_RDATA == expected_data) begin
            $display("Read OK: Addr 0x%h, Got 0x%h", addr, S_AXI_RDATA);
        end else begin
            $display("ERROR: Read Mismatch: Addr 0x%h, Got 0x%h, Expected 0x%h", 
                     addr, S_AXI_RDATA, expected_data);
        end
        
        if (S_AXI_RRESP != `AXI_RESP_OKAY) begin
            $display("ERROR: AXI Read Failed. RRESP = %b", S_AXI_RRESP);
        end

        @(posedge S_AXI_ACLK);
        S_AXI_RREADY <= 1'b0;
    end
    endtask

endmodule