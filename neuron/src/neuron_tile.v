module neuron_tile
#(
    parameter VIRTUAL_CHANNEL = 4,
    parameter ADDRESS_WIDTH = 5,
    parameter PAYLOAD_WIDTH = 32,
    parameter FLIT_WIDTH = 38,

    parameter NUM_NURNS = 128,

    parameter NURN_CNT_BIT_WIDTH   = 1,
	parameter AXON_CNT_BIT_WIDTH   = 1,

    parameter NUM_NURNS    = 2,
	parameter NUM_AXONS    = 2,

)
(
    input neuron_clk,
    input neuron_rst,
    input router_clk,
    input router_rst,
    input start, 
    input flit_in_wr, 
    input [FLIT_WIDTH-1:0] flit_in, 
    input [VIRTUAL_CHANNEL-1:0] credit_in, 
    input flit_out_wr, 
    input [2+VIRTUAL_CHANNEL+PAYLOAD_WIDTH-1:0] flit_out, 
    input [VIRTUAL_CHANNEL-1:0] credit_out,
);


wire [63:0] config_data;
wire [37:0] flit_to_decoder;

wire [(1<<AXON_CNT_BIT_WIDTH) -1:0] spike_array;

wire [NURN_CNT_BIT_WIDTH-1:0] address_bias;
wire [NURN_CNT_BIT_WIDTH-1:0] address_potential;
wire [NURN_CNT_BIT_WIDTH-1:0] address_threshold;
wire [NURN_CNT_BIT_WIDTH-1:0] address_posthistory;
wire [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] address_preshistory;
wire [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] address_weight;

wire [NURN_CNT_BIT_WIDTH-1:0] address_config_A;
wire [NURN_CNT_BIT_WIDTH-1:0] address_config_B;
wire [NURN_CNT_BIT_WIDTH-1:0] address_axonmode;
wire [NURN_CNT_BIT_WIDTH-1:0] address_AER;
wire [AXON_CNT_BIT_WIDTH-1:0] address_axon_scaling;


Neuron
#(
    .NUM_NURNS(4),
    .NUM_AXONS(4),

    .NURN_CNT_BIT_WIDTH(2),
    .AXON_CNT_BIT_WIDTH(2),

    .DSIZE = DATA_BIT_WIDTH_INT+DATA_BIT_WIDTH_FRAC(),

    .X_ID("1"),
    .Y_ID("1"),
        
    .STOP_STEP(5),

    .SYNTH_PATH("D:/code/synth/data"),
    .SIM_PATH("D:/code/data"),
)
neuron_dut
(
    .clk(neuron_clk),
    .rst_n(neuron_rst), 
    .SpikePacket(), 
    .outSpike(outSpike), 
    .start(start), 
    .inSpike(spike_array), 
    .packet_write_req(packet_write_req), 
    .config_data_in(config_data),

    .wr_en_potential_i(wr_en_potential),
    .wr_en_threshold_i(wr_en_threshold),
    .wr_en_bias_i(wr_en_bias),
    .wr_en_posthistory_i(wr_en_posthistory),
    .wr_en_prehistory_i(wr_en_prehistory),

    // address to status memory
    .address_bias(address_bias),
    .address_potential(address_potential),
    .address_threshold(address_threshold),
    .address_posthistory(address_posthistory),
    .address_preshistory(address_preshistory),
    .address_weight(address_weight),

    //output to write config memory
    .wr_en_configA_i(wr_en_configA),
    .wr_en_configB_i(wr_en_configB),
    .wr_en_AER_i(wr_en_AER),
    .wr_en_weight_i(wr_en_weight),
    .wr_en_axonmode_i(wr_en_axonmode),
    .wr_en_coreconfig_i(wr_en_coreconfig),
    .wr_en_axonmode_1_i(wr_en_axonmode_1),
    .wr_en_axonmode_2_i(wr_en_axonmode_2),
    .wr_en_axonmode_3_i(wr_en_axonmode_3),
    .wr_en_axonmode_4_i(wr_en_axonmode_4),
    .wr_en_scaling_i(wr_en_scaling),

    //address to config memory
    .address_config_A(address_config_A),
    .address_config_B(address_config_B),
    .address_axonmode(address_axonmode),
    .address_AER(address_AER),
    .address_axon_scaling(address_axon_scaling),

    .config_data_in(config_data)

);




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