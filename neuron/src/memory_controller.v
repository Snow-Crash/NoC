module memory_controller
#(

    parameter NURN_CNT_BIT_WIDTH   = 8 ,
	parameter AXON_CNT_BIT_WIDTH   = 8 ,
    parameter DSIZE = 16,
    parameter PARAMETER_SELECT_BIT = 4, 
    parameter PACKET_SIZE = PARAMETER_SELECT_BIT + NURN_CNT_BIT_WIDTH + DSIZE + DSIZE ,
    parameter CONFIG_PARAMETER_NUMBER = 9,
    parameter STATUS_PARAMETER_NUMBER = 6,
    parameter STDP_WIN_BIT_WIDTH = 8
)
(   
    input clk_i,
    input reset_n_i,
    //global config mode signal
    input en_config,

    //input from packet decoder
    input [PACKET_SIZE-1:0] data_in, 
    input NI_empty, 
    //read request NI fifo
    output reg read_NI, 

    //config memory
    //read address (from neuron controller)
    input [NURN_CNT_BIT_WIDTH-1:0]                          rd_addr_config_A_nc_i,
    input [NURN_CNT_BIT_WIDTH-1:0]                          rd_addr_config_B_nc_i,
    input [NURN_CNT_BIT_WIDTH*AXON_CNT_BIT_WIDTH-1:0]       rd_addr_config_C_nc_i,
    input [NURN_CNT_BIT_WIDTH:0]                            rd_addr_config_AER_nc_i,
    input [AXON_CNT_BIT_WIDTH-1:0]                          rd_addr_axon_scaling_nc_i,
    
    //config memory write address (from decoder)
    input [NURN_CNT_BIT_WIDTH-1:0]                         wr_addr_config_A_dc_i,
    input [NURN_CNT_BIT_WIDTH-1:0]                         wr_addr_config_B_dc_i,
    input [NURN_CNT_BIT_WIDTH*AXON_CNT_BIT_WIDTH-1:0]      wr_addr_config_C_dc_i,
    input [NURN_CNT_BIT_WIDTH:0]                           wr_addr_config_AER_dc_i,
    input [AXON_CNT_BIT_WIDTH-1:0]                         wr_addr_axon_scaling_dc_i,

    // read address from memory reader
    // input [NURN_CNT_BIT_WIDTH-1:0]                          rd_addr_config_A_mr_i,
    // input [NURN_CNT_BIT_WIDTH-1:0]                          rd_addr_config_B_mr_i,
    // input [NURN_CNT_BIT_WIDTH*AXON_CNT_BIT_WIDTH-1:0]       rd_addr_config_C_mr_i,
    // input [NURN_CNT_BIT_WIDTH:0]                            rd_addr_config_AER_mr_i,
    // input [AXON_CNT_BIT_WIDTH-1:0]                          rd_addr_axon_scaling_mr_i,

    //config memory address to config memory (used for both read and write)
    output [NURN_CNT_BIT_WIDTH-1:0]                         addr_config_A_o,
    output [NURN_CNT_BIT_WIDTH-1:0]                         addr_config_B_o,
    output [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0]      addr_config_C_o,
    output [NURN_CNT_BIT_WIDTH:0]                           addr_AER_o,
    output [AXON_CNT_BIT_WIDTH-1:0]                         addr_axon_scaling_o,

    //write enable signal used in config mode
    // output wr_config_A_o,
    // output wr_config_B_o,
    // output wr_config_C1_o,
    // output wr_config_C2_o,
    // output wr_config_C3_o,
    // output wr_config_C4_o,
    // output wr_config_AER_o,
    // output wr_axon_scaling_o,

    // input wr_config_A_init_i,
    // input wr_config_B_init_i,
    // input wr_config_C1_init_i,
    // input wr_config_C2_init_i,
    // input wr_config_C3_init_i,
    // input wr_config_C4_init_i,
    // input wr_config_AER_init_i,
    // input wr_axon_scaling_init_o,

    // read enable (from controller)
    // input read_en_bias_controller_i,
    // input read_en_potential_controller_i,
    // input read_en_threshold_controller_i,
    // input read_en_posthistory_controller_i,
    // input read_en_E_controller_i,
    // input read_en_F_controller_i,

    // //status memory read address (from controller)
	// input [NURN_CNT_BIT_WIDTH-1:0]						read_addr_bias_controller_i,
	// input [NURN_CNT_BIT_WIDTH-1:0]						read_addr_potential_controller_i,
	// input [NURN_CNT_BIT_WIDTH-1:0]						read_addr_threshold_controller_i,
	// input [NURN_CNT_BIT_WIDTH-1:0]						read_addr_posthistory_controller_i,
	// input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	read_addr_prehistory_controller_i,

    // input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	read_addr_E_controller_i,
    // input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	read_addr_F_controller_i,

    // //status memory read address (to status memory)
	// input [NURN_CNT_BIT_WIDTH-1:0]						read_addr_bias_o,
	// input [NURN_CNT_BIT_WIDTH-1:0]						read_addr_potential_o,
	// input [NURN_CNT_BIT_WIDTH-1:0]						read_addr_threshold_o,
	// input [NURN_CNT_BIT_WIDTH-1:0]						read_addr_posthistory_o,
	// input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	read_addr_prehistory_o,

    // input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	read_addr_E_o,
    // input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	read_addr_F_o,

    //status memory write enable signal (from controller)
    input wr_Bias_nc_i,
    input wr_Potential_nc_i,
    input wr_Threshold_nc_i,
    input wr_Posthistory_nc_i,
    input wr_Prehistory_nc_i,
    input wr_Weight_nc_i,

    // status memory write enable signal (from decoder)
    input wr_Bias_dc_i,
    input wr_Potential_dc_i,
    input wr_Threshold_dc_i,
    input wr_Posthistory_dc_i,
    input wr_Prehistory_dc_i,
    input wr_Weight_dc_i,
    
    //status memory write enable (to status memory)
    output wr_Bias_o,
    output wr_Potential_o,
    output wr_Threshold_o,
    output wr_Posthistory_o,
    output wr_Prehistory_o,
    output wr_Weight_o,

    //status memory read enable signal (from controller)
    input rd_prehistory_nc_i,
    input rd_weight_nc_i,

    input rd_prehistory_mr_i,
    input rd_weight_mr_i,

    //status memory write address (from controller)
	input [NURN_CNT_BIT_WIDTH-1:0]						wr_addr_bias_nc_i,
	input [NURN_CNT_BIT_WIDTH-1:0]						wr_addr_potential_nc_i,
	input [NURN_CNT_BIT_WIDTH-1:0]						wr_addr_threshold_nc_i,
	input [NURN_CNT_BIT_WIDTH-1:0]						wr_addr_posthistory_nc_i,
    input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0]	wr_addr_prehistory_nc_i,
    input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	wr_addr_G_nc_i,//weight

    //status memory write address (from decoder)
	input [NURN_CNT_BIT_WIDTH-1:0]						wr_addr_bias_dc_i,
	input [NURN_CNT_BIT_WIDTH-1:0]						wr_addr_potential_dc_i,
	input [NURN_CNT_BIT_WIDTH-1:0]						wr_addr_threshold_dc_i,
	input [NURN_CNT_BIT_WIDTH-1:0]						wr_addr_posthistory_dc_i,
    input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0]	wr_addr_prehistory_dc_i,
    input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	wr_addr_G_dc_i,//weight

    //status memory write address (to status memory)
	input [NURN_CNT_BIT_WIDTH-1:0]						wr_addr_bias_o,
	input [NURN_CNT_BIT_WIDTH-1:0]						wr_addr_potential_o,
	input [NURN_CNT_BIT_WIDTH-1:0]						wr_addr_threshold_o,
	input [NURN_CNT_BIT_WIDTH-1:0]						wr_addr_posthistory_o,
    input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0]	wr_addr_prethistory_o,
    input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	wr_addr_G_o,//weight

    //data from datapath
    input [DSIZE-1:0]                                   data_wr_potential_dp_i,
    input [DSIZE-1:0]                                   data_wr_threshold_dp_i,
    input [STDP_WIN_BIT_WIDTH-1:0]                      data_wr_posthistory_dp_i,
    input [DSIZE-1:0]                                   data_wr_bias_dp_i,
    input [DSIZE-1:0]                                   data_wr_weight_dp_i,
    input [STDP_WIN_BIT_WIDTH-1:0]                      data_wr_prehistory_dp_i,

    //data from decoder
    input [DSIZE-1:0]                                   data_wr_potential_dc_i,
    input [DSIZE-1:0]                                   data_wr_threshold_dc_i,
    input [STDP_WIN_BIT_WIDTH-1:0]                      data_wr_posthistory_dc_i,
    input [DSIZE-1:0]                                   data_wr_bias_dc_i,
    input [DSIZE-1:0]                                   data_wr_weight_dc_i,
    input [STDP_WIN_BIT_WIDTH-1:0]                      data_wr_prehistory_dc_i,

    //data to status memory
    output [DSIZE-1:0]                                  data_wr_potential_o,
    output [DSIZE-1:0]                                  data_wr_threshold_o,
    output [STDP_WIN_BIT_WIDTH-1:0]                     data_wr_posthistory_o,
    output [DSIZE-1:0]                                  data_wr_bias_o,
    output [DSIZE-1:0]                                  data_wr_weight_o,
    output [STDP_WIN_BIT_WIDTH-1:0]                     data_wr_prehistory_o


    );

//define coding for different neuron parameters

// assign wr_config_A_o = wr_config_A_init_i;
// assign wr_config_B_o = wr_config_C1_init_i;
// assign wr_config_C1_o = wr_config_C1_init_i;
// assign wr_config_C2_o = wr_config_C2_init_i;
// assign wr_config_C3_o = wr_config_C3_init_i;
// assign wr_config_C4_o = wr_config_C4_init_i;
// assign wr_config_AER_o = wr_config_AER_init_i;

//config memory address mux
assign addr_config_A_o =  (en_config == 1'b1) ? wr_addr_config_A_dc_i : rd_addr_config_A_nc_i;
assign addr_config_B_o =  (en_config == 1'b1) ? wr_addr_config_A_dc_i : read_addr_config_B_i;
assign addr_config_C_o =  (en_config == 1'b1) ? write_addr_config_C_i : read_addr_config_C_i;
assign addr_AER_o =  (en_config == 1'b1) ? write_addr_config_AER_i : read_addr_config_AER_i;
assign addr_axon_scaling_o = (en_config == 1'b1) ? write_addr_axon_scaling_i : read_addr_axon_scaling_i;

always @(*)
    begin
        if (en_config == 1'b1)
            begin
                assign addr_config_A_o = wr_addr_config_A_dc_i;
                assign addr_config_B_o = wr_addr_config_A_dc_i;
                assign addr_config_C_o = write_addr_config_C_i;
                assign addr_AER_o = write_addr_config_AER_i;
                assign addr_axon_scaling_o = write_addr_axon_scaling_i;
            end
        else if (en_retrive == 1'b1)
            begin

            end
        else
            begin

            end

    end

//status memory write address mux
assign write_addr_bias_o = (en_config == 1'b0) ? write_addr_bias_controller_i :  write_addr_bias_init_i;
assign write_addr_potential_o = (en_config == 1'b0) ? write_addr_potential_controller_i : write_addr_potential_init_i;
assign write_addr_threshold_o = (en_config == 1'b0) ? write_addr_threshold_controller_i: write_addr_threshold_init_i;
assign write_addr_posthistory_o = (en_config == 1'b0) ? write_addr_posthistory_controller_i : write_addr_posthistory_init_i;
assign write_addr_G_o = (en_config == 1'b0) ? write_addr_G_controller_i : write_addr_G_init_i;
assign write_addr_prethistory_o = (en_config == 1'b0) ? write_addr_prehistory_controller_i : write_addr_prehistory_init_i;

//status memory write en mux
assign wr_en_Bias_o = (en_config == 1'b0) ? wr_Bias_controller_i : wr_Bias_init_i;
assign wr_en_Potential_o = (en_config == 1'b1) ? wr_Potential_controller_i : wr_Potential_init_i;
assign wr_en_Threshold_o = (en_config == 1'b1) ? wr_Threshold_controller_i : wr_Threshold_init_i;
assign wr_en_Posthistory_o = (en_config == 1'b1) ? wr_Posthistory_controller_i : wr_Posthistory_init_i;
assign wr_en_Prehistory_o = (en_config == 1'b1) ? wr_Prehistory_controller_i : wr_Prehistory_init_i;
assign wr_en_Weight_o = (en_config == 1'b1) ? wr_Weight_controller_i : wr_Weight_init_i; 


assign data_wr_potential_o = (en_config == 1'b0) ? data_wr_potential_datapath_i : data_wr_potential_decoder_i;
assign data_wr_threshold_o = (en_config == 1'b0) ? data_wr_threshold_datapath_i : data_wr_threshold_decoder_i;
assign data_wr_posthistory_o = (en_config == 1'b0) ? data_wr_posthistory_datapath_i : data_wr_posthistory_decoder_i;
assign data_wr_bias_o = (en_config == 1'b0) ? data_wr_bias_datapath_i : data_wr_bias_decoder_i;
assign data_wr_weight_o = (en_config == 1'b0) ? data_wr_weight_datapath_i : data_wr_weight_decoder_i;
assign data_wr_prehistory_o = (en_config == 1'b0) ? data_wr_prehistory_datapath_i : data_wr_prehistory_decoder_i;


endmodule