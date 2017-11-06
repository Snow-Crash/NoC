//------------------------------------------------------------------------
// Title       : Linear feedback shift register
// Version     : 0.1
// Author      : Khadeer Ahmed
// Date created: 1/5/2017
// -----------------------------------------------------------------------
// Discription : generates pseudo random numbers for given bus width.
//               The seed should not be all 1s
// 				 NOTE: this module can be parameterized from 4 to 32 bit 
// 				      bus width. for larger sizes refer to
//                    http://www.xilinx.com/support/documentation/application_notes/xapp052.pdf
// 					  for complete list of equations
// -----------------------------------------------------------------------
// Maintainance History
// -ver x.x : date : author
//    details
//------------------------------------------------------------------------
`include "neuron_define.v"

module Lfsr 
#(
	parameter DSIZE = 16 ,
	parameter SEED  = 2
) 
(
	input           		clk_i 		, 
	input           		reset_n_i	, 
	input           		rd_rand_i	, 

	output [DSIZE-1:0]  lfsr_dat_o
);
 
	reg [DSIZE:1]     random/* synthesis noprune */;
	reg            			feedback;


	always @ (*) begin
		if (DSIZE == 3)
			feedback = ~^{random[3],random[2]};
		if (DSIZE == 4)
			feedback = ~^{random[4],random[3]};
		if (DSIZE == 5)
			feedback = ~^{random[5],random[3]};
		if (DSIZE == 6)
			feedback = ~^{random[6],random[5]};
		if (DSIZE == 7)
			feedback = ~^{random[7],random[6]};
		if (DSIZE == 8)
			feedback = ~^{random[8],random[6],random[5],random[4]};
		if (DSIZE == 9)
			feedback = ~^{random[9],random[5]};
		if (DSIZE == 10)
			feedback = ~^{random[10],random[7]};
		if (DSIZE == 11)
			feedback = ~^{random[11],random[9]};
		if (DSIZE == 12)
			feedback = ~^{random[12],random[6],random[4],random[1]};
		if (DSIZE == 13)
			feedback = ~^{random[13],random[4],random[3],random[1]};
		if (DSIZE == 14)
			feedback = ~^{random[14],random[5],random[3],random[1]};
		if (DSIZE == 15)
			feedback = ~^{random[15],random[14]};
		if (DSIZE == 16)
			feedback = ~^{random[16],random[15],random[13],random[4]};
		if (DSIZE == 17)
			feedback = ~^{random[17],random[14]};
		if (DSIZE == 18)
			feedback = ~^{random[18],random[11]};
		if (DSIZE == 19)
			feedback = ~^{random[19],random[6],random[2],random[1]};
		if (DSIZE == 20)
			feedback = ~^{random[20],random[17]};
		if (DSIZE == 21)
			feedback = ~^{random[21],random[19]};
		if (DSIZE == 22)
			feedback = ~^{random[22],random[21]};
		if (DSIZE == 23)
			feedback = ~^{random[23],random[18]};
		if (DSIZE == 24)
			feedback = ~^{random[24],random[23],random[22],random[17]};
		if (DSIZE == 25)
			feedback = ~^{random[25],random[22]};
		if (DSIZE == 26)
			feedback = ~^{random[26],random[6],random[2],random[1]};
		if (DSIZE == 27)
			feedback = ~^{random[27],random[5],random[2],random[1]};
		if (DSIZE == 28)
			feedback = ~^{random[28],random[25]};
		if (DSIZE == 29)
			feedback = ~^{random[29],random[27]};
		if (DSIZE == 30)
			feedback = ~^{random[30],random[6],random[4],random[1]};
		if (DSIZE == 31)
			feedback = ~^{random[31],random[28]};
		if (DSIZE == 32)
			feedback = ~^{random[32],random[22],random[2],random[1]};
	end

  

	always @ (posedge clk_i or negedge reset_n_i) begin
		if (reset_n_i == 0) begin
			random  <= SEED; //An xnor LFSR cannot have an all 1 state
		end	else if (rd_rand_i == 1'b1)	begin
			random  <= {random[DSIZE-1:1], feedback}; //shift left the xnor'd value every posedge clk_i
		end
	end

	assign lfsr_dat_o = random[DSIZE:1];
  
endmodule
