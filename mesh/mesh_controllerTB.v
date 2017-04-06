`timescale 1ns/100ps
`define tpd_clk 10

module mesh_conreollerTB();

reg neu_clk, rt_reset,rst_n, rt_clk, write_enable;
reg [3:0] packet_in;
wire [31:0] spike_packet;
wire write_req, start, receive_full;

mesh_controller uut (.neu_clk(neu_clk), .rst_n(rst_n), .rt_clk(rt_clk),
                     .rt_reset(rt_reset), .start(start), .spike_packet(spike_packet), 
                     .packet_in(packet_in), .write_req(write_req), .write_enable(write_enable),
                     .receive_full(receive_full));



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
        write_enable = 1'b1;
            packet_in = 4'h1; #10 packet_in = 4'h2; #10 packet_in = 4'h3; #10 packet_in = 4'h4; 
        #10 packet_in = 4'h5; #10 packet_in = 4'h6; #10 packet_in = 4'h7; #10 packet_in = 4'h8; 
        #10 packet_in = 4'h9; #10 packet_in = 4'ha; #10 packet_in = 4'hb; #10 packet_in = 4'hc; 
        #10 packet_in = 4'hd; #10 packet_in = 4'he; #10 packet_in = 4'hf; #10 packet_in = 4'h0; 
        #10 write_enable = 0; 
    #1000 rt_reset = 1'b0;


    end
endmodule
