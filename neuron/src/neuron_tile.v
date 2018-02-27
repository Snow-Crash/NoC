module neuron_tile
(
    input neuron_clk,
    input neuron_rst,
    input router_clk,
    input router_rst,
    input [37:0] flit_in,
    
);


module Neuron
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
(
    .clk(),
    .rst_n(), 
    .SpikePacket(), 
    .outSpike(), 
    .start(), 
    .inSpike(), 
    .packet_write_req(), 
    .config_data_in(),

    .wr_en_potential_i(),
    .wr_en_threshold_i(),
    .wr_en_bias_i(),
    .wr_en_posthistory_i(),
    .wr_en_prehistory_i(),

        // address to status memory
    .address_bias(),
    .address_potential(),
    .address_threshold(),
    .address_posthistory(),
    .address_preshistory(),
    .address_weight(),

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

module packet_decoder
#(
    .NUM_AXONS = 256,
    .AXON_CNT_BIT_WIDTH = 8,
    .NURN_CNT_BIT_WIDTH = 7,
    .STDP_WIN_BIT_WIDTH = 8,
    .DSIZE = 16,
    .FLIT_WIDTH = 38,
    .VIRTUAL_CHANNEL = 4,
    .PAYLOAD_WIDTH = 32
)
(
    .neuron_clk(), 
    .neuron_rst(), 
    .start(), 
    .activate_decoder(), 
    .stall_decoder(), 
    .flit_in(),
    .spike_out(), 
    .mem_data_out(), 
    .class_type_in(),

    //output to write status memory
    .wr_en_potential_o(),
    .wr_en_threshold_o(),
    .wr_en_bias_o(),
    .wr_en_posthistory_o(),
    .wr_en_prehistory_o(),
    // address to status memory
    .address_bias(),
    .address_potential(),
    .address_threshold(),
    .address_posthistory(),
    .address_preshistory(),
    .address_weight(),

    //output to write config memory
    .wr_en_configA_o(),
    .wr_en_configB_o(),
    .wr_en_AER_o(),
    .wr_en_weight_o(),
    .wr_en_axonmode_o(),
    .wr_en_coreconfig_o(),
    .wr_en_axonmode_1_o(),
    .wr_en_axonmode_2_o(),
    .wr_en_axonmode_3_o(),
    .wr_en_axonmode_4_o(),
    .wr_en_scaling_o(),

    //address to config memory
    .address_config_A(),
    .address_config_B(),
    .address_axonmode(),
    .address_AER(),
    .address_axon_scaling(),

    .config_data_out()
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