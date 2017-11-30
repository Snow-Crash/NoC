`include "neuron_define.v"

module neuron_router_cell(clk, rst_n, rt_clk, rt_rst, start,
clk_east, clk_west, clk_north, clk_south,
wr_req_in_north, wr_req_in_south, wr_req_in_east, wr_req_in_west,
wr_req_out_north, wr_req_out_south, wr_req_out_east, wr_req_out_west,
flit_in_north, flit_in_south, flit_in_east, flit_in_west,
flit_out_north, flit_out_south, flit_out_east, flit_out_west,
full_in_north, full_in_south, full_in_east, full_in_west,
full_out_north, full_out_south, full_out_east, full_out_west);

parameter packet_size = 32;
parameter flit_size = 4;
parameter NUM_NURNS = 128;
parameter NUM_AXONS = 256;
parameter NURN_CNT_BIT_WIDTH = 1;
parameter AXON_CNT_BIT_WIDTH = 1;
parameter X_ID = "1";
parameter Y_ID = "1";
parameter SYNTH_PATH = "D:/code/synth/data";
parameter SIM_PATH =  "D:/code/data";
parameter X_COORDINATE = 0;
parameter Y_COORDINATE = 0;
parameter STOP_STEP = 5;

input clk, rst_n, rt_clk, rt_rst, start;
input clk_east, clk_west, clk_north, clk_south;
input wr_req_in_north, wr_req_in_south, wr_req_in_east, wr_req_in_west;
input wr_req_out_north, wr_req_out_south, wr_req_out_east, wr_req_out_west;
input [3:0] flit_in_north, flit_in_south, flit_in_east, flit_in_west;
output [3:0] flit_out_north, flit_out_south, flit_out_east, flit_out_west;
input full_in_north, full_in_south, full_in_east, full_in_west;
output full_out_north, full_out_south, full_out_east, full_out_west;

wire [3:0] flit_out_local;
wire outSpike;
wire [31:0] flit_in_local;
wire full_in_local, full_out_local;
wire wr_req_out_local;
wire [(1<<AXON_CNT_BIT_WIDTH) - 1:0] spike;


`ifdef LOCAL_PACKET_BYPASS
wire [31:0] packet_to_interface;
wire write_req_to_router;

Neuron #(
        .X_ID(X_ID), 
        .Y_ID(Y_ID), 
        .NUM_NURNS(NUM_NURNS), 
        .NUM_AXONS(NUM_AXONS), 
        .NURN_CNT_BIT_WIDTH(NURN_CNT_BIT_WIDTH), 
        .AXON_CNT_BIT_WIDTH(AXON_CNT_BIT_WIDTH),
        .SYNTH_PATH(SYNTH_PATH),
        .SIM_PATH(SIM_PATH),
		.STOP_STEP(STOP_STEP)
        ) 
uut_neuron (
    .clk(clk), 
    .rst_n(rst_n), 
    .SpikePacket(packet_to_interface), 
    
    .start(start), 
    .inSpike(spike),
`ifdef AER_MULTICAST
    .outSpike(outSpike),
	.packet_write_req(packet_write_req)
`else
    .outSpike(packet_write_req),
    .packet_write_req( )
`endif
    );

router #(
        .X_COORDINATE(X_COORDINATE),
        .Y_COORDINATE(Y_COORDINATE),
		.X_ID(X_ID),
		.Y_ID(Y_ID),
		.SIM_PATH(SIM_PATH),
		.STOP_STEP(STOP_STEP)
        )
uut_rt (
        .clk(rt_clk), 
        .clk_local(clk), 
        .clk_north(clk_north), 
        .clk_south(clk_south), 
        .clk_east(clk_east), 
        .clk_west(clk_west),
        .reset(rt_rst), 
        .local_in(flit_in_local), 
        .north_in(flit_in_north), 
        .south_in(flit_in_south), 
        .east_in(flit_in_east), 
        .west_in(flit_in_west),
        .local_out(flit_out_local), 
        .north_out(flit_out_north), 
        .south_out(flit_out_south), 
        .east_out(flit_out_east), 
        .west_out(flit_out_west),
        .local_full(full_out_local), 
        .north_full(full_out_north), 
        .south_full(full_out_south), 
        .east_full(full_out_east), 
        .west_full(full_out_west),
        .write_en_local(write_req_to_router), 
        .write_en_north(wr_req_in_north), 
        .write_en_south(wr_req_in_south), 
        .write_en_east(wr_req_in_east), 
        .write_en_west(wr_req_in_west),
        .write_req_local(wr_req_out_local), 
        .write_req_north(wr_req_out_north), 
        .write_req_south(wr_req_out_south),
        .write_req_east(wr_req_out_east), 
        .write_req_west(wr_req_out_west),
        .local_neuron_full(full_in_local), 
        .north_neighbor_full(full_in_north), 
        .south_neighbor_full(full_in_south), 
        .east_neighbor_full(full_in_east), 
        .west_neighbor_full(full_in_west),
		.start(start)
);

interface #(
            .packet_size(packet_size),
            .flit_size(flit_size),
            .x_address_length(8),
            .y_address_length(8),
            .NUM_AXONS(NUM_AXONS),
            .AXON_CNT_BIT_WIDTH(AXON_CNT_BIT_WIDTH),
			.X_ID(X_ID),
			.Y_ID(Y_ID),
			.SIM_PATH(SIM_PATH),
			.SYNTH_PATH(SYNTH_PATH),
			.STOP_STEP(STOP_STEP),
			.X_COORDINATE(X_COORDINATE),
			.Y_COORDINATE(Y_COORDINATE)
            ) 
neu_interface 
            (
            .router_clk(rt_clk), 
            .neuron_clk(clk), 
            .rst_n(rst_n), 
            .router_reset(rt_rst), 
            .write_en(wr_req_out_local), 
            .start(start), 
            .data_in(flit_out_local), 
            .spike(spike),
            .neuron_full(full_in_local),
			.write_en_from_neuron(packet_write_req),
			.write_req_to_router(write_req_to_router),
			.packet_to_router(flit_in_local),
			.packet_from_neuron(packet_to_interface)
            );
`else
Neuron #(
        .X_ID(X_ID), 
        .Y_ID(Y_ID), 
        .NUM_NURNS(NUM_NURNS), 
        .NUM_AXONS(NUM_AXONS), 
        .NURN_CNT_BIT_WIDTH(NURN_CNT_BIT_WIDTH), 
        .AXON_CNT_BIT_WIDTH(AXON_CNT_BIT_WIDTH),
        .SYNTH_PATH(SYNTH_PATH),
        .SIM_PATH(SIM_PATH),
		.STOP_STEP(STOP_STEP)
        ) 
uut (
    .clk(clk), 
    .rst_n(rst_n), 
    .SpikePacket(flit_in_local), 
    .start(start), 
    .inSpike(spike)
`ifdef AER_MULTICAST
    .outSpike(outSpike),
	.packet_write_req(packet_write_req)
`else
    .outSpike(packet_write_req),
    .packet_write_req( )
`endif
    );

router #(
        .X_COORDINATE(X_COORDINATE),
        .Y_COORDINATE(Y_COORDINATE),
		.X_ID(X_ID),
		.Y_ID(Y_ID),
		.SIM_PATH(SIM_PATH),
		.STOP_STEP(STOP_STEP)
        )
rt (
        .clk(rt_clk), 
        .clk_local(clk), 
        .clk_north(clk_north), 
        .clk_south(clk_south), 
        .clk_east(clk_east), 
        .clk_west(clk_west),
        .reset(rt_rst), 
        .local_in(flit_in_local), 
        .north_in(flit_in_north), 
        .south_in(flit_in_south), 
        .east_in(flit_in_east), 
        .west_in(flit_in_west),
        .local_out(flit_out_local), 
        .north_out(flit_out_north), 
        .south_out(flit_out_south), 
        .east_out(flit_out_east), 
        .west_out(flit_out_west),
        .local_full(full_out_local), 
        .north_full(full_out_north), 
        .south_full(full_out_south), 
        .east_full(full_out_east), 
        .west_full(full_out_west),
        .write_en_local(packet_write_req), 
        .write_en_north(wr_req_in_north), 
        .write_en_south(wr_req_in_south), 
        .write_en_east(wr_req_in_east), 
        .write_en_west(wr_req_in_west),
        .write_req_local(wr_req_out_local), 
        .write_req_north(wr_req_out_north), 
        .write_req_south(wr_req_out_south),
        .write_req_east(wr_req_out_east), 
        .write_req_west(wr_req_out_west),
        .local_neuron_full(full_in_local), 
        .north_neighbor_full(full_in_north), 
        .south_neighbor_full(full_in_south), 
        .east_neighbor_full(full_in_east), 
        .west_neighbor_full(full_in_west),
		.start(start)
);

interface #(
            .packet_size(packet_size),
            .flit_size(flit_size),
            .x_address_length(8),
            .y_address_length(8),
            .NUM_AXONS(NUM_AXONS),
            .AXON_CNT_BIT_WIDTH(AXON_CNT_BIT_WIDTH),
			.X_ID(X_ID),
			.Y_ID(Y_ID),
			.SIM_PATH(SIM_PATH),
			.SYNTH_PATH(SYNTH_PATH),
			.STOP_STEP(STOP_STEP)
            ) 
neu_interface 
            (
            .router_clk(rt_clk), 
            .neuron_clk(clk), 
            .rst_n(rst_n), 
            .router_reset(rt_rst), 
            .write_en(wr_req_out_local), 
            .start(start), 
            .data_in(flit_out_local), 
            .spike(spike),
            .neuron_full(full_in_local)
            );
`endif

endmodule