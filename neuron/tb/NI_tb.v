`timescale 1ns/100ps

module NI_tb();

reg router_clk, router_rst, neuron_clk, neuron_rst, start;
reg flit_in_wr;
reg [37:0] flit_in;
wire [3:0] credit_out;
wire [37:0] flit_to_decoder;
wire activate_decoder, stall_decoder;
wire [2:0] class_type;


network_interface ni_uut
(
    .router_clk(router_clk), 
    .router_rst(router_rst), 
    .flit_in_wr(flit_in_wr), 
    .flit_in(flit_in), 
    .credit_in(), 
    .flit_out_wr(), 
    .flit_out(), 
    .credit_out(),
    .neuron_clk(neuron_clk), 
    .neuron_rst(neuron_rst), 
    .start(start), 
    .flit_to_decoder(flit_to_decoder), 
    .spike_packet_in(), 
    .activate_decoder(activate_decoder), 
    .stall_decoder(stall_decoder), 
    .class_type_out(class_type)
);

packet_decoder decoder_uut
(
    .neuron_clk(neuron_clk), 
    .neuron_rst(neuron_rst), 
    .start(start), 
    .activate_decoder(activate_decoder), 
    .stall_decoder(stall_decoder), 
    .flit_in(flit_to_decoder), 
    .spike_out(), 
    .mem_data_out(), 
    .class_type_in(class_type)
);

initial
    begin
        router_clk = 1'b1;
        neuron_clk = 1'b0;
        router_rst = 1'b0;
        neuron_rst = 1'b0;
        #10 router_rst= 1'b1;
        flit_in_wr = 1'b0;
        neuron_rst = 1'b1;
        #10 router_rst = 1'b0;
        //test 2 flits, type bias, no stall
        #40 flit_in = 38'b10_0001_010_00001_000001_000001_000001_000001;
        flit_in_wr = 1'b1;
        #10 flit_in = 38'b01_0001_0000_00000010_00_00_0000000110000000;
        // second packet, 2 flits, test state transition, type potential
        #10 flit_in =  38'b10_0001_010_00001_000001_000001_000001_000001;
            flit_in_wr = 1'b1;
        #10 flit_in_wr = 1'b1;
            flit_in = 38'b01_0001_0010_00000010_00_00_0000000111100000;
        #10 flit_in_wr = 1'b0;
        //test stall
        //send fist flit and then stall, type post history
        flit_in = 38'b10_0001_010_00001_000001_000001_000001_000001;
        flit_in_wr = 1'b1;
        //stall 1 cycle
        #10 flit_in_wr = 1'b0;
        #10 flit_in_wr = 1'b1;
            flit_in = 38'b01_0001_0011_00000010_00_00_0000011111100000;
        #10 flit_in_wr = 1'b0;
        //test packet which has more than two flits
        //config a 
        #10 flit_in_wr = 1'b1;
            //header
            flit_in = 38'b10_0001_010_00001_000001_000001_000001_000001;
        #10 flit_in_wr = 1'b1;
            //          body|vc|cfg a|  n id |para|  | ltp rate|
            flit_in = 38'b00_0001_0101_00000010_00_00_0000011111100000;
            //          body|vc|cfg a|  n id |para|  | ltd rate|
        #10 flit_in = 38'b00_0001_0101_00000010_01_00_0000011111100000;
            //          body|vc|cfg a|  n id |para|bias| window|
        #10 flit_in = 38'b01_0001_0101_00000010_10_01_0000011100000111;
        #10 flit_in_wr = 1'b0;
        // test spike packet decode
        #10 flit_in =  38'b10_0001_000_00001_000001_000001_000001_000001;
            flit_in_wr = 1'b1;
        #10 flit_in =  38'b01_0001_0000_0000_00000011_0000011100000111;
        #10 flit_in_wr = 1'b0;

        #10 flit_in = 16'h5555;

    end

always
	begin
		#5 router_clk = ~router_clk ;
        //#5 neuron_clk <= ~neuron_clk;
	end

always
    begin
        #5 neuron_clk = ~neuron_clk ;
    end


endmodule