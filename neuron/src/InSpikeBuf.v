//------------------------------------------------------------------------
// Title       : Input spike buffer
// Version     : 0.1
// Author      : Khadeer Ahmed
// Date created: 12/13/2016
// -----------------------------------------------------------------------
// Discription : buffer to manage input spike for crossbar
// -----------------------------------------------------------------------
// Maintainance History
// -ver x.x : date : auth
//		details
//------------------------------------------------------------------------
//2017.4.1  fix multiple drive issue of RclSpikeBuf
//2017.4.4  find reason which causes wrong spikes. RclSpikeBuf and LrnSpikeBuf
//			cant write multiple blocks in one clock, that causes RclSpikeBuf can't 
//			get right spike data when start = 1;
//			change RclSpikeBuf and LrnSpikeBuf type from memory to register.
//			doesn't afftect timing, tested and get right result

`include "neuron_define.v"
// `timescale 1ns/100ps

//`define SIM_MEM_INIT
// `define READ_SPIKE_BUF

module InSpikeBuf
#(
	parameter NUM_AXONS    = 256 ,
	parameter AXON_CNT_BIT_WIDTH   = 8 ,
	parameter X_ID = "1",
	parameter Y_ID = "1",
	parameter DIR_ID = {X_ID, "_", Y_ID}
)
(
	input 			clk_i			,
	input 			rst_n_i			,
	
	input 			start_i			,

	input [AXON_CNT_BIT_WIDTH-1:0] RclAxonAddr_i,
	input 			rdEn_RclInSpike_i,

	input 			saveRclSpikes_i ,
	input [AXON_CNT_BIT_WIDTH-1:0] LrnAxonAddr_i,
	input 			rdEn_LrnInSpike_i,
	input [(1<<AXON_CNT_BIT_WIDTH) -1 : 0]		spike_in,

	output reg		Rcl_InSpike_o   ,
	output reg		Lrn_InSpike_o /* synthesis noprune */
);

	//REGISTER DECLARATION
	//--------------------------------------------------//
	reg  [0:(1<<AXON_CNT_BIT_WIDTH) -1] RclSpikeBuf;
	reg  [0:(1<<AXON_CNT_BIT_WIDTH) -1] LrnSpikeBuf;

	integer i;
// synthesis translate_off
	//simulation memory data initialization
	//--------------------------------------------------//
	`ifdef SIM_MEM_INIT
		//reg [100*8:1] file_name;
		integer         file_ptr              ; 

		initial begin
			//file_name = "../data/InSpikeBuf.txt";			$readmemh (file_name,RclSpikeBuf);
			//open file for reading Read 
         	file_ptr = $fopen ({"../data", DIR_ID, "/InSpikeBuf.txt"}, "r");

		end

		always @ (posedge start_i) begin
			if (start_i == 1'b1)
				ReadInSpikes();
		end

		task ReadInSpikes;
			integer idx;
			reg spike_data;
			begin
				//$display("\n ======= IN task ======= \n");
				for(idx = 0 ; idx < NUM_AXONS ; idx = idx + 1)
		        begin
		        	$fscanf (file_ptr, "%x\n", spike_data);
		        	RclSpikeBuf[idx] = spike_data;
		        	//$display("   RclSpikeBuf[%d] =  %x\n",idx,RclSpikeBuf[idx]);
		        end
			end
		endtask
	`endif
// synthesis translate_on
//read spike from interface
//always @ (posedge start_i) 
//	begin
//		if(start_i == 1'b1)
//			for(i = 0; i < NUM_AXONS; i = 1 + 1)
//				RclSpikeBuf[i] <= spike_in[i];
//	end
	
	//LOGIC
	//--------------------------------------------------//
	// Read spike reg
	
	always @(posedge clk_i or negedge rst_n_i)
		begin
			if (rst_n_i == 1'b0)
				begin
						RclSpikeBuf <= 0;
				end
			else if (start_i == 1'b1)
		  		begin
						RclSpikeBuf <= spike_in;
				end
		end


	always@(posedge clk_i or negedge rst_n_i)  begin
		if(rst_n_i == 1'b0) begin
			Rcl_InSpike_o	<= 1'b0;
			Lrn_InSpike_o   <= 1'b0;

				LrnSpikeBuf <= 0;
	  	end 
		  
		  else begin
	  		if(rdEn_RclInSpike_i == 1'b1) begin
	  			Rcl_InSpike_o <= RclSpikeBuf[RclAxonAddr_i];
	  		end

	  		if(rdEn_LrnInSpike_i == 1'b1) begin
	  			Lrn_InSpike_o <= LrnSpikeBuf[LrnAxonAddr_i];
	  		end

			if(saveRclSpikes_i == 1'b1) begin
					LrnSpikeBuf <= RclSpikeBuf;
	  		end	  		
	  	end
	end


endmodule