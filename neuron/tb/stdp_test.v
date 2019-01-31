`timescale 1ns/100ps
`define tpd_clk 10
`define DUMP_MEMORY

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
parameter SIM_PATH =  "D:/code/learn_test_work_dir/";
parameter STOP_STEP = 80;

reg clk, rst_n;
wire outSpike;
reg start;

wire [NUM_AXONS - 1:0] spike;

Neuron #(
	`ifdef DUMP_MEMORY
	.STOP_STEP(STOP_STEP),
	`endif
	.NUM_NURNS(NUM_NURNS), 
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


// initial
// 	begin
// 		clk  = 1'b0;
// 		rst_n = 1'b0;
// 		start = 1'b0;	
		
// 		#(`tpd_clk*2);
// 		rst_n = 1'b1;

// 		spike = 4'b1111;
// 		#((`tpd_clk*2)*2);
// 		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
		
// 		#((`tpd_clk*2)*100);//interval between two start signal

// 		spike = 4'b0010;
// 		#((`tpd_clk*2)*2);
// 		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;

// 		#((`tpd_clk*2)*100);

// 		spike = 4'b1100;
//         #((`tpd_clk*2)*2);
// 		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;

// 		#((`tpd_clk*2)*100);

// 		spike = 4'b0100;
//         #((`tpd_clk*2)*2);
// 		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;

// 		#((`tpd_clk*2)*100);

// 		spike = 4'b0101;
//         #((`tpd_clk*2)*2);
// 		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;

// 		#((`tpd_clk*2)*100);


// 		$stop;
// 	end

initial
	begin
		clk  = 1'b0;
		rst_n = 1'b0;
		start = 1'b0;	
		
		#(`tpd_clk*2);
		rst_n = 1'b1;

		#((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1;
		@(posedge clk); start = 1'b0;
	end

always @(posedge clk)
	begin
		#((`tpd_clk*2)*100);
		@(posedge clk); start = 1'b1;
		@(posedge clk); start = 1'b0;
	end


//read testcases
integer f1;
integer nouse1, i;
integer delay = 0;
wire [7:0] step_counter;
wire [NUM_AXONS-1:0] spike_wire;
reg [7 + NUM_AXONS:0] testcases;
reg [NUM_AXONS-1:0] reversed_spike;
assign step_counter = testcases[7 + NUM_AXONS:NUM_AXONS];
assign spike = reversed_spike;
assign spike_wire = testcases[NUM_AXONS-1:0];

always @(*)
	begin
	  for(i = 0; i < NUM_AXONS; i = i+1)
	  	begin
			reversed_spike[NUM_AXONS-1-i] = spike_wire[i]; 
		end
	end


initial
	begin
		f1 = $fopen("D:/code/learn_test_work_dir/InputSpikes_HW_RAND_4.txt","r");
		//f1 = $fopen("D:/code/learn_test_work_dir/InputSpikes_relutest_HW_RAND_4.txt","r");
	end


always @(posedge start)
	begin
		if (delay >= 1)
			nouse1 = $fscanf(f1, "%b\n", testcases);
		else
			testcases = 0;
		delay = delay + 1;
	end


endmodule