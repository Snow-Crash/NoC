`include "test_reg.v"

module test_reg_tb;

reg clk, shift, sr_in;
wire sr_out;

shift_1x64 dut (.clk(clk), 
		  	.shift(shift),
			.sr_in(sr_in),
			.sr_out(sr_out)
		   );

always 
    begin
    #10 clk = ~clk;

    end

//always
       // #20 sr_in = ~sr_in;

initial
    begin
    clk = 0;
    shift = 0;
    #10 shift = 1;
    sr_in = 1;
    #20 sr_in = 0;
    #20 sr_in = 1;
    #20 sr_in = 0;
    #20 sr_in = 1;
    #20 sr_in = 0;
    #20 sr_in = 1;
    #20 sr_in = 0;
    #20 sr_in = 1;
    #20 sr_in = 0;
    #20 sr_in = 1;

    end

    endmodule