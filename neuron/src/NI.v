
module NI(router_clk, router_rst, current_x, current_y, flit_in_wr, flit_in, credit_in, flit_out_wr, flit_out, credit_out,
        neuron_clk, neuron_rst, start, spike_out, spike_packet_in);


parameter 

input router_clk, router_reset;
input  current_x, current_y;