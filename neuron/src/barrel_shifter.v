module barrel_shifter#(parameter DSIZE     = 16,
					   parameter SHIFTSIZE = 4)
(shift_in, rightshift_i, shift_by_i, shift_out_o);
   input    [(DSIZE - 1):0]    shift_in     ;
   input                       rightshift_i ;
   input    [(SHIFTSIZE-1):0]  shift_by_i   ;
   output   [(DSIZE - 1):0]    shift_out_o    ;
   reg      [(DSIZE - 1):0]    shift_out_o    ;

   parameter SHIFTLEFT  = 0 ;
   parameter SHIFTRIGHT = 1 ;
   always @ (*)
   begin
	  case(rightshift_i)
		 SHIFTLEFT   :   begin
							shift_out_o[(DSIZE - 1):0] =  shift_in << shift_by_i ;
						 end
		 SHIFTRIGHT  :   begin
							shift_out_o[(DSIZE - 1):0] =  shift_in >> shift_by_i ;
						 end
		default      :   begin
							shift_out_o[(DSIZE - 1):0] =  shift_in ;
						 end
	  endcase
   end
endmodule
