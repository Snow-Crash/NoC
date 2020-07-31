//------------------------------------------------------------------------
// Title       : Neuron testbench
// Version     : 0.1
// Author      : Khadeer Ahmed
// Date created: 11/28/2016
// -----------------------------------------------------------------------
// Discription : testbench for neuron controller
// -----------------------------------------------------------------------
// Maintainance History
// -ver x.x : date : auth
//		details
//------------------------------------------------------------------------
//2017.4.24 add two parameter SYNTH_PATH and SIM_PATH.
//2017.5.10 add new signal: update_weight_enable in learn pipeline of datapath.v. if enLTD/enLTP is 
//			enabled, update_weight_enable is high. It is used to control weight memory write enable 
//			signal generated by controller. Thses two signal are sent into a AND gate. 
//			if update_weight_enable is 0, weight won't be updated.
//			Issue: timing of update_weight_enable is not correct, it's not aligned weight memory write enable signal.
//			it's earlier than weight memory write enable signal. need to fix it by adding a new pipeline. 
//2017.9.7  Add two wire, expired_post_history_write_back and en_expired_post_history_write_back. And make connections.

`include "../src/neuron_define.v"
// `timescale 1ns/100ps
// `define tpd_clk 5
// `define DUMP_MEMORY
// `define NEW_STATUS_MEMORY
// `define NEW_CONFIG_MEMORY
// `define SEPARATE_ADDRESS
// `define RECORD_SPIKE

module Neuron_debug(clk, rst_n, SpikePacket, outSpike, start, inSpike, packet_write_req);

	
	parameter NUM_NURNS    = 2  ;
	parameter NUM_AXONS    = 2  ;

	parameter DATA_BIT_WIDTH_INT    = 8 ;
	parameter DATA_BIT_WIDTH_FRAC   = 8 ;

	parameter NURN_CNT_BIT_WIDTH   = 1 ;
	parameter AXON_CNT_BIT_WIDTH   = 1 ;

	parameter STDP_WIN_BIT_WIDTH = 8;
	
	parameter AER_BIT_WIDTH = 32;

	parameter PRIORITY_ENC_OUT_BIT_WIDTH = 4;
	
	parameter SEED = 16'h0380;


	parameter DSIZE = DATA_BIT_WIDTH_INT+DATA_BIT_WIDTH_FRAC;

	parameter X_ID = "1";
	parameter Y_ID = "1";

	
	parameter STOP_STEP = 5;

	//parameter MEM_A_MIF_PATH = "D:/code/synth/data1_1/mem_A.mif";
	//parameter MEM_B_MIF_PATH = "D:/code/synth/data1_1/mem_B.mif";
	//parameter MEM_C_MIF_PATH = "D:/code/synth/data1_1/mem_C.mif";
	//parameter BIAS_MIF_PATH = "D:/code/synth/data1_1/Bias.mif";
	//parameter MEMBPOT_MIF_PATH = "D:/code/synth/data1_1/MembPot.mif";
	//parameter TH_MIF_PATH = "D:/code/synth/data1_1/Th.mif";
	//parameter POSTSPIKEHISTORY_MIF_PATH = "D:/code/synth/data1_1/PostSpikeHistory.mif";
	//parameter PRESPIKEHISTORY_MIF_PATH = "D:/code/synth/data1_1/PreSpikeHistory.mif";
	//parameter WEIGHTS_MIF_PATH = "D:/code/synth/data1_1/Weights.mif";
	parameter SYNTH_PATH = "D:/code/synth/data";
	parameter SIM_PATH =  "D:/code/data";

	input clk, rst_n, start;
	input [(1<<AXON_CNT_BIT_WIDTH) -1:0] inSpike;
	output  outSpike;
	output [31:0] SpikePacket;
	output packet_write_req;
	//REGISTER DECLARATION
	//reg  start;


	//WIRE DECLARATIONS
	//--------------------------------------------------//
	//controller
	wire [1:0] sel_rclAdd_B, sel_wrBackStat_B;
	wire [NURN_CNT_BIT_WIDTH-1:0] Addr_Config_A, Addr_Config_B;
	wire [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] Addr_Config_C, Addr_StatRd_C;
	wire [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] Addr_StatWr_D, Addr_StatRd_E;
	wire [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] Addr_StatRd_F, Addr_StatWr_G;
	wire [NURN_CNT_BIT_WIDTH-1+2:0] Addr_StatRd_A;
	wire [NURN_CNT_BIT_WIDTH-1:0] Addr_StatWr_B;
	//wire shift_writeback_en_buffer;
	wire expired_post_history_write_back;

	//config mem
	wire [STDP_WIN_BIT_WIDTH-1:0] LTP_Win, LTD_Win;
	wire [DSIZE-1:0] LTP_LrnRt, LTD_LrnRt, Th_Mask;
	wire [DSIZE-1:0] RstPot;
	wire [AER_BIT_WIDTH-1:0] SpikeAER;
	wire [DSIZE-1:0] FixedThreshold;

	//status mem
	wire [DSIZE-1:0] data_StatRd_A, data_StatRd_E, data_StatRd_F;
	wire [STDP_WIN_BIT_WIDTH-1:0] data_StatRd_C;

	wire [DSIZE-1:0] data_wr_bias, data_wr_potential, data_wr_threshold, data_rd_bias, data_rd_potential, data_rd_threshold;
	wire [STDP_WIN_BIT_WIDTH-1:0] data_wr_posthistory, data_rd_posthistory;

	//data path
	wire [DSIZE-1:0] data_StatWr_B, data_StatWr_G;
	wire [STDP_WIN_BIT_WIDTH-1:0] data_StatWr_D;
	wire update_weight_enable;

	wire write_enable_G;
	wire en_expired_post_history_write_back;

	assign SpikePacket = SpikeAER;
	//assign outSpike = outSpike_o;
	wire [NURN_CNT_BIT_WIDTH-1:0] read_address_bias, read_address_posthistory, read_address_potential, read_address_threshold;
	wire [NURN_CNT_BIT_WIDTH-1:0] write_address_bias, write_address_posthistory, write_address_potential, write_address_threshold;
	//wire [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0]   read_address_weight, read_address_prehistory;
	wire [DSIZE-1:0] data_StatRd_A2;
	//--------------------------------------------------//

	wire [NURN_CNT_BIT_WIDTH-1:0] access_address_config_A, access_address_config_B;
	wire [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] access_address_config_C;

	wire [NURN_CNT_BIT_WIDTH-1:0] AER_pointer;

	//MODULE INSTANTIATIONS
	NurnCtrlr 
	#(
		.NUM_NURNS				( NUM_NURNS ),
		.NUM_AXONS				( NUM_AXONS ),

		.NURN_CNT_BIT_WIDTH		( NURN_CNT_BIT_WIDTH ),
		.AXON_CNT_BIT_WIDTH		( AXON_CNT_BIT_WIDTH )
	)
	NURNCTRLR
	(
		.clk_i				( clk 	),
		.rst_n_i 			( rst_n ),

		.start_i 			( start ),

		//data path
		.rstAcc_o 			( rstAcc ),
		.accEn_o 			( accEn ),
		.cmp_th_o 			( cmp_th ),
		.buffMembPot_o 		( buffMembPot ),
		.updtPostSpkHist_o	( updtPostSpkHist ),
		.addLrnRt_o 		(  ),
		.enQuant_o 			(  ),
		.buffBias_o 		( buffBias ),
		.lrnUseBias_o 		( lrnUseBias ),
		.cmpSTDP_o 			(  ),
		.sel_rclAdd_B_o 	( sel_rclAdd_B ),
		.sel_wrBackStat_B_o ( sel_wrBackStat_B ),
		//.shift_writeback_en_buffer_o (shift_writeback_en_buffer),
		.expired_post_history_write_back_o(expired_post_history_write_back),
		.enLrnWtPipln_o		(enLrnWtPipln),

		//config mem
		.biasLrnMode_i  	( biasLrnMode   ),
		.Addr_Config_A_o 	( Addr_Config_A ),
		.rdEn_Config_A_o 	( rdEn_Config_A ),

		.NurnType_i			( NurnType      ),
		.Addr_Config_B_o 	( Addr_Config_B ),
		.rdEn_Config_B_o 	( rdEn_Config_B ),

		.axonLrnMode_i  	( axonLrnMode  ),
		.Addr_Config_C_o 	( Addr_Config_C ),
		.rdEn_Config_C_o 	( rdEn_Config_C ),

		//status mem
		.Addr_StatRd_A_o	( Addr_StatRd_A ),
		.rdEn_StatRd_A_o	( rdEn_StatRd_A ),

		.Addr_StatWr_B_o	( Addr_StatWr_B ),
		.wrEn_StatWr_B_o	( wrEn_StatWr_B ),

		.Addr_StatRd_C_o	( Addr_StatRd_C ),
		.rdEn_StatRd_C_o	( rdEn_StatRd_C ),

		.Addr_StatWr_D_o	( Addr_StatWr_D ),
		.wrEn_StatWr_D_o	( wrEn_StatWr_D ),

		.Addr_StatRd_E_o	( Addr_StatRd_E ),
		.rdEn_StatRd_E_o	( rdEn_StatRd_E ),

		.Addr_StatRd_F_o	( Addr_StatRd_F ),
		.rdEn_StatRd_F_o	( rdEn_StatRd_F ),

		.Addr_StatWr_G_o	( Addr_StatWr_G ),
		.wrEn_StatWr_G_o	( wrEn_StatWr_G ),
		.en_expired_post_history_write_back_i (en_expired_post_history_write_back),
		.read_weight_fifo_o (read_weight_fifo),

`ifdef AER_MULTICAST
		.read_next_AER_i	(read_next_AER),
		.AER_pointer_o		(AER_pointer),
		.th_compare_i		(th_compare),
		.packet_write_req_o (packet_write_req),
`endif


	`ifdef SEPARATE_ADDRESS
		.read_address_bias_o				(read_address_bias),
		.read_address_potential_o			(read_address_potential),
		.read_address_threshold_o			(read_address_threshold),
		.read_address_posthistory_o			(read_address_posthistory),

		.write_address_bias_o				(write_address_bias),
		.write_address_potential_o			(write_address_potential),
		.write_address_threshold_o			(write_address_threshold),
		.write_address_posthistory_o		(write_address_posthistory),
	`endif

		.read_enable_bias_o					(read_enable_bias),
		.write_enable_bias_o				(write_enable_bias),
		.read_enable_potential_o			(read_enable_potential),
		.write_enable_potential_o			(write_enable_potential),
		.read_enable_threshold_o			(read_enable_threshold),
		.write_enable_threshold_o			(write_enable_threshold),
		.read_enable_posthistory_o			(read_enable_posthistory),
		.write_enable_posthistory_o			(write_enable_posthistory)
		//.read_enable_prehistory_o			(read_enable_prehistory),
		//.write_enable_prehistory_o		(write_enable_prehistory),
		//.read_enable_weight_learn_o		(read_enable_weight_learn),
		//.read_enable_weight_recall_o		(read_enable_weight_recall),
		//.write_enable_weight_o			(write_enable_weight)
	);

	dataPath
	#(
		
		.X_ID(X_ID),
		.Y_ID(Y_ID),
		.SIM_PATH(SIM_PATH),
		.STOP_STEP(STOP_STEP),

		.NUM_NURNS			( NUM_NURNS ),
		.NUM_AXONS			( NUM_AXONS ),

		.DATA_BIT_WIDTH_INT	( DATA_BIT_WIDTH_INT ),
		.DATA_BIT_WIDTH_FRAC	( DATA_BIT_WIDTH_FRAC ),

		.NURN_CNT_BIT_WIDTH	( NURN_CNT_BIT_WIDTH ),
		.AXON_CNT_BIT_WIDTH	( AXON_CNT_BIT_WIDTH ),

		.STDP_WIN_BIT_WIDTH	( STDP_WIN_BIT_WIDTH ),
		
		.AER_BIT_WIDTH		( AER_BIT_WIDTH ),
		
		.PRIORITY_ENC_OUT_BIT_WIDTH (PRIORITY_ENC_OUT_BIT_WIDTH),

		.SEED 				( SEED )

	)
	DATAPATH
	(
		.clk_i				( clk 	),
		.rst_n_i			( rst_n ),

		//config memory
		.RstPot_i			( RstPot 		),
		.NurnType_i 		( NurnType 		),
		.RandTh_i 			( RandTh 		),
		.Th_Mask_i			( Th_Mask 		),
		.LTP_Win_i			( LTP_Win 	),
		.LTD_Win_i			( LTD_Win	),
		.axonLrnMode_i 		( axonLrnMode 	),
		.LTP_LrnRt_i		( LTP_LrnRt 	),
		.LTD_LrnRt_i		( LTD_LrnRt 	),
		.FixedThreshold_i	(FixedThreshold),

		//status memory
		.data_StatRd_A_i 	( data_StatRd_A ),
		.data_StatRd_C_i 	( data_StatRd_C ),
		.data_StatRd_E_i 	( data_StatRd_E ),
		.data_StatRd_F_i 	( data_StatRd_F ),

		.data_StatWr_B_o 	( data_StatWr_B ),
		.data_StatWr_D_o 	( data_StatWr_D ),
		.data_StatWr_G_o 	( data_StatWr_G ),

		.data_rd_bias_i(data_rd_bias),
		.data_rd_potential_i(data_rd_potential),
		.data_rd_threshold_i(data_rd_threshold),
		.data_rd_posthistory_i(data_rd_posthistory),

		.data_wr_bias_o(data_wr_bias),
		.data_wr_potential_o(data_wr_potential),
		.data_wr_threshold_o(data_wr_threshold),
		.data_wr_posthistory_o(data_wr_posthistory),


		//in spike buffer
		.rcl_inSpike_i 		( Rcl_InSpike 	),
		.lrn_inSpike_i 		( Lrn_InSpike 	),

		//Router
		.outSpike_o 		(outSpike),

		//controller
		.rstAcc_i 			( rstAcc 		),
		.accEn_i 			( accEn 		),
		.cmp_th_i 			( cmp_th 		),
		.sel_rclAdd_B_i 	( sel_rclAdd_B 	),
		.sel_wrBackStat_B_i ( sel_wrBackStat_B),
		.buffMembPot_i 		( buffMembPot 	),
		.updtPostSpkHist_i	( updtPostSpkHist ),
		.addLrnRt_i 		(),
		.enQuant_i 			(),
		.buffBias_i 		( buffBias ),
		.lrnUseBias_i 		( lrnUseBias ),
		.cmpSTDP_i 			(),
		.enLrnWtPipln_i		(enLrnWtPipln),

		`ifdef DUMP_OUTPUT_SPIKE
		.start_i			(start),
		`endif

		`ifdef AER_MULTICAST
		.th_compare_o		(th_compare),
		`endif

		.update_weight_enable_o		(update_weight_enable),
		//.shift_writeback_en_buffer_i (shift_writeback_en_buffer),
		.expired_post_history_write_back_i(expired_post_history_write_back),
		.en_expired_post_history_write_back_o (en_expired_post_history_write_back)

	);

ConfigMem_Asic_Onchip
#(
	.NUM_NURNS(NUM_NURNS)  ,
	.NUM_AXONS(NUM_AXONS) ,

	.DSIZE(DSIZE) ,

	.NURN_CNT_BIT_WIDTH(NURN_CNT_BIT_WIDTH),
	.AXON_CNT_BIT_WIDTH(AXON_CNT_BIT_WIDTH),

	.STDP_WIN_BIT_WIDTH(STDP_WIN_BIT_WIDTH),

	.AER_BIT_WIDTH(AER_BIT_WIDTH),

	.CONFIG_PARAMETER_NUMBER(9),

	.LEARN_MODE_MEMORY_WIDTH(2),
	

	.X_ID(X_ID),
	.Y_ID(Y_ID),
	.SYNTH_PATH(SYNTH_PATH),
	.SIM_PATH(SIM_PATH)	

)
ConfigMem_Asic
(
	.clk_i(clk)			,
	.rst_n_i(rst_n)			,

	.config_data_in(),

	.config_write_enable(),

	.FixedThreshold_o(FixedThreshold),
	.Number_Neuron_o(),
	.Number_Axon_o(),

	//read port A
	.Addr_Config_A_i(Addr_Config_A),
	.rdEn_Config_A_i(rdEn_Config_A),

	.LTP_Win_o(LTP_Win ),
	.LTD_Win_o(LTD_Win ),
	.LTP_LrnRt_o(LTP_LrnRt ),
	.LTD_LrnRt_o(LTD_LrnRt ),
	.biasLrnMode_o(biasLrnMode ),
	
	//read port B
	.Addr_Config_B_i(Addr_Config_B ),
	.rdEn_Config_B_i(rdEn_Config_B),

	.NurnType_o(NurnType ),
	.RandTh_o(RandTh),
	.Th_Mask_o(Th_Mask ),
	.RstPot_o( RstPot),
	.SpikeAER_o(SpikeAER ),

`ifdef AER_MULTICAST
		.read_next_AER_o	(read_next_AER),
		.AER_pointer_i		(AER_pointer),
`endif

	//read port C
	.Addr_Config_C_i( Addr_Config_C),
	.rdEn_Config_C_i(rdEn_Config_C ),

	.axonLrnMode_o(axonLrnMode )
);


ConfigMem_Asic
#(
	.NUM_NURNS(NUM_NURNS)  ,
	.NUM_AXONS(NUM_AXONS) ,

	.DSIZE(DSIZE) ,

	.NURN_CNT_BIT_WIDTH(NURN_CNT_BIT_WIDTH),
	.AXON_CNT_BIT_WIDTH(AXON_CNT_BIT_WIDTH),

	.STDP_WIN_BIT_WIDTH(STDP_WIN_BIT_WIDTH),

	.AER_BIT_WIDTH(AER_BIT_WIDTH),

	.CONFIG_PARAMETER_NUMBER(9),

	.LEARN_MODE_MEMORY_WIDTH(2),
	

	.X_ID(X_ID),
	.Y_ID(Y_ID),
	.SYNTH_PATH(SYNTH_PATH),
	.SIM_PATH(SIM_PATH)	

)
ConfigMem_Asic_uut
(
	.clk_i(clk)			,
	.rst_n_i(rst_n)			,

	.config_data_in(),

	.config_write_enable(),

	.FixedThreshold_o( ),
	.Number_Neuron_o(),
	.Number_Axon_o(),

	//read port A
	.Addr_Config_A_i(Addr_Config_A),
	.rdEn_Config_A_i(rdEn_Config_A),

	.LTP_Win_o(  ),
	.LTD_Win_o(  ),
	.LTP_LrnRt_o(  ),
	.LTD_LrnRt_o(  ),
	.biasLrnMode_o(  ),
	
	//read port B
	.Addr_Config_B_i(Addr_Config_B ),
	.rdEn_Config_B_i(rdEn_Config_B),

	.NurnType_o(  ),
	.RandTh_o( ),
	.Th_Mask_o(  ),
	.RstPot_o(  ),
	.SpikeAER_o(  ),

`ifdef AER_MULTICAST
		.read_next_AER_o	(read_next_AER),
		.AER_pointer_i		(AER_pointer),
`endif

	//read port C
	.Addr_Config_C_i( Addr_Config_C),
	.rdEn_Config_C_i(rdEn_Config_C ),

	.axonLrnMode_o(  ),
	.ce(1'b1)
);




	StatusMem_Asic
	#(
		
		.STOP_STEP(STOP_STEP),
		
		.NUM_NURNS(NUM_NURNS),
		.NUM_AXONS(NUM_AXONS),

		.DSIZE(DSIZE),

		.NURN_CNT_BIT_WIDTH(NURN_CNT_BIT_WIDTH),
		.AXON_CNT_BIT_WIDTH(AXON_CNT_BIT_WIDTH),

		.STDP_WIN_BIT_WIDTH(STDP_WIN_BIT_WIDTH),

		
		.X_ID(X_ID),
		.Y_ID(Y_ID),
		.SIM_PATH(SIM_PATH),
		.SYNTH_PATH(SYNTH_PATH)
	)
	StatusMem_Asic_uut
	(

		.start_i(start),
		.clk_i(clk),
		.rst_n_i(rst_n),
		.ce(1'b1),

		//read port A
		.Addr_StatRd_A_i								(Addr_StatRd_A),
		.read_enable_bias_i								(read_enable_bias),
		.read_enable_potential_i						(read_enable_potential),
		.read_enable_threshold_i						(read_enable_threshold),
		.read_enable_posthistory_i						(read_enable_posthistory),

		.write_enable_bias_i 							(write_enable_bias),
		.write_enable_potential_i						(write_enable_potential),
		.write_enable_threshold_i						(write_enable_threshold),
		.write_enable_posthistory_i						(write_enable_posthistory),

		//.data_StatRd_A_o								(data_StatRd_A),
		.data_wr_bias_i									(data_wr_bias),
		.data_wr_potential_i							(data_wr_potential),
		.data_wr_threshold_i							(data_wr_threshold),
		.data_wr_posthistory_i							(data_wr_posthistory),

		.data_rd_bias_o(data_rd_bias),
		.data_rd_potential_o(data_rd_potential),
		.data_rd_threshold_o(data_rd_threshold),
		.data_rd_posthistory_o(data_rd_posthistory),

`ifdef SEPARATE_ADDRESS
		.read_addr_bias_i								(read_address_bias),
		.read_addr_potential_i							(read_address_potential),
		.read_addr_threshold_i							(read_address_threshold),
		.read_addr_posthistory_i						(read_address_posthistory),

		.write_addr_bias_i								(write_address_bias),
		.write_addr_potential_i							(write_address_potential),
		.write_addr_threshold_i							(write_address_threshold),
		.write_addr_posthistory_i						(write_address_posthistory),
`endif
		//write port B
		.Addr_StatWr_B_i(Addr_StatWr_B),
		//.data_StatWr_B_i(data_StatWr_B),
		
		//read port C
		.Addr_StatRd_C_i(Addr_StatRd_C),
		.rdEn_StatRd_C_i(rdEn_StatRd_C),
		.data_StatRd_C_o( ),

		//write port D
		.Addr_StatWr_D_i(Addr_StatWr_D),
		.wrEn_StatWr_D_i(wrEn_StatWr_D),
		.data_StatWr_D_i(data_StatWr_D),
		
		//read port E
		.Addr_StatRd_E_i(Addr_StatRd_E),
		.rdEn_StatRd_E_i(rdEn_StatRd_E),

		.data_StatRd_E_o( ),
		
		//read port F
		.Addr_StatRd_F_i(Addr_StatRd_F),
		.rdEn_StatRd_F_i(read_weight_fifo),

		.data_StatRd_F_o( ),

		//write port G
		.Addr_StatWr_G_i(Addr_StatWr_G),
		.wrEn_StatWr_G_i(write_enable_G),
		.data_StatWr_G_i(data_StatWr_G)
	);




	StatusMem_Asic_Onchip_SharePort
	#(
		
		.STOP_STEP(STOP_STEP),
		
		.NUM_NURNS(NUM_NURNS),
		.NUM_AXONS(NUM_AXONS),

		.DSIZE(DSIZE),

		.NURN_CNT_BIT_WIDTH(NURN_CNT_BIT_WIDTH),
		.AXON_CNT_BIT_WIDTH(AXON_CNT_BIT_WIDTH),

		.STDP_WIN_BIT_WIDTH(STDP_WIN_BIT_WIDTH),

		
		.X_ID(X_ID),
		.Y_ID(Y_ID),
		.SIM_PATH(SIM_PATH),
		.SYNTH_PATH(SYNTH_PATH)
	)
	StatusMem_Asic
	(

		.start_i(start),
		.clk_i(clk),
		.rst_n_i(rst_n),

		//read port A
		.Addr_StatRd_A_i								(Addr_StatRd_A),
		.read_enable_bias_i								(read_enable_bias),
		.read_enable_potential_i						(read_enable_potential),
		.read_enable_threshold_i						(read_enable_threshold),
		.read_enable_posthistory_i						(read_enable_posthistory),

		.write_enable_bias_i 							(write_enable_bias),
		.write_enable_potential_i						(write_enable_potential),
		.write_enable_threshold_i						(write_enable_threshold),
		.write_enable_posthistory_i						(write_enable_posthistory),

		.data_StatRd_A_o								(data_StatRd_A),

		//write port B
		.Addr_StatWr_B_i(Addr_StatWr_B),
		.data_StatWr_B_i(data_StatWr_B),
		
		//read port C
		.Addr_StatRd_C_i(Addr_StatRd_C),
		.rdEn_StatRd_C_i(rdEn_StatRd_C),
		.data_StatRd_C_o(data_StatRd_C),

		//write port D
		.Addr_StatWr_D_i(Addr_StatWr_D),
		.wrEn_StatWr_D_i(wrEn_StatWr_D),
		.data_StatWr_D_i(data_StatWr_D),
		
		//read port E
		.Addr_StatRd_E_i(Addr_StatRd_E),
		.rdEn_StatRd_E_i(rdEn_StatRd_E),

		.data_StatRd_E_o(data_StatRd_E),
		
		//read port F
		.Addr_StatRd_F_i(Addr_StatRd_F),
		.rdEn_StatRd_F_i(read_weight_fifo),

		.data_StatRd_F_o(data_StatRd_F),

		//write port G
		.Addr_StatWr_G_i(Addr_StatWr_G),
		.wrEn_StatWr_G_i(write_enable_G),
		.data_StatWr_G_i(data_StatWr_G)
	);

	assign write_enable_G = update_weight_enable & wrEn_StatWr_G;

	InSpikeBuf
	#(
		.NUM_AXONS			( NUM_AXONS ),
		.AXON_CNT_BIT_WIDTH	( AXON_CNT_BIT_WIDTH ),
		.X_ID					(X_ID),
		.Y_ID					(Y_ID)
	)
	INSPIKEBUF
	(
		.clk_i				( clk   ),
		.rst_n_i			( rst_n ),
		
		.start_i			( start ),
		
		.RclAxonAddr_i 		( Addr_StatRd_E[AXON_CNT_BIT_WIDTH-1:0] ),
		.rdEn_RclInSpike_i 	( rdEn_StatRd_E ),

		.saveRclSpikes_i    ( buffBias ),
		.LrnAxonAddr_i 		( Addr_StatRd_C[AXON_CNT_BIT_WIDTH-1:0] ),
		.rdEn_LrnInSpike_i 	( rdEn_StatRd_C ),

		.Rcl_InSpike_o		( Rcl_InSpike ),
		.Lrn_InSpike_o		( Lrn_InSpike ),
		.spike_in			( inSpike)	//input from interface
	);

endmodule