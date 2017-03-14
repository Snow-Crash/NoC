`include "two_by_one.v"

module mesh_two_by_one_tb();

reg clk1, clk2;
reg [3:0] local_in1, north_in1, south_in1, west_in1;
reg [3:0] local_in2, north_in2, south_in2, east_in2;
wire [3:0] local_out1, north_out1, south_out1, west_out1;
wire [3:0] local_out2, north_out2, south_out2, east_out2;
wire local_full1, north_full1, south_full1, west_full1;
wire local_full2, north_full2, south_full2, east_full2;
reg reset1, reset2;

reg reset_local1, reset_north1, reset_south1, reset_west1;
reg reset_local2, reset_north2, reset_south2, reset_east2;
reg clk_local1, clk_north1, clk_south1, clk_west1;
reg clk_local2, clk_north2, clk_south2, clk_east2;

wire write_req_local1, write_req_north1, write_req_south1, write_req_west1;
wire write_req_local2, write_req_north2, write_req_south2, write_req_east2;
reg write_local1, write_north1, write_south1, write_west1;
reg write_local2, write_north2, write_south2, write_east2;


mesh_two_one uut (clk1, clk2, 
local_in1, north_in1, south_in1, west_in1,
local_in2, north_in2, south_in2, east_in2,
local_out1, north_out1, south_out1, west_out1,
local_out2, north_out2, south_out2, east_out2,
local_full1, north_full1, south_full1, west_full1,
local_full2, north_full2, south_full2, east_full2,
reset1, reset2, 
reset_local1, reset_north1, reset_south1, reset_west1,
reset_local2, reset_north2, reset_south2, reset_east2,
clk_local1, 0, 0, clk_west1,
clk_local2, clk_north2, clk_south2, clk_east2,
write_req_local1, write_req_north1, write_req_south1, write_req_west1, 
write_req_local2, write_req_north2, write_req_south2, write_req_east2, 
write_local1, write_north1, write_south1, write_west1,
write_local2, write_north2, write_south2, write_east2);

always
    begin
        #10 clk1 = ~clk1;
    end

always
    begin
        #10 clk2 = ~clk2;
    end

always
    #10 clk_west1 = ~clk_west1;

initial
    begin
    clk1 = 0; clk2 = 0;
    clk_local1 = 0; clk_north1 = 0; clk_south1 = 0; clk_west1 = 0;
    reset1 = 1; reset_local1 = 1;  reset_north1 = 1; reset_south1 = 1; reset_west1 = 1;
    reset2 = 1;
    write_west1 = 0; write_local1 = 0; write_south1 = 0; write_north1 = 0;
    local_in1 = 0; north_in1 = 0; south_in1 = 0; west_in1 = 0; 
    #11 reset_local1 = 0;
    #20
    write_local1 = 1;
    local_in1 = 4'h5;
    #40 local_in1 = 4'h6;
    #40 local_in1 = 4'hb;
    #40 local_in1 = 4'hc;
    #40 local_in1 = 4'he;
    #40 local_in1 = 4'hf;
    #40 local_in1 = 4'he;
    #40 local_in1 = 4'hf;
    end
initial
    begin
        #10 reset1 = 0;  reset2 = 0;
            reset_west1 = 0;
        #1  write_west1 = 1;
            west_in1 = 4'h3;
        #20 west_in1 = 4'h4;
        #20 west_in1 = 4'h7;
        #20 west_in1 = 4'h8;
        #20 west_in1 = 4'hc;
        #20 west_in1 = 4'hd;
        #20 west_in1 = 4'he;
        #20 west_in1 = 4'hf;
        #20 write_west1 = 0;
        #200 write_west1 = 1;
    end



endmodule