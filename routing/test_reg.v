module shift_1x64 (clk, 
		  	shift,
			sr_in,
			sr_out,
		   );
  
	input clk, shift;â?â? 
	input sr_in;
	output sr_out;

	reg [7:0] sr;
    reg sr2;

	always@(posedge clk)
	begin
		if (shift == 1'b1)
		begin
			sr[7:1] <= sr[6:0];
			sr[0] <= sr_in;
		end
	end
	


    always @(posedge clk)
        sr2 <= sr[7];
        
	assign sr_out = sr2;

endmodule
