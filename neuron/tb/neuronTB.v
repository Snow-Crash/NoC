`timescale 1ns/100ps
`define tpd_clk 10


module neuronTB;

reg clk, rst_n;
wire [31:0] SpikePacket;
wire outSpike;
wire [3:0] local_packet_out;
reg start;


 Neuron uut (.clk(clk), .rst_n(rst_n), .SpikePacket(SpikePacket), .outSpike(outSpike),. start(start));




reg rt_clk, rt_reset;
reg clk_local, clk_north, clk_south, clk_east, clk_west;
reg reset_north, reset_south, reset_east, reset_west, reset_local;
reg write_north, write_south, write_east, write_west;
reg [3:0] north_in, south_in, east_in, west_in;
wire [3:0] local_out, north_out, south_out, east_out, west_out;
wire local_full, north_full, south_full, east_full, west_full;
wire write_req_local,write_req_north, write_req_south, write_req_east, write_req_west;



routerv2 router (.clk(rt_clk), .clk_local(clk), .clk_north(clk_north), .clk_south(clk_south), .clk_east(clk_east), .clk_west(clk_west),
.reset(rt_reset), .local_in(SpikePacket), .north_in(north_in), .south_in(south_in), .east_in(east_in), .west_in(west_in),
.local_out(local_packet_out), .north_out(north_out), .south_out(south_out), .east_out(east_out), .west_out(west_out),
.local_full(local_full), .north_full(north_full), .south_full(south_full), .east_full(east_full), .west_full(west_full),
.reset_local(rst_n), .reset_north(reset_north), .reset_south(reset_south), .reset_east(reset_east), .reset_west(reset_west), .write_local(outSpike), .write_north(write_north),
.write_south(write_south), .write_east(write_east), .write_west(write_west), .write_req_local(write_req_local), .write_req_north(write_req_north), .write_req_south(write_req_north),
.write_req_east(write_req_east), .write_req_west(write_req_west));




	always
		begin
			#5 rt_clk <= ~rt_clk  ;
		end

	initial
		begin
			rt_clk = 1'b0;
			rt_reset = 1'b1;
	clk_north = 0; clk_south = 0; clk_east = 0; clk_west = 0;
    reset_local = 1; reset_east = 1; reset_north = 1; reset_south = 1; reset_west = 1;
    write_east = 0; write_west = 0; write_south = 0; write_north = 0;
    north_in = 0; south_in = 0; east_in = 0; west_in = 0; 
	#10 rt_reset = 1'b0;


		end


	//cpu clock
	always
	begin
		#(`tpd_clk) clk <= ~clk  ;
	end

	initial
	begin
		clk  = 1'b0;
		rst_n = 1'b0;
		start = 1'b0;	


		
		#(`tpd_clk*2);
		rst_n = 1'b1;


		#((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
		
		#((`tpd_clk*2)*30);


		#((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;

		#((`tpd_clk*2)*30);

		$stop;
	end

endmodule