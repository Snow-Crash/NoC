
`include "../router/router.v"

module mesh_two_one (clk, rt_clk,reset,
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

input [31:0] local_in1, local_in2;
input [3:0] north_in1, south_in1, west_in1;
input [3:0] north_in2, south_in2, east_in2;

input reset, clk, rt_clk;
input write_en_local1, write_en_north1, write_en_south1, write_en_west1;
input write_en_local2, write_en_north2, write_en_south2, write_en_east2;

input local_neuron_full1, north_neighbor_full1, south_neighbor_full1, west_neighbor_full1;
input local_neuron_full2, north_neighbor_full2, south_neighbor_full2, east_neighbor_full2;

output [3:0] local_out1, north_out1, south_out1, west_out1;
output [3:0] local_out2, north_out2, south_out2, east_out2;
output write_req_local1, write_req_north1, write_req_south1, write_req_west1;
output write_req_local2, write_req_north2, write_req_south2, write_req_east2;
output local_full1, north_full1, south_full1, west_full1;
output local_full2, north_full2, south_full2, east_full2;

wire [3:0] local_out1, north_out1, south_out1, west_out1;
wire [3:0] local_out2, north_out2, south_out2, east_out2;

wire write_r_local1, write_r_north1, write_r_south1, write_r_west1;
wire write_r_local2, write_r_north2, write_r_south2, write_r_east2;

wire [3:0] east1_west2, west2_east1;

wire clk_east1_west2, clkl_west2_east1;
wire east_full1_west2, west_full2_east1;
wire write_req_west2_east1;
wire write_req_east1_west2;

router rt1 (.clk(rt_clk), .clk_local(clk), .clk_north(rt_clk), .clk_south(rt_clk), .clk_east(rt_clk), .clk_west(rt_clk),
.reset(reset), .local_in(local_in1), .north_in(north_in1), .south_in(south_in1), .east_in(west2_east1), .west_in(west_in1),
.local_out(local_out1), .north_out(north_out1), .south_out(south_out1), .east_out(east1_west2), .west_out(west_out1),
.local_full(local_full1), .north_full(north_full1), .south_full(south_full1), .east_full(east_full1_west2), .west_full(west_full1),
.local_neuron_full(local_neuron_full1), .north_neighbor_full(north_neighbor_full1), .south_neighbor_full(south_neighbor_full1), .east_neighbor_full(west_full2_east1), .west_neighbor_full(west_neighbor_full1),
.write_en_local(write_en_local1), .write_en_north(write_en_north1), .write_en_south(write_en_south1), .write_en_east(write_req_west2_east1), .write_en_west(write_en_west1),
.write_req_local(write_r_local1), .write_req_north(write_r_north1), .write_req_south(write_en_south1), .write_req_east(write_req_east1_west2), .write_req_west(write_r_west1));

router rt2 (.clk(rt_clk), .clk_local(clk), .clk_north(rt_clk), .clk_south(rt_clk), .clk_east(rt_clk), .clk_west(rt_clk),
.reset(reset), .local_in(local_in2), .north_in(north_in2), .south_in(south_in2), .east_in(east_in2), .west_in(east1_west2),
.local_out(local_out2), .north_out(north_out2), .south_out(south_out2), .east_out(east_out2), .west_out(west2_east1),
.local_full(local_full2), .north_full(north_full2), .south_full(south_full2), .east_full(east_full2), .west_full(west_full2_east1),
.local_neuron_full(local_neuron_full2), .north_neighbor_full(north_neighbor_full2), .south_neighbor_full(south_neighbor_full2), .east_neighbor_full(east_neighbor_full2), .west_neighbor_full(east_full1_west2),
.write_en_local(write_en_local2), .write_en_north(write_en_north2), .write_en_south(write_en_south2), .write_en_east(write_en_east2), .write_en_west(write_req_east1_west2),
.write_req_local(write_r_local2), .write_req_north(write_r_north2), .write_req_south(write_en_south2), .write_req_east(write_r_east2), .write_req_west(write_req_west2_east1));

/*
router router1(.clk(clk1), .clk_local(clk_local1), .clk_north(clk_north1), .clk_south(clk_south1), .clk_east(clk_east1_west2), .clk_west(clk_west1),
.reset(reset1), .local_in(local_in1), .north_in(north_in1), .south_in(south_in1), .east_in(west2_east1), .west_in(west_in1), 
.local_out(local_out1), .north_out(north_out1), .south_out(south_out), .east_out(east1_west2), .west_out(west_out1),
.local_full(local_full1), .north_full(north_full1), .south_full(south_full1), .east_full(east_full1_west2), .west_full(west_full1),
.reset_local(reset_local), .reset_north(reset_north), .reset_south(reset_south1), .reset_east(), .reset_west(reset2), .write_local(write_local1), .write_north(write_north1),
.write_south(write_req_south1), .write_east(write_req_west2_east1), .write_west(write_west1), .write_req_local(write_req_local1), .write_req_north(write_req_north1), .write_req_south(write_req_south1),
.write_req_east(write_req_east1_west2), .write_req_west(write_req_west1));

router router2(.clk(clk2), .clk_local(clk_east2), .clk_north(clk_north2), .clk_south(clk_south2), .clk_east(clk_east2), .clk_west(clk1),
.reset(reset2), .local_in(local_in2), .north_in(north_in2), .south_in(south_in2), .east_in(east_in2), .west_in(east1_west2),
.local_out(local_out2), .north_out(north_out2), .south_out(south_out2), .east_out(east_out2), .west_out(west2_east1),
.local_full(local_full2), .north_full(north_full2), .south_full(south_full2), .east_full(east_full2), .west_full(west_full2_east1),
.reset_local(reset_local2), .reset_north(reset_north2), .reset_south(reset_south2), .reset_east(reset_east2), .reset_west(reset1), .write_local(write_local2), .write_north(write_north2),
.write_south(write_south2), .write_east(write_east2), .write_west(write_req_east1_west2), .write_req_local(write_req_local2), .write_req_north(write_north2), .write_req_south(write_req_south2),
.write_req_east(write_east2), .write_req_west(write_req_west2_east1));
*/


endmodule

