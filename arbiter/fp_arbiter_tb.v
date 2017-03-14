`include "fp_arbiter.v"

module fp_arbiter_tb;

reg clk, reset; 

reg [4:0] req;

wire local_grant, north_grant, south_grant, east_grant, west_grant, local_request, north_request,
south_request, east_request, west_request;

wire [2:0] crossbar_control;

fp_arbiter dut (.clk(clk), .reset(reset), .local_request(local_request), .north_request(north_request),
.south_request(south_request), .east_request(east_request), .west_request(west_request), 
.local_grant(local_grant), .north_grant(north_grant), .south_grant(south_grant), .east_grant(east_grant),
 .west_grant(west_grant), .crossbar_control(crossbar_control));

 always 
    begin
    #10 clk = ~clk;
    end

assign local_request = req[4];
assign north_request = req[3];
assign south_request = req[2];
assign east_request = req[1];
assign west_request = req[0];

initial
    begin
        clk = 0;
        reset = 1;
        #10 reset = 0;
            req = 5'b11000;
        #40 req = 5'b01110;
        #80 req = 5'b00110;
        #140 req = 5'b10010;
        #300 req = 5'b01001; 
    end

endmodule
