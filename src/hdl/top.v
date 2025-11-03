`timescale 1ns/1ps
module top (
    input wire sysclk,
    input wire [0:0] sw,
    output reg [0:0] led
);

    reg [24:0] blk_cnt = 0;
    always @(posedge sysclk) begin
        if (sw[0] == 1'b0) begin
            blk_cnt <= 0;
            led[0] <= 1'b0;
        end else begin
            blk_cnt <= blk_cnt + 1;
            if (blk_cnt == 0) begin
                led[0] <= ~led[0];
            end
        end
    end

endmodule