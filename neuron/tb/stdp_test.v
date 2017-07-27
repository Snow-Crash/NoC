`timescale 1ns/100ps
`define tpd_clk 10

module stdp_test();

parameter packet_size = 32;
parameter flit_size = 4;
parameter NUM_NURNS = 2;
parameter NUM_AXONS = 2;
parameter NURN_CNT_BIT_WIDTH = 1;
parameter AXON_CNT_BIT_WIDTH = 1;
parameter X_ID = "1";
parameter Y_ID = "1";
parameter SYNTH_PATH = "D:/code/synth/data";
parameter SIM_PATH =  "D:/code/data";

reg clk, rst_n;
wire [31:0] SpikePacket;
wire outSpike;
wire [3:0] local_packet_out;
reg start;

wire [NUM_AXONS - 1:0] spike;

Neuron uut (.clk(clk), .rst_n(rst_n), .SpikePacket(SpikePacket), .outSpike(outSpike),. start(start), .inSpike(spike));


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
		
		#((`tpd_clk*2)*30);//interval between two start signal


		#((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;

		#((`tpd_clk*2)*30);

        #((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;

		#((`tpd_clk*2)*30);


        #((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;

		#((`tpd_clk*2)*30);

        #((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;

		#((`tpd_clk*2)*30);


		$stop;
	end


endmodule