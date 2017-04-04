//2017.3.23     testbench for a single neuron. It is used to test if the interface can work
//              properly. Interface should decode the packet, and write spike into spike_reg
//              It works.

`timescale 1ns/100ps
`define tpd_clk 10


module single_core_TB();


reg clk, rt_clk, rst_n, rt_reset, start;

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
		write_en_north = 0; write_en_south = 0;  write_en_west = 0;
        north_in = 0; south_in = 0; east_in = 0;
        north_neighbor_full = 0; south_neighbor_full = 0; east_neighbor_full = 0; west_neighbor_full = 0; 
	    write_en_north = 0; write_en_south = 0;
        
		end

initial
    begin
            rt_clk = 1'b0;
			rt_reset = 1'b1;
			east_in = 4'h0;
            write_en_east = 1'b0;
        #6  rt_reset = 0;
            //packet 00000000 axon_id = 0 time step = 3
            #1000 write_en_east = 1;
                east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 write_en_east = 0; 
            //packet 00010000 axon_id = 1 time step = 3
            #80 write_en_east = 1;
                east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 east_in = 4'h1; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 write_en_east = 0; 
            //packet 00000000 axon_id = 0 time step = 4
            #1000 write_en_east = 1;
                east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 write_en_east = 0; 
            //packet 00010000 axon_id = 1 time step = 4
            #80 write_en_east = 1;
                east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 east_in = 4'h1; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 write_en_east = 0; 
            //packet 00000000 axon_id = 0 time step = 5
            #1000 write_en_east = 1;
                east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 write_en_east = 0; 
            //packet 00010000 axon_id = 1 time step = 5
            #80 write_en_east = 1;
                east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 east_in = 4'h1; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 write_en_east = 0; 
            //packet 00000000 axon_id = 0 time step = 6
            #1000 write_en_east = 1;
                east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 write_en_east = 0; 
            //packet 00010000 axon_id = 1 time step = 6
            #80 write_en_east = 1;
                east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 east_in = 4'h1; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 write_en_east = 0; 
            //packet 00000000 axon_id = 0 time step = 7
            #1000 write_en_east = 1;
                east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 write_en_east = 0; 
            //packet 00010000 axon_id = 1 time step = 7
            #80 write_en_east = 1;
                east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 east_in = 4'h1; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 write_en_east = 0; 
            //packet 00000000 axon_id = 0 time step = 8
            #1000 write_en_east = 1;
                east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 write_en_east = 0; 
            //packet 00010000 axon_id = 1 time step = 8
            #80 write_en_east = 1;
                east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 east_in = 4'h1; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 write_en_east = 0; 
            //packet 00000000 axon_id = 0 time step = 9
            #1000 write_en_east = 1;
                east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 write_en_east = 0; 
            //packet 00010000 axon_id = 1 time step = 9
            #80 write_en_east = 1;
                east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 east_in = 4'h1; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 write_en_east = 0; 
            //packet 00000000 axon_id = 0 time step = 10
            #1000 write_en_east = 1;
                east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 write_en_east = 0; 
            //packet 00010000 axon_id = 1 time step = 10
            #80 write_en_east = 1;
                east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 east_in = 4'h1; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 write_en_east = 0; 
            //packet 00000000 axon_id = 0 time step = 11
            #1000 write_en_east = 1;
                east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 write_en_east = 0; 
            //packet 00010000 axon_id = 1 time step = 11
            #80 write_en_east = 1;
                east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 east_in = 4'h1; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 write_en_east = 0; 
            //packet 00000000 axon_id = 0 time step = 12
            #1000 write_en_east = 1;
                east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 write_en_east = 0; 
            //packet 00010000 axon_id = 1 time step = 12
            #80 write_en_east = 1;
                east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 east_in = 4'h1; #10 east_in = 4'h0; #10 east_in = 4'h0; #10 east_in = 4'h0; 
            #10 write_en_east = 0; 
            //packet 00000000 axon_id = 0 time step = 13
            #1000 write_en_east = 1;
            $stop;
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

//#1    
        #1600 rst_n = 1'b1;
		#((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
		#600 rst_n = 1'b1;
		#((`tpd_clk*2)*30);
//#2
		#((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
		#600 rst_n = 1'b1;
		#((`tpd_clk*2)*30);

//#3
		#((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
		#600 rst_n = 1'b1;
		#((`tpd_clk*2)*30);
//#4
        #((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
		#600 rst_n = 1'b1;
		#((`tpd_clk*2)*30);
//#5
        #((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
		#600 rst_n = 1'b1;
		#((`tpd_clk*2)*30);
//#6
        #((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
		#600 rst_n = 1'b1;
		#((`tpd_clk*2)*30);
//#7
        #((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
		#600 rst_n = 1'b1;
		#((`tpd_clk*2)*30);
//#8
        #((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
		#600 rst_n = 1'b1;
		#((`tpd_clk*2)*30);
//#9
        #((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
		#600 rst_n = 1'b1;
		#((`tpd_clk*2)*30);
//#10
        #((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
		#600 rst_n = 1'b1;
		#((`tpd_clk*2)*30);
//#11
        #((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
		#600 rst_n = 1'b1;
		#((`tpd_clk*2)*30);
//#12
        #((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
		#600 rst_n = 1'b1;
		#((`tpd_clk*2)*30);
//#13
        #((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
		#600 rst_n = 1'b1;
		#((`tpd_clk*2)*30);



		$stop;
	end

endmodule