//------------------------------------------------------------------------
// Title       : config memory
// Version     : 0.1
// Author      : Khadeer Ahmed
// Date created: 12/8/2016
// -----------------------------------------------------------------------
// Discription : controller for the neuron
// NurnTyp_i: 0: I&F
//			  1: ReLU
// -----------------------------------------------------------------------
// Maintainance History
// -ver x.x : date : auth
//		details
//------------------------------------------------------------------------
//2017.4.1  localparam cause error in quartus, unkown reason
//2017.4.21 rewrite config memory. Simulated in recall mode, timing is not affacted.
//2017.4.24 add two parameter SYNTH_PATH and SIM_PATH.
//			change sensitivity list of the three latches. sensitivity list was incomplete
//			only includes enable signal.　data shoule also be included.	

//Todo		If rdEn_Config_A_i, rdEn_Config_A_i and rdEn_Config_A_i are not delayed,
//			use these three signal as enable signal of the latched, still get right
//			result. 
//			1: need to check if it is necessary to delay the 3 signals.
//			2: check if it is necessasy to have the three signal: rdEn_Config_A_i, 
//			rdEn_Config_A_i and rdEn_Config_A_i

`timescale 1ns/100ps

`define SIM_MEM_INIT
`define NULL 0

module ConfigMem
#(
	parameter NUM_NURNS    = 256  ,
	parameter NUM_AXONS    = 256  ,

	parameter DSIZE    = 16 ,

	parameter NURN_CNT_BIT_WIDTH   = 8 ,
	parameter AXON_CNT_BIT_WIDTH   = 8 ,

	parameter STDP_WIN_BIT_WIDTH = 8 ,

	parameter AER_BIT_WIDTH = 32 ,

	parameter X_ID = "1",
	parameter Y_ID = "1",
	parameter DIR_ID = {X_ID, "_", Y_ID},
	parameter SYNTH_PATH = "D:/code/synth/data",
	parameter SIM_PATH = "D:/code/data"
	//parameter MEM_A_MIF_PATH = {SYNTH_PATH, DIR_ID, "/mem_A.mif"},
	//parameter MEM_B_MIF_PATH = {SYNTH_PATH, DIR_ID, "/mem_B.mif"},
	//parameter MEM_C_MIF_PATH = {SYNTH_PATH, DIR_ID, "/mem_C.mif"}
	

)
(
	input 			clk_i			,
	input 			rst_n_i			,

	//read port A
	input [NURN_CNT_BIT_WIDTH-1:0]						Addr_Config_A_i,
	input 												rdEn_Config_A_i,

	output [STDP_WIN_BIT_WIDTH-1:0]						LTP_Win_o,
	output [STDP_WIN_BIT_WIDTH-1:0]						LTD_Win_o,
	output [DSIZE-1:0]  								LTP_LrnRt_o,
	output [DSIZE-1:0]									LTD_LrnRt_o,
	output 												biasLrnMode_o,
	
	//read port B
	input [NURN_CNT_BIT_WIDTH-1:0]						Addr_Config_B_i,
	input 												rdEn_Config_B_i,

	output												NurnType_o,
	output												RandTh_o,
	output [DSIZE-1:0] 									Th_Mask_o,
	output [DSIZE-1:0] 									RstPot_o,
	output [AER_BIT_WIDTH-1:0] 							SpikeAER_o,

	//read port C
	input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	Addr_Config_C_i,
	input 												rdEn_Config_C_i,

	output												axonLrnMode_o
);

	//port A memory -- {LTP_Win, LTD_Win, LTP_LrnRt, LTD_LrnRt, LrnModeBias}
	parameter MEM_WIDTH_A = STDP_WIN_BIT_WIDTH + STDP_WIN_BIT_WIDTH + DSIZE + DSIZE + 1;
	//port B memory -- {NurnType, RandTh, Th_Mask, RstPot, SpikeAER}
	parameter MEM_WIDTH_B = 1 + 1 + DSIZE + DSIZE + AER_BIT_WIDTH;
	//port C memory -- LrnModeWght
	parameter MEM_WIDTH_C = 1;

	//wire [MEM_WIDTH_A - 1:0] mem_A_out;
	//wire [MEM_WIDTH_B - 1:0] mem_B_out;

	wire [STDP_WIN_BIT_WIDTH - 1:0] mem_LTP_WIN_out, mem_LTD_WIN_out;
	wire [DSIZE - 1:0]	mem_LTP_LrnRt_out, mem_LTD_LrnRt_out;
	wire mem_LrnModeBias_out;
	wire mem_NurnType_out, mem_RandTh_out;
	wire [DSIZE - 1:0] mem_Th_Mask_out, mem_RstPot_out;
	wire [AER_BIT_WIDTH - 1:0] mem_SpikeAER_out;
	wire mem_C_out;

	reg [MEM_WIDTH_A - 1:0] latch_mem_A;
	reg [MEM_WIDTH_B - 1:0] latch_mem_B;
	reg latch_mem_C;
	reg rdEn_Config_A_delay, rdEn_Config_B_delay, rdEn_Config_C_delay;

//rdEn_Config_A_i, rdEn_Config_B_i and rdEn_Config_C_i are delayed 1 clock
	always @(posedge clk_i or negedge rst_n_i)
		if(rst_n_i == 1'b0)
			rdEn_Config_A_delay <= 1'b0;
		else
			rdEn_Config_A_delay <= rdEn_Config_A_i;

	always @(posedge clk_i or negedge rst_n_i)
		if(rst_n_i == 1'b0)
			rdEn_Config_B_delay <= 1'b0;
		else
			rdEn_Config_B_delay <= rdEn_Config_B_i;

	always @(posedge clk_i or negedge rst_n_i)
		if(rst_n_i == 1'b0)
			rdEn_Config_C_delay <= 1'b0;
		else
			rdEn_Config_C_delay <= rdEn_Config_C_i;
//latch
	always @(*)
		if (rdEn_Config_A_i == 1'b1)
			latch_mem_A <= {mem_LTP_WIN_out, mem_LTD_WIN_out, mem_LTP_LrnRt_out, mem_LTD_LrnRt_out, mem_LrnModeBias_out};
	
	always @(*)
		if (rdEn_Config_B_i == 1'b1)
			latch_mem_B <= {mem_NurnType_out, mem_RandTh_out, mem_Th_Mask_out, mem_RstPot_out, mem_SpikeAER_out};

	always @(*)
		if (rdEn_Config_C_i == 1'b1)
			latch_mem_C <= mem_C_out;

//port A memory -- {LTP_Win, LTD_Win, LTP_LrnRt, LTD_LrnRt, LrnModeBias}
//split mem_A into 5 memories
single_port_rom	#(.DATA_WIDTH(STDP_WIN_BIT_WIDTH), .ADDR_WIDTH(NURN_CNT_BIT_WIDTH), .INIT_FILE_PATH({SYNTH_PATH, DIR_ID, "/LTP_Win.mif"}), .SIM_FILE_PATH({SIM_PATH, DIR_ID, "/LTP_Win.txt"}))
				mem_LTP_WIN (.addr(Addr_Config_A_i), .clk(clk_i), .q(mem_LTP_WIN_out));

single_port_rom	#(.DATA_WIDTH(STDP_WIN_BIT_WIDTH), .ADDR_WIDTH(NURN_CNT_BIT_WIDTH), .INIT_FILE_PATH({SYNTH_PATH, DIR_ID, "/LTD_Win.mif"}), .SIM_FILE_PATH({SIM_PATH, DIR_ID, "/LTD_Win.txt"}))
				mem_LTD_WIN (.addr(Addr_Config_A_i), .clk(clk_i), .q(mem_LTD_WIN_out));

single_port_rom	#(.DATA_WIDTH(DSIZE), .ADDR_WIDTH(NURN_CNT_BIT_WIDTH), .INIT_FILE_PATH({SYNTH_PATH, DIR_ID, "/LTP_LrnRt.mif"}), .SIM_FILE_PATH({SIM_PATH, DIR_ID, "/LTP_LrnRt.txt"}))
				mem_LTP_LrnRt (.addr(Addr_Config_A_i), .clk(clk_i), .q(mem_LTP_LrnRt_out));

single_port_rom	#(.DATA_WIDTH(DSIZE), .ADDR_WIDTH(NURN_CNT_BIT_WIDTH), .INIT_FILE_PATH({SYNTH_PATH, DIR_ID, "/LTD_LrnRt.mif"}), .SIM_FILE_PATH({SIM_PATH, DIR_ID, "/LTD_LrnRt.txt"}))
				mem_LTD_LrnRt (.addr(Addr_Config_A_i), .clk(clk_i), .q(mem_LTD_LrnRt_out));

single_port_rom	#(.DATA_WIDTH(1), .ADDR_WIDTH(NURN_CNT_BIT_WIDTH), .INIT_FILE_PATH({SYNTH_PATH, DIR_ID, "/LrnModeBias.mif"}), .SIM_FILE_PATH({SIM_PATH, DIR_ID, "/LrnModeBias.txt"}))
				mem_LrnModeBias (.addr(Addr_Config_A_i), .clk(clk_i), .q(mem_LrnModeBias_out));

//port B memory -- {NurnType, RandTh, Th_Mask, RstPot, SpikeAER}

single_port_rom	#(.DATA_WIDTH(1), .ADDR_WIDTH(NURN_CNT_BIT_WIDTH), .INIT_FILE_PATH({SYNTH_PATH, DIR_ID, "/NurnType.mif"}), .SIM_FILE_PATH({SIM_PATH, DIR_ID, "/NurnType.txt"}))
				mem_NurnType (.addr(Addr_Config_B_i), .clk(clk_i), .q(mem_NurnType_out));

single_port_rom	#(.DATA_WIDTH(1), .ADDR_WIDTH(NURN_CNT_BIT_WIDTH), .INIT_FILE_PATH({SYNTH_PATH, DIR_ID, "/RandTh.mif"}), .SIM_FILE_PATH({SIM_PATH, DIR_ID, "/RandTh.txt"}))
				mem_RandTh (.addr(Addr_Config_B_i), .clk(clk_i), .q(mem_RandTh_out));

single_port_rom	#(.DATA_WIDTH(DSIZE), .ADDR_WIDTH(NURN_CNT_BIT_WIDTH), .INIT_FILE_PATH({SYNTH_PATH, DIR_ID, "/Th_Mask.mif"}), .SIM_FILE_PATH({SIM_PATH, DIR_ID, "/Th_Mask.txt"}))
				mem_Th_Mask (.addr(Addr_Config_B_i), .clk(clk_i), .q(mem_Th_Mask_out));

single_port_rom	#(.DATA_WIDTH(DSIZE), .ADDR_WIDTH(NURN_CNT_BIT_WIDTH), .INIT_FILE_PATH({SYNTH_PATH, DIR_ID, "/RstPot.mif"}), .SIM_FILE_PATH({SIM_PATH, DIR_ID, "/RstPot.txt"}))
				mem_RstPot (.addr(Addr_Config_B_i), .clk(clk_i), .q(mem_RstPot_out));

single_port_rom	#(.DATA_WIDTH(AER_BIT_WIDTH), .ADDR_WIDTH(NURN_CNT_BIT_WIDTH), .INIT_FILE_PATH({SYNTH_PATH, DIR_ID, "/SpikeAER.mif"}), .SIM_FILE_PATH({SIM_PATH, DIR_ID, "/SpikeAER.txt"}))
				mem_SpikeAER (.addr(Addr_Config_B_i), .clk(clk_i), .q(mem_SpikeAER_out));

//mem_C LrnModeWght
single_port_rom	#(.DATA_WIDTH(1), .ADDR_WIDTH(NURN_CNT_BIT_WIDTH + AXON_CNT_BIT_WIDTH), .INIT_FILE_PATH({SYNTH_PATH, DIR_ID, "/LrnModeWght.mif"}), .SIM_FILE_PATH({SIM_PATH, DIR_ID, "/LrnModeWght.txt"}))
				mem_C (.addr(Addr_Config_C_i), .clk(clk_i), .q(mem_C_out));

	//output bus splitting mem A
	assign LTP_Win_o 		= latch_mem_A[MEM_WIDTH_A-1 : MEM_WIDTH_A-STDP_WIN_BIT_WIDTH];
	assign LTD_Win_o 		= latch_mem_A[MEM_WIDTH_A-STDP_WIN_BIT_WIDTH-1 : MEM_WIDTH_A-2*STDP_WIN_BIT_WIDTH];
	assign LTP_LrnRt_o 		= latch_mem_A[MEM_WIDTH_A-2*STDP_WIN_BIT_WIDTH-1 : MEM_WIDTH_A-2*STDP_WIN_BIT_WIDTH-DSIZE];
	assign LTD_LrnRt_o 		= latch_mem_A[MEM_WIDTH_A-2*STDP_WIN_BIT_WIDTH-DSIZE-1 : MEM_WIDTH_A-2*STDP_WIN_BIT_WIDTH-2*DSIZE];
	assign biasLrnMode_o 	= latch_mem_A[0];

	//output bus splitting mem B
	assign NurnType_o		= latch_mem_B[MEM_WIDTH_B-1];
	assign RandTh_o			= latch_mem_B[MEM_WIDTH_B-1-1];
	assign Th_Mask_o		= latch_mem_B[MEM_WIDTH_B-1-1-1 : MEM_WIDTH_B-1-1-DSIZE];
	assign RstPot_o			= latch_mem_B[MEM_WIDTH_B-1-1-DSIZE-1 : MEM_WIDTH_B-1-1-2*DSIZE];
	assign SpikeAER_o		= latch_mem_B[MEM_WIDTH_B-1-1-2*DSIZE-1 : 0];

	//output bus splitting mem C
	assign axonLrnMode_o 	= latch_mem_C;
	
endmodule
