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


module router (clk, clk_local, clk_north, clk_south, clk_east, clk_west,
reset, local_in, north_in, south_in, east_in, west_in, 
local_out, north_out, south_out, east_out, west_out,
local_full, north_full, south_full, east_full, west_full,
local_neuron_full, north_neighbor_full, south_neighbor_full, east_neighbor_full, west_neighbor_full,
write_en_local, write_en_north, write_en_south, write_en_east, write_en_west, 
write_req_local,write_req_north, write_req_south, write_req_east, write_req_west);

parameter packet_size = 32;
parameter flit_size = 4;

input clk, clk_north, clk_south, clk_east, clk_west, clk_local;
input reset;
input write_en_local, write_en_north, write_en_south, write_en_east, write_en_west;
input local_neuron_full, north_neighbor_full, south_neighbor_full, east_neighbor_full, west_neighbor_full;

input [3:0] north_in, south_in, east_in, west_in;
input [31:0] local_in;

output [3:0] local_out, north_out, south_out, east_out, west_out;

output local_full, north_full, south_full, east_full, west_full;

output write_req_local, write_req_north, write_req_south, write_req_east, write_req_west;

//wire send_flit_local, send_flit_north, send_flit_south, send_flit_east, send_flit_west;

wire local_buf_empty, north_buf_empty, south_buf_empty, east_buf_empty, west_buf_empty;
wire local_read_buf, north_read_buf, south_read_buf, east_read_buf, west_read_buf;
wire local_stall, north_stall, south_stall, east_stall, west_stall;
wire [3:0] local_flit_in, north_flit_in, south_flit_in, east_flit_in, west_flit_in;
wire [3:0] local_flit_out, north_flit_out, south_flit_out, east_flit_out, west_flit_out;
wire local_address_ready, north_address_ready, south_address_ready, east_address_ready, west_address_ready;
wire [2:0] local_destination, north_destination, south_destination, east_destination, west_destination;

wire [4:0] local_port_req, north_port_req, south_port_req, east_port_req, west_port_req;




port local_port(.clk(clk), .reset(reset), .fifo_empty(local_buf_empty),
 .stall(local_stall), .flit_in(local_flit_in), .destination_port(local_destination),  
.current_address_ready(local_address_ready), .read_fifo(local_read_buf), .flit_out(local_flit_out),
.request_vector(local_port_req));

port north_port (.clk(clk), .reset(reset), .fifo_empty(north_buf_empty),
 .stall(north_stall), .flit_in(north_flit_in), .destination_port(north_destination),  
.current_address_ready(north_address_ready), .read_fifo(north_read_buf), .flit_out(north_flit_out),
.request_vector(north_port_req));

port south_port (.clk(clk), .reset(reset), .fifo_empty(south_buf_empty),
 .stall(south_stall), .flit_in(south_flit_in), .destination_port(south_destination),  
.current_address_ready(south_address_ready), .read_fifo(south_read_buf), .flit_out(south_flit_out),
.request_vector(south_port_req));

port east_port (.clk(clk), .reset(reset), .fifo_empty(east_buf_empty),
 .stall(east_stall), .flit_in(east_flit_in), .destination_port(east_destination),  
.current_address_ready(east_address_ready), .read_fifo(east_read_buf), .flit_out(east_flit_out),
.request_vector(east_port_req));

port west_port (.clk(clk), .reset(reset), .fifo_empty(west_buf_empty),
 .stall(west_stall), .flit_in(west_flit_in), .destination_port(west_destination),  
.current_address_ready(west_address_ready), .read_fifo(west_read_buf), .flit_out(west_flit_out),
.request_vector(west_port_req));

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

round_robin_arbiter arbiter_local(.clk(clk), .reset(reset), .request(local_arbiter_req), .grant_vec(local_arbiter_grant), .crossbar_control(local_select), .write_request(write_req_local));

round_robin_arbiter arbiter_north(.clk(clk), .reset(reset), .request(north_arbiter_req), .grant_vec(north_arbiter_grant), .crossbar_control(north_select), .write_request(write_req_north));

round_robin_arbiter arbiter_south(.clk(clk), .reset(reset), .request(south_arbiter_req), .grant_vec(south_arbiter_grant), .crossbar_control(south_select), .write_request(write_req_south));

round_robin_arbiter arbiter_east(.clk(clk), .reset(reset), .request(east_arbiter_req), .grant_vec(east_arbiter_grant), .crossbar_control(east_select), .write_request(write_req_east));

round_robin_arbiter arbiter_west(.clk(clk), .reset(reset), .request(west_arbiter_req), .grant_vec(west_arbiter_grant), .crossbar_control(west_select), .write_request(write_req_west));


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

endmodule