`include "round_robin_arbiter.v"

module round_robin_arbiter_tb;

reg clk, reset;
reg [4:0] request;
wire [4:0] grant_vec;
wire [2:0] crossbar_control;

round_robin_arbiter uut (.clk(clk), .reset(reset), .request(request),
 .grant_vec(grant_vec), .crossbar_control(crossbar_control));

 always
    #10 clk = ~clk;

initial
    begin
        clk = 0;
        reset = 1;
        request = 0;
        #11 reset = 0;
        request = 5'b11100;
        #20 request = 5'b11000;
        #120 request = 5'b01110;
        #140 request = 5'b01000;
        #140 request = 5'b10010;
        #140 request = 5'b11100;
        #140 request = 5'b11100;
        #140 request = 5'b11100;
        #140 request = 5'b11100;
    end
endmodule