`timescale 1ns/100ps
`define tpd_clk 10

module mesh_with_controllerTB();

reg neu_clk, neu_reset, rt_clk, rt_reset;

mesh_with_controller dut (.neu_clk(neu_clk), .neu_reset(neu_reset), .rt_clk(rt_clk), .rt_reset(rt_reset));

always
	begin
		#5 rt_clk <= ~rt_clk  ;
	end

always
	begin
		#(`tpd_clk) neu_clk <= ~neu_clk  ;
	end

initial
    begin
        neu_clk  = 1'b0;
		neu_reset = 1'b0;	
		#(`tpd_clk*2);
		neu_reset = 1'b1;
        #2000 neu_reset = 1'b1;
    end

initial
    begin
        rt_clk = 1'b0;
        rt_reset = 1'b1;
    #6  rt_reset = 1'b0;

    #2000 rt_reset = 1'b0;
    end

endmodule