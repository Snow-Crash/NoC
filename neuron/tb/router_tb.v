module router_tb();

reg clk, rst, neuron_clk, neuron_rst;

//s w n e l
reg [4:0] credit_in_local, credit_in_east, credit_in_north, credit_in_west, credit_in_south;
reg [37:0] flit_in_local, flit_in_east, flit_in_north, flit_in_west, flit_in_south;
reg we_local, we_east, we_north, we_west, we_south;
reg [2:0] current_x, current_y;

wire [19:0] credit_in, credit_out;
wire [189:0] flit_in, flit_out;
wire [4:0] we_in, we_out;
wire we_out_local, we_out_east, we_out_north, we_out_west, we_out_south;
wire [37:0] flit_out_local, flit_out_east, flit_out_north, flit_out_west, flit_out_south;
wire [37:0] flit_to_decoder;
wire [2:0] class_type;

assign credit_in = {credit_in_south, credit_in_west, credit_in_north, credit_in_east, credit_in_local};
assign flit_in = {flit_in_south, flit_in_west, flit_in_north, flit_in_east, flit_in_local};
assign we_in = {we_south, we_west, we_north, we_east, we_local};

assign we_out_local = we_out[0];
assign we_out_east = we_out[1];
assign we_out_north = we_out[2];
assign we_out_west = we_out[3];
assign we_out_south = we_out[4];
assign flit_out_local = flit_out[37:0];
assign flit_out_west = flit_out[75:38];
assign flit_out_north = flit_out[113:76];
assign flit_out_east = flit_out[151:114];
assign flit_out_south = flit_out[189:152];


initial
    begin
        clk = 1'b0;
        rst = 1'b0;
        credit_in_local = 1'b1;
        credit_in_north = 1'b1;
        credit_in_east = 1'b1;
        credit_in_south = 1'b1;
        credit_in_west = 1'b1;
        we_local = 1'b0;
        we_west = 1'b0;
        we_north = 1'b0;
        we_east = 1'b0;
        we_south = 1'b0;
        flit_in_east = 0;
        flit_in_west = 0;
        flit_in_south = 0;
        flit_in_north = 0;
        flit_in_local = 0;
        current_x = 3'd1;
        current_y = 3'd1;
    end

always
    #5 clk = ~clk;

always
    #5 neuron_clk = ~neuron_clk;

initial
    begin
        clk = 1'b0;
        neuron_clk = 1'b0;
        rst = 1'b0;
        neuron_rst = 1'b0;
        #10 rst= 1'b1;
        we_north = 1'b0;
        neuron_rst = 1'b1;
        #10 rst = 1'b0;
        //test 2 flits, type bias, no stall
        #40 flit_in_north = 38'b10_0001_010_00001_000001_000001_000001_000001;
        we_north = 1'b1;
        #10 flit_in_north = 38'b01_0001_0000_00000010_00_00_0000000110000000;
        // second packet, 2 flits, test state transition, type potential
        #10 flit_in_north =  38'b10_0001_010_00001_000001_000001_000001_000001;
            we_north = 1'b1;
        #10 we_north = 1'b1;
            flit_in_north = 38'b01_0001_0010_00000010_00_00_0000000111100000;
        #10 we_north = 1'b0;
        //test stall
        //send fist flit and then stall, type post history
        flit_in_north = 38'b10_0001_010_00001_000001_000001_000001_000001;
        we_north = 1'b1;
        //stall 1 cycle
        #10 we_north = 1'b0;
        #10 we_north = 1'b1;
            flit_in_north = 38'b01_0001_0011_00000010_00_00_0000011111100000;
        #10 we_north = 1'b0;
        //test packet which has more than two flits
        //config a 
        #10 we_north = 1'b1;
            //header
            flit_in_north = 38'b10_0001_010_00001_000001_000001_000001_000001;
        #10 we_north = 1'b1;
            //          body|vc|cfg a|  n id |para|  | ltp rate|
            flit_in_north = 38'b00_0001_0101_00000010_00_00_0000011111100000;
            //          body|vc|cfg a|  n id |para|  | ltd rate|
        #10 flit_in_north = 38'b00_0001_0101_00000010_01_00_0000011111100000;
            //          body|vc|cfg a|  n id |para|bias| window|
        #10 flit_in_north = 38'b01_0001_0101_00000010_10_01_0000011100000111;
        #10 we_north = 1'b0;
        // test spike packet decode
        #10 flit_in_north =  38'b10_0001_000_00001_000001_000001_000001_000001;
            we_north = 1'b1;
        #10 flit_in_north =  38'b01_0001_0000_0000_00000011_0000011100000111;
        #10 we_north = 1'b0;

        #10 flit_in_north = 16'h5555;

    end



router router_uut
(
    .current_x(current_x),
	.current_y(current_y),
	.flit_in_all(flit_in),
	.flit_in_we_all(we_in),
	.credit_out_all(credit_out),
	.congestion_in_all(),
	
	.flit_out_all(flit_out),
	.flit_out_we_all(we_out),
	.credit_in_all(credit_in),
	.congestion_out_all(),
	
	.clk(clk),
    .reset(rst)
);

network_interface ni_uut
(
    .router_clk(clk), 
    .router_rst(rst), 
    .flit_in_wr(we_out_local), 
    .flit_in(flit_out_local), 
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

endmodule
