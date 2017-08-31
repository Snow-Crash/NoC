`timescale 1ns/100ps
`define tpd_clk 10

module stdp_test();

parameter packet_size = 32;
parameter flit_size = 4;
parameter NUM_NURNS = 4;
parameter NUM_AXONS = 4;
parameter NURN_CNT_BIT_WIDTH = 2;
parameter AXON_CNT_BIT_WIDTH = 2;
parameter X_ID = "1";
parameter Y_ID = "1";
parameter SYNTH_PATH = "D:/code/synth/data";
parameter SIM_PATH =  "D:/code/learn_test_work_dir/data";

reg clk, rst_n;
wire outSpike;
reg start;

reg [NUM_AXONS - 1:0] spike;

Neuron #(.NUM_NURNS(NUM_NURNS), 
	.NUM_AXONS(NUM_AXONS), 
	.SIM_PATH(SIM_PATH), 
	.NURN_CNT_BIT_WIDTH(NURN_CNT_BIT_WIDTH), 
	.AXON_CNT_BIT_WIDTH(AXON_CNT_BIT_WIDTH)) 
	uut (.clk(clk), .rst_n(rst_n), .SpikePacket(SpikePacket), .outSpike(outSpike),. start(start), .inSpike(spike));


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

		spike = 4'b1111;
		#((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
		
		#((`tpd_clk*2)*100);//interval between two start signal

		spike = 4'b0010;
		#((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;

		#((`tpd_clk*2)*100);

		spike = 4'b1100;
        #((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;

		#((`tpd_clk*2)*100);

		spike = 4'b0100;
        #((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;

		#((`tpd_clk*2)*100);

		spike = 4'b0101;
        #((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;

		#((`tpd_clk*2)*100);


		$stop;
	end


endmodule