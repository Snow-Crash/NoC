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
	parameter MEM_A_MIF_PATH = "D:/code/synth/data1_1/mem_A.mif",
	parameter MEM_B_MIF_PATH = "D:/code/synth/data1_1/mem_B.mif",
	parameter MEM_C_MIF_PATH = "D:/code/synth/data1_1/mem_C.mif"

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

	//MEMORY DECLARATION
	//--------------------------------------------------//
	`ifdef SIM_MEM_INIT
		reg [MEM_WIDTH_A-1:0] mem_A [0:NUM_NURNS-1];
		reg [MEM_WIDTH_B-1:0] mem_B [0:NUM_NURNS-1];
		reg 				  mem_C [0:NUM_NURNS*NUM_AXONS-1];
	`else
		(* ram_init_file = MEM_A_MIF_PATH *) reg [MEM_WIDTH_A-1:0] mem_A [0:NUM_NURNS-1];
		(* ram_init_file = MEM_B_MIF_PATH *) reg [MEM_WIDTH_B-1:0] mem_B [0:NUM_NURNS-1];
		(* ram_init_file = MEM_C_MIF_PATH *) reg 				  mem_C [0:NUM_NURNS*NUM_AXONS-1];
	`endif

	//REGISTER DECLARATION
	//--------------------------------------------------//
	reg [MEM_WIDTH_A-1:0] memOutReg_A/* synthesis preserve */;
	reg [MEM_WIDTH_B-1:0] memOutReg_B/* synthesis preserve */;
	reg 				  memOutReg_C/* synthesis preserve */;
// synthesis translate_off
	//simulation memory data initialization
	//--------------------------------------------------//
	
	`ifdef SIM_MEM_INIT
		integer file1, file2, file3, file4, file5, idx;
		reg [100*8:1] file_name;
		reg [STDP_WIN_BIT_WIDTH-1:0] data_S1, data_S2;
		reg [DSIZE-1:0] data_D1, data_D2;
		reg data_B1, data_B2;
		reg [AER_BIT_WIDTH-1:0] data_A1;
			
		initial begin

			// initialize mem_A
			file_name = {"../data", DIR_ID, "/LTP_Win.txt"}; 		file1 = $fopen(file_name, "r+");
			if (file1 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end
			file_name = {"../data", DIR_ID, "/LTD_Win.txt"}; 		file2 = $fopen(file_name, "r+");
			if (file2 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end
			file_name = {"../data", DIR_ID, "/LTP_LrnRt.txt"}; 	file3 = $fopen(file_name, "r+");
			if (file3 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end
			file_name = {"../data", DIR_ID, "/LTD_LrnRt.txt"}; 	file4 = $fopen(file_name, "r+");
			if (file4 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end
			file_name = {"../data", DIR_ID, "/LrnModeBias.txt"}; 	file5 = $fopen(file_name, "r+");
			if (file5 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end

			for(idx = 0 ; idx <= (NUM_NURNS - 1) ; idx = idx + 1)
			begin
				$fscanf (file1, "%h\n", data_S1);
				$fscanf (file2, "%h\n", data_S2);
				$fscanf (file3, "%h\n", data_D1);
				$fscanf (file4, "%h\n", data_D2);
				$fscanf (file5, "%h\n", data_B1);
				mem_A[idx]   =  {data_S1,data_S2,data_D1,data_D2,data_B1};
			end
		
			$fclose(file1);
			$fclose(file2);
			$fclose(file3);
			$fclose(file4);
			$fclose(file5);
			//-----------------------------

			// initialize mem_B
			file_name = {"../data", DIR_ID, "/NurnType.txt"}; 	file1 = $fopen(file_name, "r+");
			if (file1 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end
			file_name = {"../data", DIR_ID, "/RandTh.txt"}; 		file2 = $fopen(file_name, "r+");
			if (file1 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end
			file_name = {"../data", DIR_ID, "/Th_Mask.txt"}; 		file3 = $fopen(file_name, "r+");
			if (file2 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end
			file_name = {"../data", DIR_ID, "/RstPot.txt"};	 	file4 = $fopen(file_name, "r+");
			if (file3 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end
			file_name = {"../data", DIR_ID, "/SpikeAER.txt"};	 	file5 = $fopen(file_name, "r+");
			if (file4 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end

			for(idx = 0 ; idx <= (NUM_NURNS - 1) ; idx = idx + 1)
			begin
				$fscanf (file1, "%h\n", data_B1);
				$fscanf (file2, "%h\n", data_B2);
				$fscanf (file3, "%h\n", data_D1);
				$fscanf (file4, "%h\n", data_D2);
				$fscanf (file5, "%h\n", data_A1);
				mem_B[idx]   =  {data_B1,data_B2,data_D1,data_D2,data_A1};
			end
		
			$fclose(file1);
			$fclose(file2);
			$fclose(file3);
			$fclose(file4);
			$fclose(file5);
			//-----------------------------
			
			// initialize mem_C
			file_name = {"../data", DIR_ID, "/LrnModeWght.txt"};
			$readmemh (file_name,mem_C);
			//-----------------------------
				
		end
	`endif
// synthesis translate_on

	//LOGIC
	//--------------------------------------------------//
	// Read configuration Memory
	always@(posedge clk_i or negedge rst_n_i)  begin
		if(rst_n_i == 1'b0) begin
			memOutReg_A    <=  0   ;
			memOutReg_B   <=  0 ;
			memOutReg_C    <=  0;    
	  	end
	  	else begin
	  		if(rdEn_Config_A_i == 1'b1) begin
	        	memOutReg_A   <=  mem_A[Addr_Config_A_i] ;
        	end

        	if(rdEn_Config_B_i == 1'b1) begin
	        	memOutReg_B <= mem_B[Addr_Config_B_i] ;
  			end

  			if(rdEn_Config_C_i == 1'b1) begin
				memOutReg_C    <=   mem_C[Addr_Config_C_i] ;    
			end
	  	end
	end

	//output bus splitting mem A
	assign LTP_Win_o 		= memOutReg_A[MEM_WIDTH_A-1 : MEM_WIDTH_A-STDP_WIN_BIT_WIDTH];
	assign LTD_Win_o 		= memOutReg_A[MEM_WIDTH_A-STDP_WIN_BIT_WIDTH-1 : MEM_WIDTH_A-2*STDP_WIN_BIT_WIDTH];
	assign LTP_LrnRt_o 		= memOutReg_A[MEM_WIDTH_A-2*STDP_WIN_BIT_WIDTH-1 : MEM_WIDTH_A-2*STDP_WIN_BIT_WIDTH-DSIZE];
	assign LTD_LrnRt_o 		= memOutReg_A[MEM_WIDTH_A-2*STDP_WIN_BIT_WIDTH-DSIZE-1 : MEM_WIDTH_A-2*STDP_WIN_BIT_WIDTH-2*DSIZE];
	assign biasLrnMode_o 	= memOutReg_A[0];

	//output bus splitting mem B
	assign NurnType_o		= memOutReg_B[MEM_WIDTH_B-1];
	assign RandTh_o			= memOutReg_B[MEM_WIDTH_B-1-1];
	assign Th_Mask_o		= memOutReg_B[MEM_WIDTH_B-1-1-1 : MEM_WIDTH_B-1-1-DSIZE];
	assign RstPot_o			= memOutReg_B[MEM_WIDTH_B-1-1-DSIZE-1 : MEM_WIDTH_B-1-1-2*DSIZE];
	assign SpikeAER_o		= memOutReg_B[MEM_WIDTH_B-1-1-2*DSIZE-1 : 0];

	//output bus splitting mem C
	assign axonLrnMode_o 	= memOutReg_C;
	
endmodule
