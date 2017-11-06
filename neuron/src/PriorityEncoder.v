//------------------------------------------------------------------------
// Title       : priority encoder
// Version     : 0.1
// Author      : Khadeer Ahmed
// Date created: 12/13/2016
// -----------------------------------------------------------------------
// Discription : parameterized priority encoder
// -----------------------------------------------------------------------
// Maintainance History
// -ver x.x : date : auth
//		details
//------------------------------------------------------------------------
`include "neuron_define.v"
// `timescale 1ns/100ps

module PriorityEncoder
#(
	parameter IN_DSIZE  = 16 ,
	parameter OUT_DSIZE = 4
)
(
	input      [IN_DSIZE-1:0]	in_data_i 	,

	output 						valid_bit_o ,
	output reg [OUT_DSIZE-1:0] 	out_data_o
);
	
	integer i;

	//LOGIC
	//--------------------------------------------------//
	assign valid_bit_o = (|in_data_i);
	always @ (*) begin
		out_data_o = 0;
		for (i = 0; i < IN_DSIZE; i=i+1) begin
			if (in_data_i[i] == 1'b1) begin
				out_data_o = i;
			end
		end
	end


endmodule