//`include "two_by_one.v"

`timescale 1ns/100ps

module mesh_two_by_one_tb();

reg clk, rt_clk, reset;
reg [31:0] local_in1, local_in2;
reg [3:0] north_in1, south_in1, west_in1;
reg [3:0] north_in2, south_in2, east_in2;
wire [3:0] local_out1, north_out1, south_out1, west_out1;
wire [3:0] local_out2, north_out2, south_out2, east_out2;
wire local_full1, north_full1, south_full1, west_full1;
wire local_full2, north_full2, south_full2, east_full2;


wire write_req_local1, write_req_north1, write_req_south1, write_req_west1;
wire write_req_local2, write_req_north2, write_req_south2, write_req_east2;

reg write_en_local1, write_en_north1, write_en_south1, write_en_west1;
reg write_en_local2, write_en_north2, write_en_south2, write_en_east2;

reg local_neuron_full1, north_neighbor_full1, south_neighbor_full1, west_neighbor_full1;
reg local_neuron_full2, north_neighbor_full2, south_neighbor_full2, east_neighbor_full2;


mesh_two_one uut (clk, rt_clk,reset,
local_in1, north_in1, south_in1, west_in1,
local_in2, north_in2, south_in2, east_in2,
local_out1, north_out1, south_out1, west_out1,
local_out2, north_out2, south_out2, east_out2,
local_full1, north_full1, south_full1, west_full1,
local_full2, north_full2, south_full2, east_full2,
write_req_local1, write_req_north1, write_req_south1, write_req_west1, 
write_req_local2, write_req_north2, write_req_south2, write_req_east2, 
write_en_local1, write_en_north1, write_en_south1, write_en_west1,
write_en_local2, write_en_north2, write_en_south2, write_en_east2,
local_neuron_full1, north_neighbor_full1, south_neighbor_full1, west_neighbor_full1,
local_neuron_full2, north_neighbor_full2, south_neighbor_full2, east_neighbor_full2);

always
    begin
        #20 clk = ~clk;
    end

always
    begin
        #10 rt_clk = ~rt_clk;
    end


initial
    begin
    clk = 0; rt_clk = 0;
    reset = 1;
    write_en_local1 = 1;
    east_neighbor_full2 = 1;
    local_in1 = 32'h98765432;
    north_in1 = 0; south_in1 = 0; west_in1 = 0; 
    #11 reset = 0;
    #20 write_en_local1 = 1;
        local_in1 = 32'habcd7643;
    #40 write_en_local1 = 0;
    #600 east_neighbor_full2 = 0;

    end
initial
    begin
        write_en_west1 = 0;
        #11  write_en_west1 = 1;
            west_in1 = 4'h3;
        #20 west_in1 = 4'h4;
        #20 west_in1 = 4'h7;
        #20 west_in1 = 4'h8;
        #20 west_in1 = 4'hc;
        #20 west_in1 = 4'hd;
        #20 west_in1 = 4'he;
        #20 west_in1 = 4'hf;
        #20 write_en_west1 = 0;
        #200 write_en_west1 = 1;
    end



endmodule