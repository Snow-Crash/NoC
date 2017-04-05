`timescale 1ns/100ps
`define tpd_clk 10

module mesh_conreollerTB();

reg neu_clk, rt_reset,rst_n, rt_clk;
wire [31:0] spike_packet;
wire write_req, start;

mesh_controller uut (.neu_clk(neu_clk), .rst_n(rst_n), .start(start), .spike_packet(spike_packet), .write_req(write_req));



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
		rst_n = 1'b0;	
		#(`tpd_clk*2);
		rst_n = 1'b1;
        #1000 rst_n = 1'b1;
    end

initial
    begin
        rt_clk = 1'b0;
        rt_reset = 1'b1;
    #6  rt_reset = 1'b0;
    #1000 rt_reset = 1'b0;


    end
endmodule
