//2017.3.23     testbench for a single neuron. It is used to test if the interface can work
//              properly. Interface should decode the packet, and write spike into spike_reg
//              It works.
//2017.3.26     Input test package to west port of router, and router forward package to local neuron.
//              Interface decode package and generate spike signal, crresponding bit of spike_reg is set to 1
//              After start signal, spike data is stored in InSpikeBuf
//              Work correctly

`timescale 1ns/100ps
`define tpd_clk 10


module SpikeBuf_and_interfaceTB();


reg clk, rt_clk, rst_n, rt_reset, start, clk_north, clk_south, clk_east, clk_west;

reg [3:0] north_in, south_in, east_in, west_in;

reg north_neighbor_full, south_neighbor_full, east_neighbor_full, west_neighbor_full;

reg write_en_north, write_en_south, write_en_east, write_en_west;

wire [3:0] north_out, south_out, east_out, west_out;
wire north_full, south_full, east_full, west_full;
wire write_req_north, write_req_south, write_req_east, write_req_west;

parameter packet_size = 32;
parameter flit_size = 4;
parameter NUM_NURNS = 2;
parameter NUM_AXONS = 2;
parameter NURN_CNT_BIT_WIDTH = 1;
parameter AXON_CNT_BIT_WIDTH = 1;
parameter X_ID = "1";
parameter Y_ID = "1";

neuron_cell #(.NUM_NURNS(NUM_NURNS), 
            .NUM_AXONS(NUM_AXONS),
            .NURN_CNT_BIT_WIDTH(NURN_CNT_BIT_WIDTH),
            .AXON_CNT_BIT_WIDTH(AXON_CNT_BIT_WIDTH),
            .X_ID(X_ID),
            .Y_ID(Y_ID)) 
            uut(.clk(clk), .rt_clk(rt_clk), .rst_n(rst_n), .rt_reset(rt_reset), .start(start),
            .clk_north(rt_clk), .clk_south(rt_clk), .clk_east(rt_clk), .clk_west(rt_clk),
            .north_in(north_in), .south_in(south_in), .east_in(east_in), .west_in(west_in),
            .north_neighbor_full(north_full), .south_neighbor_full(south_neighbor_full), .east_neighbor_full(east_neighbor_full), .west_neighbor_full(west_neighbor_full),
            .north_out(north_out), .south_out(south_out), .east_out(east_out), .west_out(west_out),
            .north_full(north_full), .south_full(south_full), .east_full(east_full), .west_full(west_full),
            .write_req_north(write_req_north), .write_req_south(write_req_south), .write_req_east(write_req_east), .write_req_west(write_req_west),
            .write_en_north(write_en_north), .write_en_south(write_en_south), .write_en_east(write_en_east), .write_en_west(write_en_west));


always
	begin
		#5 rt_clk <= ~rt_clk  ;
	end


initial
	begin
		rt_clk = 1'b0;
		write_en_north = 0; write_en_south = 0;  write_en_east= 0;
        north_in = 0; south_in = 0; east_in = 0;
        north_neighbor_full = 0; south_neighbor_full = 0; east_neighbor_full = 0; west_neighbor_full = 0; 
	    write_en_north = 0; write_en_south = 0; write_en_east = 0;
        
		end

initial
    begin
            west_in = 0;
            rt_reset = 1;
            write_en_west = 1'b0;
        #6  rt_reset = 0;
            write_en_west = 1;
            west_in = 4'h0;
        #10 west_in = 4'h0;
        #10 west_in = 4'h0;
        #10 west_in = 4'h0;
        #10 west_in = 4'h8;
        #10 west_in = 4'h1;
        #10 west_in = 4'he;
        #10 west_in = 4'hf;
        #10 write_en_west = 0;
        #200 write_en_west = 1;
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

        #300 start = 1'b0;      //after packets are decoded and spike are stored in InSpikeBuf, start compute
		#((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
		
		#((`tpd_clk*2)*30);


		#((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;

		#((`tpd_clk*2)*30);

		$stop;
	end

endmodule