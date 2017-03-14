`timescale 1ns/100ps
`define DLY 5
module tb_priority_encoder();


	parameter IN_DSIZE  = 12 ;
	parameter OUT_DSIZE = 4  ;

	reg  [IN_DSIZE-1:0]     in_data_i   ;
	wire            valid_bit_o ;
	wire [OUT_DSIZE-1:0]     out_data_o  ;

	integer i, max;
	//integer out_siz,val;


   	PriorityEncoder
  	#(
		.IN_DSIZE  ( IN_DSIZE  ),
		.OUT_DSIZE ( OUT_DSIZE )
	)
	PRIORITY_ENCODER
	(
		.in_data_i   ( in_data_i 	),

		.valid_bit_o ( valid_bit_o 	),
		.out_data_o  ( out_data_o 	)
	);
	  

   initial
   begin
		in_data_i   =  0 ;
		i = 0;
		max = 65536;
		#`DLY;


		// val = 3;	out_siz = $ln(val);
		// #`DLY;
		// val = 8;	out_siz = $ln(val);
		// #`DLY;
		// val = 15;	out_siz = $ln(val);
		// #`DLY;
		// val = 32;	out_siz = $ln(val);
		// #`DLY;

		for (i = 0; i < max; i=i+1) begin
			in_data_i   =   in_data_i + 1;
	  		#`DLY;
		end

	  #(`DLY*5);

	  $stop;
   end



endmodule
