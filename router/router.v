//2017.2.14 remove port request decode. request decode integrated in address_compute
//2017.2.15 replace fixed priority arbiter
//2017.2.17 add send_flit signal

//2017.3.5  replace fifo with altara ip
//2017.3.10 change ports. Remove 5 reset ports
//2017.3.14 modify request signal of each port.
//			if a neighbor's fifo is full, the request signal to this port should be 0
//			for example, in this testbench, the east neighbor's fifo is full,
//			local port and west port both request for east port, the request vector which inputed
//			to east arbiter is 5'b00000, instead of 5'b10001. Althought two ports send request signal,
//			arbiter doesn't receive request, the two ports will be stalled.

`define DEBUG_ROUTER
`define DUMP_STALL_EVENT
`define DUMP_DROPPED_PACKET
`define DUMP_NEURON_OUTPUT_PACKET
`define DUMP_CONGESTION

module router (clk, clk_local, clk_north, clk_south, clk_east, clk_west,
reset, local_in, north_in, south_in, east_in, west_in, 
local_out, north_out, south_out, east_out, west_out,
local_full, north_full, south_full, east_full, west_full,
local_neuron_full, north_neighbor_full, south_neighbor_full, east_neighbor_full, west_neighbor_full,
write_en_local, write_en_north, write_en_south, write_en_east, write_en_west, 
write_req_local,write_req_north, write_req_south, write_req_east, write_req_west, start);

parameter packet_size = 32;
parameter flit_size = 4;
parameter X_COORDINATE = 1;
parameter Y_COORDINATE = 1;
parameter X_ID = "1";
parameter Y_ID = "1";
parameter DIR_ID = {X_ID, "_", Y_ID};
parameter SIM_PATH = "D:/code/data";
parameter STOP_STEP = 50;

input clk, clk_north, clk_south, clk_east, clk_west, clk_local;
input reset;
input write_en_local, write_en_north, write_en_south, write_en_east, write_en_west;
input local_neuron_full, north_neighbor_full, south_neighbor_full, east_neighbor_full, west_neighbor_full;
input start;

input [flit_size-1:0] north_in, south_in, east_in, west_in;
input [31:0] local_in;

output [flit_size-1:0] local_out, north_out, south_out, east_out, west_out;

output local_full, north_full, south_full, east_full, west_full;

output write_req_local, write_req_north, write_req_south, write_req_east, write_req_west;

//wire send_flit_local, send_flit_north, send_flit_south, send_flit_east, send_flit_west;

wire local_buf_empty, north_buf_empty, south_buf_empty, east_buf_empty, west_buf_empty;
wire local_read_buf, north_read_buf, south_read_buf, east_read_buf, west_read_buf;
wire local_stall, north_stall, south_stall, east_stall, west_stall;
wire [flit_size-1:0] local_flit_in, north_flit_in, south_flit_in, east_flit_in, west_flit_in;
wire [flit_size-1:0] local_flit_out, north_flit_out, south_flit_out, east_flit_out, west_flit_out;
wire local_address_ready, north_address_ready, south_address_ready, east_address_ready, west_address_ready;
wire [2:0] local_destination, north_destination, south_destination, east_destination, west_destination;

wire [4:0] local_port_req, north_port_req, south_port_req, east_port_req, west_port_req;
wire [4:0] destination_full_vector;

								//west east south north local
assign destination_full_vector = {west_neighbor_full, east_neighbor_full, south_neighbor_full, north_neighbor_full, local_neuron_full};

port 
#(.X_COORDINATE(X_COORDINATE),
.Y_COORDINATE(Y_COORDINATE))
local_port(.clk(clk), .reset(reset), .fifo_empty(local_buf_empty),
 .stall(local_stall), .flit_in(local_flit_in), .destination_port(local_destination),  
.current_address_ready(local_address_ready), .read_fifo(local_read_buf), .flit_out(local_flit_out),
.request_vector(local_port_req), .destination_full_vector(destination_full_vector));

port 
#(.X_COORDINATE(X_COORDINATE),
.Y_COORDINATE(Y_COORDINATE))
north_port (.clk(clk), .reset(reset), .fifo_empty(north_buf_empty),
 .stall(north_stall), .flit_in(north_flit_in), .destination_port(north_destination),  
.current_address_ready(north_address_ready), .read_fifo(north_read_buf), .flit_out(north_flit_out),
.request_vector(north_port_req), .destination_full_vector(destination_full_vector));

port 
#(.X_COORDINATE(X_COORDINATE),
.Y_COORDINATE(Y_COORDINATE))
south_port (.clk(clk), .reset(reset), .fifo_empty(south_buf_empty),
 .stall(south_stall), .flit_in(south_flit_in), .destination_port(south_destination),  
.current_address_ready(south_address_ready), .read_fifo(south_read_buf), .flit_out(south_flit_out),
.request_vector(south_port_req), .destination_full_vector(destination_full_vector));

port 
#(.X_COORDINATE(X_COORDINATE),
.Y_COORDINATE(Y_COORDINATE))
east_port (.clk(clk), .reset(reset), .fifo_empty(east_buf_empty),
 .stall(east_stall), .flit_in(east_flit_in), .destination_port(east_destination),  
.current_address_ready(east_address_ready), .read_fifo(east_read_buf), .flit_out(east_flit_out),
.request_vector(east_port_req), .destination_full_vector(destination_full_vector));

port 
#(.X_COORDINATE(X_COORDINATE),
.Y_COORDINATE(Y_COORDINATE))
west_port (.clk(clk), .reset(reset), .fifo_empty(west_buf_empty),
 .stall(west_stall), .flit_in(west_flit_in), .destination_port(west_destination),  
.current_address_ready(west_address_ready), .read_fifo(west_read_buf), .flit_out(west_flit_out),
.request_vector(west_port_req), .destination_full_vector(destination_full_vector));

local_afifo	fifo_local (
	.aclr ( reset ),
	.data (local_in ),
	.rdclk ( clk ),
	.rdreq ( local_read_buf ),
	.wrclk ( clk_local ),
	.wrreq ( write_en_local ),
	.q ( local_flit_in ),
	.rdempty ( local_buf_empty ),
	.wrfull ( local_full )
	);


async_fifo fifo_north (
	.aclr ( reset ),
	.data ( north_in ),//in
	.rdclk ( clk ),
	.rdreq ( north_read_buf ),
	.wrclk ( clk_north ),
	.wrreq ( write_en_north ),
	.q ( north_flit_in ),//out
	.rdempty ( north_buf_empty ),
	.wrfull ( north_full )
	);

async_fifo fifo_south (
	.aclr ( reset ),
	.data ( south_in ),//in
	.rdclk ( clk ),
	.rdreq ( south_read_buf ),
	.wrclk ( clk_south ),
	.wrreq ( write_en_south ),
	.q ( south_flit_in ),//out
	.rdempty ( south_buf_empty ),
	.wrfull ( south_full )
	);

async_fifo fifo_east (
	.aclr ( reset ),
	.data ( east_in ),//in
	.rdclk ( clk ),
	.rdreq ( east_read_buf ),
	.wrclk ( clk_east ),
	.wrreq ( write_en_east ),
	.q ( east_flit_in ),//out
	.rdempty ( east_buf_empty ),
	.wrfull ( east_full )
	);

async_fifo fifo_west (
	.aclr ( reset ),
	.data ( west_in ),//in
	.rdclk ( clk ),
	.rdreq ( west_read_buf ),
	.wrclk ( clk_west ),
	.wrreq ( write_en_west ),
	.q ( west_flit_in ),//out
	.rdempty ( west_buf_empty ),
	.wrfull ( west_full )
	);



wire local_port_grant, north_port_grant, south_port_grant, east_port_grant, west_port_grant;
wire [4:0] local_arbiter_req, north_arbiter_req, south_arbiter_req, east_arbiter_req, west_arbiter_req;
wire [4:0] local_arbiter_grant, north_arbiter_grant, south_arbiter_grant, east_arbiter_grant, west_arbiter_grant;
wire [2:0] local_select, north_select, south_select, east_select, west_select;

round_robin_arbiter arbiter_local(.clk(clk), .reset(reset), .request(local_arbiter_req), .grant_vec(local_arbiter_grant), .crossbar_control(local_select), .write_request(write_req_local), .destination_full(local_neuron_full));

round_robin_arbiter arbiter_north(.clk(clk), .reset(reset), .request(north_arbiter_req), .grant_vec(north_arbiter_grant), .crossbar_control(north_select), .write_request(write_req_north), .destination_full(north_neighbor_full));

round_robin_arbiter arbiter_south(.clk(clk), .reset(reset), .request(south_arbiter_req), .grant_vec(south_arbiter_grant), .crossbar_control(south_select), .write_request(write_req_south), .destination_full(south_neighbor_full));

round_robin_arbiter arbiter_east(.clk(clk), .reset(reset), .request(east_arbiter_req), .grant_vec(east_arbiter_grant), .crossbar_control(east_select), .write_request(write_req_east), .destination_full(east_neighbor_full));

round_robin_arbiter arbiter_west(.clk(clk), .reset(reset), .request(west_arbiter_req), .grant_vec(west_arbiter_grant), .crossbar_control(west_select), .write_request(write_req_west), .destination_full(west_neighbor_full));


assign local_port_grant = local_arbiter_grant[0] || north_arbiter_grant[0] || south_arbiter_grant[0] || east_arbiter_grant[0] || west_arbiter_grant[0];
assign north_port_grant = local_arbiter_grant[1] || north_arbiter_grant[1] || south_arbiter_grant[1] || east_arbiter_grant[1] || west_arbiter_grant[1];
assign south_port_grant = local_arbiter_grant[2] || north_arbiter_grant[2] || south_arbiter_grant[2] || east_arbiter_grant[2] || west_arbiter_grant[2];
assign east_port_grant = local_arbiter_grant[3] || north_arbiter_grant[3] || south_arbiter_grant[3] || east_arbiter_grant[3] || west_arbiter_grant[3];
assign west_port_grant = local_arbiter_grant[4] || north_arbiter_grant[4] || south_arbiter_grant[4] || east_arbiter_grant[4] || west_arbiter_grant[4];

assign local_arbiter_req = local_neuron_full? 5'b0 : {west_port_req[0], east_port_req[0], south_port_req[0], north_port_req[0], local_port_req[0]};
assign north_arbiter_req = north_neighbor_full? 5'b0 : {west_port_req[1], east_port_req[1], south_port_req[1], north_port_req[1], local_port_req[1]};
assign south_arbiter_req = south_neighbor_full? 5'b0 : {west_port_req[2], east_port_req[2], south_port_req[2], north_port_req[2], local_port_req[2]};
assign east_arbiter_req = east_neighbor_full? 5'b0 : {west_port_req[3], east_port_req[3], south_port_req[3], north_port_req[3], local_port_req[3]};
assign west_arbiter_req = west_neighbor_full? 5'b0 : {west_port_req[4], east_port_req[4], south_port_req[4], north_port_req[4], local_port_req[4]};

assign local_stall = ~local_port_grant;
assign north_stall = ~north_port_grant;
assign south_stall = ~south_port_grant;
assign east_stall = ~east_port_grant;
assign west_stall = ~west_port_grant;

switch_matrix crossbar(.input0(local_flit_out), .input1(north_flit_out), .input2(south_flit_out),
.input3(east_flit_out), .input4(west_flit_out), .output0(local_out),
.output1(north_out), .output2(south_out), .output3(east_out),
.output4(west_out),
.sel0(local_select), .sel1(north_select), .sel2(south_select), .sel3(east_select), .sel4(west_select));


`ifdef DEBUG_ROUTER

integer router_clk_counter = 0;
integer step_counter = 0;
integer neuron_clk_counter = 0;

always @(posedge clk_local)
	begin
		if (start == 1'b1)
			step_counter = step_counter + 1;
		
		neuron_clk_counter = neuron_clk_counter + 1;
	end

always @(posedge clk)
	router_clk_counter = router_clk_counter + 1;

`endif


`ifdef DUMP_STALL_EVENT

reg [100*8:1] dump_file_name1;
integer f1;
wire write_file;
wire local_active, north_active, south_active, east_active, west_active;
wire local_stall_event, north_stall_event, south_stall_event, east_stall_event, west_stall_event;
wire [4:0] local_stalled_request, north_stalled_request, south_stalled_request, east_stalled_request, west_stalled_request;

assign local_active = | local_port_req;
assign north_active = | north_port_req;
assign south_active = | south_port_req;
assign east_active = | east_port_req;
assign west_active = | west_port_req;

assign local_stall_event = local_active & local_stall;
assign north_stall_event = north_active & north_stall;
assign south_stall_event = south_active & south_stall;
assign east_stall_event = east_active & east_stall;
assign west_stall_event = west_active & west_stall;

assign local_stalled_request = (local_stall_event)? local_port_req : 5'b00000;
assign north_stalled_request = (north_stall_event)? north_port_req : 5'b00000;
assign south_stalled_request = (south_stall_event)? south_port_req : 5'b00000;
assign east_stalled_request = (east_stall_event) ? east_port_req : 5'b00000;
assign west_stalled_request = (west_stall_event) ? west_port_req : 5'b00000;

assign write_file = local_stall_event || north_stall_event || south_stall_event || east_stall_event || west_stall_event;

initial
	begin
	  	
		dump_file_name1 = {SIM_PATH, "data", DIR_ID, "/dump_stall_event.csv"};	
		f1 = $fopen(dump_file_name1,"w");
		$fwrite(f1, "router_clk,north, south, east, west, local,\n");
	end

always @(posedge clk)
	begin
		if (write_file == 1'b1)
			$fwrite(f1, "%0d,%0d,%0d,%0d,%0d,%0d,\n", router_clk_counter, north_stalled_request, south_stalled_request, east_stalled_request, west_stalled_request, local_stalled_request);
	
		if(step_counter == STOP_STEP)
			$fclose(f1);
	end

`endif

`ifdef DUMP_DROPPED_PACKET

reg [100*8:1] dump_file_name2;
integer f2;

initial
	begin
		dump_file_name2 = {SIM_PATH, "data", DIR_ID, "/dump_dropped_packet.csv"};	
		f2 = $fopen(dump_file_name2,"w");
		$fwrite(f2, "step,neuron_clk,router_clk,packet,\n");
	end
always @(posedge clk_local)
	begin
		if ((local_full == 1'b1) && (write_en_local == 1'b1))
			begin
				$fwrite(f2, "%0d,%0d,%d,%h,\n",step_counter, neuron_clk_counter, router_clk_counter, local_in);
			end

		if (step_counter == STOP_STEP)
			$fclose(f2);
	end
`endif


`ifdef DUMP_NEURON_OUTPUT_PACKET
integer f3;
reg [100*8:1] dump_file_name3;

initial
    begin
        dump_file_name3 = {SIM_PATH, "data", DIR_ID, "/dump_neuron_output_packet.csv"};
		f3 = $fopen(dump_file_name3,"w");
		$fwrite(f3, "step,neuron_clk,router_clk,packet,\n");
    end

always @(posedge clk_local)
	begin

		if (write_en_local == 1'b1)
			 $fwrite(f3, "%0d,%0d,%0d,%h,\n", step_counter, neuron_clk_counter, router_clk_counter, local_in);

		if (step_counter == STOP_STEP)
			$fclose(f3);

	end

`endif

`ifdef DUMP_CONGESTION
integer f4;
reg [100*8:1] dump_file_name4;
wire write_congestion_file, local_congestion, north_congestion, south_congestion, east_congestion, west_congestion;
wire [4:0] req_to_local, req_to_north, req_to_south, req_to_east, req_to_west;
wire local_congested, north_congested, south_congested, east_congested, west_congested;


assign req_to_local = {west_port_req[0], east_port_req[0], south_port_req[0], north_port_req[0], local_port_req[0]};
assign req_to_north = {west_port_req[1], east_port_req[1], south_port_req[1], north_port_req[1], local_port_req[1]};
assign req_to_south = {west_port_req[2], east_port_req[2], south_port_req[2], north_port_req[2], local_port_req[2]};
assign req_to_east = {west_port_req[3], east_port_req[3], south_port_req[3], north_port_req[3], local_port_req[3]};
assign req_to_west = {west_port_req[4], east_port_req[4], south_port_req[4], north_port_req[4], local_port_req[4]};

assign local_requested = | req_to_local;
assign north_requested = | req_to_north;
assign south_requested = | req_to_south;
assign east_requested = | req_to_east;
assign west_requested = |req_to_west;

assign local_congestion = local_neuron_full & local_requested;
assign north_congestion = north_neighbor_full & north_requested;
assign south_congestion = south_neighbor_full & south_requested;
assign east_congestion = east_neighbor_full & east_requested;
assign west_congestion = west_neighbor_full & west_requested;

assign write_congestion_file = | {local_congestion, north_congestion, south_congestion, east_congestion, west_congestion};

initial
    begin
        dump_file_name4 = {SIM_PATH, "data", DIR_ID, "/dump_congestion.csv"};
		f4 = $fopen(dump_file_name4,"w");
		$fwrite(f4, "step,neuron_clk,router_clk,north,south,east,west,local,\n");
    end

always @(posedge clk)
	begin

		if (write_congestion_file == 1'b1)
			 $fwrite(f4, "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,\n", step_counter, neuron_clk_counter, router_clk_counter, local_congestion, north_congestion, south_congestion, east_congestion, west_congestion );

		if (step_counter == STOP_STEP)
			$fclose(f4);

	end

`endif


endmodule