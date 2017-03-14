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

`timescale 1ns/100ps

module InSpikeBuf
#(
	parameter NUM_AXONS    = 256 ,
	parameter AXON_CNT_BIT_WIDTH   = 8 
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

	output reg		Rcl_InSpike_o   ,
	output reg		Lrn_InSpike_o
);

	//REGISTER DECLARATION
	//--------------------------------------------------//
	reg RclSpikeBuf [0:NUM_AXONS-1];
	reg LrnSpikeBuf [0:NUM_AXONS-1];

	integer i;
	
	//simulation memory data initialization
	//--------------------------------------------------//
	`ifdef SIM_MEM_INIT
		//reg [100*8:1] file_name;
		integer         file_ptr              ; 

		initial begin
			//file_name = "../data/InSpikeBuf.txt";			$readmemh (file_name,RclSpikeBuf);
			//open file for reading Read 
         	file_ptr = $fopen ("../data/InSpikeBuf.txt", "r");

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
	
	//LOGIC
	//--------------------------------------------------//
	// Read spike reg
	always@(posedge clk_i or negedge rst_n_i)  begin
		if(rst_n_i == 1'b0) begin
			Rcl_InSpike_o	<= 1'b0;
			Lrn_InSpike_o   <= 1'b0;

			for(i = 0 ; i < NUM_AXONS ; i = i + 1)
				RclSpikeBuf[i] <= 0;
			for(i = 0 ; i < NUM_AXONS ; i = i + 1)
				LrnSpikeBuf[i] <= 0;

	  	end else begin
	  		if(rdEn_RclInSpike_i == 1'b1) begin
	  			Rcl_InSpike_o <= RclSpikeBuf[RclAxonAddr_i];
	  		end

	  		if(rdEn_LrnInSpike_i == 1'b1) begin
	  			Lrn_InSpike_o <= LrnSpikeBuf[LrnAxonAddr_i];
	  		end

			if(saveRclSpikes_i == 1'b1) begin
	  			for(i = 0 ; i < NUM_AXONS ; i = i + 1)
					LrnSpikeBuf[i] <= RclSpikeBuf[i];
	  		end	  		
	  	end
	end


endmodule