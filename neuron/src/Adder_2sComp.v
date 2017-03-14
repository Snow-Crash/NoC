//------------------------------------------------------------------------
// Title       : Adder
// Version     : 0.1
// Author      : Khadeer Ahmed
// Date created: 12/13/2015
// -----------------------------------------------------------------------
// Discription : behavioural adder implementation
// -----------------------------------------------------------------------
// Maintainance History
// -ver x.x : date : auth
//		details
//------------------------------------------------------------------------

`timescale 1ns/100ps

module Adder_2sComp
#(
	parameter DSIZE    = 16
)
(
	input  [DSIZE-1:0]	A_din_i		,
	input  [DSIZE-1:0]	B_din_i		,
	input  				twos_cmplmnt_i,
	
	output reg [DSIZE-1:0]	clipped_sum_o,
	output [DSIZE-1:0]	sum_o		,
	output				carry_o 	,
	output				overflow_o 	,
	output				underflow_o
);

	wire [DSIZE-2:0] 	overflow_mag, underflow_mag;
	


	assign {carry_o,sum_o} = A_din_i + B_din_i;

	assign overflow_o = (twos_cmplmnt_i   == 1'b1) ? 
							(((A_din_i[DSIZE-1] == 1'b0) &&
						 	 (B_din_i[DSIZE-1] == 1'b0) &&
						 	 (sum_o[DSIZE-1]   == 1'b1)) ? 1'b1 : 1'b0)
						 	: carry_o;

	assign underflow_o = ((A_din_i[DSIZE-1] == 1'b1) &&
						  (B_din_i[DSIZE-1] == 1'b1) &&
						  (sum_o[DSIZE-1]   == 1'b0) &&
						  (twos_cmplmnt_i   == 1'b1)) ? 1'b1 : 1'b0;

	//clipping of overflow and underflow
	assign overflow_mag = -1;//this will result in ...1111
	assign underflow_mag = 0;//this will result in ...0000
	always @(*)	begin
		clipped_sum_o = sum_o;
		if ((overflow_o == 1'b1) && (twos_cmplmnt_i   == 1'b1)) begin
			clipped_sum_o = {1'b0,overflow_mag};
		end

		if ((overflow_o == 1'b1) && (twos_cmplmnt_i   == 1'b0)) begin
			clipped_sum_o = {1'b1,overflow_mag};
		end

		if (underflow_o == 1'b1) begin
			clipped_sum_o = {1'b1,underflow_mag};
		end
	end

endmodule