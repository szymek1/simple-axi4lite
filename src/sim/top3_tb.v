`timescale 1ns/1ps
module top3_tb;
    reg sysclk = 0;
    reg [0:0] sw = 0;
    wire [0:0] led;

    top uut (.sysclk(sysclk), .sw(sw), .led(led));

    initial begin
        forever #4 sysclk = ~sysclk;  // 125 MHz clock (8 ns period)
    end

    initial begin
        $dumpfile("waveform3.vcd"); // Add waveform dumping
        $dumpvars(0, top3_tb);

        #100;  
        sw[0] = 1'b1;
        #1000; 
        sw[0] = 1'b0;
        #200;  
        $finish;
    end
endmodule