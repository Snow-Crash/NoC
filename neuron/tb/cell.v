//neuron_cell cintains a router and a neuron

module neuron_cell(clk, rt_clk, rst_n, rt_reset, start,
clk_north, clk_south, clk_east, clk_west,
north_in, south_in, east_in, west_in,
north_neighbor_full, south_neighbor_full, east_neighbor_full, west_neighbor_full,
north_out, south_out, east_out, west_out,
north_full, south_full, east_full, west_full,
write_req_north, write_req_south, write_req_east, write_req_west,
write_en_north, write_en_south, write_en_east, write_en_west);

parameter DIRID = "1";
parameter neuron_number = 2;
parameter axon_number = 2;
parameter neuron_number_bit_width = 1;
parameter axon_number_bit_width = 1;

localparam packet_size = 32;
localparam flit_size = 4;

input clk, rt_clk, clk_north, clk_south, clk_east, clk_west;
input rst_n, rt_reset, start;
input north_neighbor_full, south_neighbor_full, east_neighbor_full, west_neighbor_full;
input write_en_north, write_en_south, write_en_east, write_en_west;
input [flit_size - 1:0] north_in, south_in, east_in, west_in;
output north_full, south_full, east_full, west_full;
output [flit_size - 1:0]  north_out, south_out, east_out, west_out;
output write_req_north, write_req_south, write_req_east, write_req_west;

wire [31:0] SpikePacket;
wire outSpike;
wire [3:0] local_packet_out;
wire local_full, write_req_east, local_neuron_full;

Neuron #(.DIRID(DIRID), .NUM_NURNS(), .NUM_AXONS(), .NURN_CNT_BIT_WIDTH(), .AXON_CNT_BIT_WIDTH()) 
uut (.clk(clk), .rst_n(rst_n), .SpikePacket(SpikePacket), .outSpike(outSpike),. start(start));

router rt (.clk(rt_clk), .clk_local(clk), .clk_north(clk_north), .clk_south(clk_south), .clk_east(clk_east), .clk_west(clk_west),
.reset(rt_reset), .local_in(SpikePacket), .north_in(north_in), .south_in(south_in), .east_in(east_in), .west_in(west_in),
.local_out(local_packet_out), .north_out(north_out), .south_out(south_out), .east_out(east_out), .west_out(west_out),
.local_full(local_full), .north_full(north_full), .south_full(south_full), .east_full(east_full), .west_full(west_full),
.write_en_local(outSpike), .write_en_north(write_en_north), .write_en_south(write_en_south), .write_en_east(write_en_east), .write_en_west(write_en_west),
.write_req_local(write_req_local), .write_req_north(write_req_north), .write_req_south(write_req_south),
.write_req_east(write_req_east), .write_req_west(write_req_west),
.local_neuron_full(local_neuron_full), .north_neighbor_full(north_neighbor_full), .south_neighbor_full(south_neighbor_full), .east_neighbor_full(east_neighbor_full), .west_neighbor_full(west_neighbor_full));

endmodule