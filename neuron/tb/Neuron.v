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

`timescale 1ns/100ps
`define tpd_clk 5

module Neuron(clk, rst_n, SpikePacket, outSpike, start, inSpike);

	
	parameter NUM_NURNS    = 2  ;
	parameter NUM_AXONS    = 2  ;

	parameter DATA_BIT_WIDTH_INT    = 8 ;
	parameter DATA_BIT_WIDTH_FRAC   = 8 ;

	parameter NURN_CNT_BIT_WIDTH   = 1 ;
	parameter AXON_CNT_BIT_WIDTH   = 1 ;

	parameter STDP_WIN_BIT_WIDTH = 8;
	
	parameter AER_BIT_WIDTH = 32;

	parameter PRIORITY_ENC_OUT_BIT_WIDTH = 3;
	
	parameter SEED = 16'h0380;


	parameter DSIZE = DATA_BIT_WIDTH_INT+DATA_BIT_WIDTH_FRAC;

	parameter X_ID = "1";
	parameter Y_ID = "1";

	input clk, rst_n, start;
	input [NUM_AXONS - 1:0] inSpike;
	output  outSpike;
	output [31:0] SpikePacket;
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
	wire [NURN_CNT_BIT_WIDTH+2-1:0] Addr_StatRd_A, Addr_StatWr_B;

	//config mem
	wire [STDP_WIN_BIT_WIDTH-1:0] LTP_Win, LTD_Win;
	wire [DSIZE-1:0] LTP_LrnRt, LTD_LrnRt, Th_Mask;
	wire [DSIZE-1:0] RstPot;
	wire [AER_BIT_WIDTH-1:0] SpikeAER;

	//status mem
	wire [DSIZE-1:0] data_StatRd_A, data_StatRd_E, data_StatRd_F;
	wire [STDP_WIN_BIT_WIDTH-1:0] data_StatRd_C;

	//data path
	wire [DSIZE-1:0] data_StatWr_B, data_StatWr_G;
	wire [STDP_WIN_BIT_WIDTH-1:0] data_StatWr_D;

	assign SpikePacket = SpikeAER;
	//assign outSpike = outSpike_o;

	//--------------------------------------------------//


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
		.wrEn_StatWr_G_o	( wrEn_StatWr_G )
	);

	dataPath
	#(
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

		//status memory
		.data_StatRd_A_i 	( data_StatRd_A ),
		.data_StatRd_C_i 	( data_StatRd_C ),
		.data_StatRd_E_i 	( data_StatRd_E ),
		.data_StatRd_F_i 	( data_StatRd_F ),

		.data_StatWr_B_o 	( data_StatWr_B ),
		.data_StatWr_D_o 	( data_StatWr_D ),
		.data_StatWr_G_o 	( data_StatWr_G ),

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
		.cmpSTDP_i 			()	

	);



	ConfigMem
	#(
		.NUM_NURNS				( NUM_NURNS ),
		.NUM_AXONS				( NUM_AXONS ),

		.DSIZE					( DSIZE ),

		.NURN_CNT_BIT_WIDTH		( NURN_CNT_BIT_WIDTH ),
		.AXON_CNT_BIT_WIDTH		( AXON_CNT_BIT_WIDTH ),

		.STDP_WIN_BIT_WIDTH		( STDP_WIN_BIT_WIDTH ),
		.AER_BIT_WIDTH 			( AER_BIT_WIDTH ),

		.X_ID					(X_ID),
		.Y_ID					(Y_ID)
	)
	CONFIGMEM
	(
		.clk_i				( clk 	),
		.rst_n_i			( rst_n ),

		//read port A
		.Addr_Config_A_i  	( Addr_Config_A ),
		.rdEn_Config_A_i  	( rdEn_Config_A ),

		.LTP_Win_o			( LTP_Win ),
		.LTD_Win_o	( LTD_Win ),
		.LTP_LrnRt_o		( LTP_LrnRt 	),
		.LTD_LrnRt_o		( LTD_LrnRt 	),
		.biasLrnMode_o 		( biasLrnMode   ),
		
		//read port B
		.Addr_Config_B_i	( Addr_Config_B ),
		.rdEn_Config_B_i 	( rdEn_Config_B ),

		.NurnType_o 		( NurnType 		),
		.RandTh_o			( RandTh 		),
		.Th_Mask_o			( Th_Mask 		),
		.RstPot_o			( RstPot 		),
		.SpikeAER_o			( SpikeAER 		),

		//read port C
		.Addr_Config_C_i	( Addr_Config_C ),
		.rdEn_Config_C_i 	( rdEn_Config_C ),

		.axonLrnMode_o 		( axonLrnMode 	)
	);

	StatusMem
	#(
		.NUM_NURNS    		( NUM_NURNS ),
		.NUM_AXONS    		( NUM_AXONS ),

		.DSIZE				( DSIZE ),

		.NURN_CNT_BIT_WIDTH ( NURN_CNT_BIT_WIDTH ),
		.AXON_CNT_BIT_WIDTH ( AXON_CNT_BIT_WIDTH ),

		.STDP_WIN_BIT_WIDTH ( STDP_WIN_BIT_WIDTH ),

		.X_ID				(X_ID),
		.Y_ID				(Y_ID)
	)
	STATUSMEM
	(
		.clk_i				( clk   ),
		.rst_n_i			( rst_n ),

		//read port A
		.Addr_StatRd_A_i	( Addr_StatRd_A ),
		.rdEn_StatRd_A_i	( rdEn_StatRd_A ),

		.data_StatRd_A_o 	( data_StatRd_A ),

		//write port B
		.Addr_StatWr_B_i	( Addr_StatWr_B ),
		.wrEn_StatWr_B_i	( wrEn_StatWr_B ),
		.data_StatWr_B_i	( data_StatWr_B ),
		
		//read port C
		.Addr_StatRd_C_i	( Addr_StatRd_C ),
		.rdEn_StatRd_C_i	( rdEn_StatRd_C ),

		.data_StatRd_C_o    ( data_StatRd_C ),

		//write port D
		.Addr_StatWr_D_i	( Addr_StatWr_D ),
		.wrEn_StatWr_D_i	( wrEn_StatWr_D ),
		.data_StatWr_D_i	( data_StatWr_D ),	
					
		//read port E
		.Addr_StatRd_E_i	( Addr_StatRd_E ),
		.rdEn_StatRd_E_i	( rdEn_StatRd_E ),

		.data_StatRd_E_o 	( data_StatRd_E ),
		
		//read port F
		.Addr_StatRd_F_i	( Addr_StatRd_F ),
		.rdEn_StatRd_F_i	( rdEn_StatRd_F ),

		.data_StatRd_F_o 	( data_StatRd_F ),

		//write port G
		.Addr_StatWr_G_i	( Addr_StatWr_G ),
		.wrEn_StatWr_G_i	( wrEn_StatWr_G ),
		.data_StatWr_G_i 	( data_StatWr_G )
	);

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