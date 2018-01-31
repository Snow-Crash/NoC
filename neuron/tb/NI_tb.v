`timescale 1ns/100ps

module NI_tb();

reg router_clk, router_rst, neuron_clk, neuron_rst, start;
reg flit_in_wr;
reg [37:0] flit_in;
wire [3:0] credit_out;

NI uut 
(
.router_clk(router_clk), 
.router_rst(router_rst), 
.flit_in_wr(flit_in_wr), 
.flit_in(flit_in), 
.credit_in(), 
.flit_out_wr(), 
.flit_out(), 
.credit_out(credit_out),
.neuron_clk(neuron_clk), 
.neuron_rst(), 
.start(), 
.packet_out(), 
.spike_packet_in());

initial
    begin
        router_clk <= 1'b1;
        neuron_clk <= 1'b0;
        router_rst <= 1'b0;
        #10 router_rst <= 1'b1;
        flit_in_wr <= 1'b0;
        #10 router_rst <= 1'b0;
        #10 flit_in <= 16'hAAAA;
        flit_in_wr <= 1'b1;
        router_rst <= 1'b0;
        #10 flit_in <= 16'hBBBB;
        #10 flit_in <= 16'h1111;
        #10 flit_in_wr <= 1'b0;
        #10 flit_in_wr = 1'b1;
        flit_in <= 38'b101111111111111111111111111111111111111;
        #10 flit_in <= 16'h5555;

    end

always
	begin
		#5 router_clk <= ~router_clk ;
        //#5 neuron_clk <= ~neuron_clk;
	end

always
    begin
        #5 neuron_clk <= ~neuron_clk ;
    end


endmodule