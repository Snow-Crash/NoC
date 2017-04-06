//------------------------------------------------------------------------
// Title       : status memory
// Version     : 0.1
// Author      : Khadeer Ahmed
// Date created: 12/9/2016
// -----------------------------------------------------------------------
// Discription : 
//					port A,B
//						Mem_1 (0x00) - Bias
//						Mem_2 (0x01) - MembPot
//						Mem_3 (0x10) - Th
//						Mem_4 (0x11) - PostSpikeHist
//					port C,D
//						Mem_5 - PreSpikeHistory
//					port E,F,G
//						Mem_6 - Weights
// -----------------------------------------------------------------------
// Maintainance History
// -ver x.x : date : auth
//		details
//------------------------------------------------------------------------
//2017.4.1  localparam cause error in quartus, unkown reason

`timescale 1ns/100ps

`define SIM_MEM_INIT
`define NULL 0

module StatusMem
#(
	parameter NUM_NURNS    = 256  ,
	parameter NUM_AXONS    = 256  ,

	parameter DSIZE    = 16 ,

	parameter NURN_CNT_BIT_WIDTH   = 8 ,
	parameter AXON_CNT_BIT_WIDTH   = 8 ,

	parameter STDP_WIN_BIT_WIDTH = 8,

	
	parameter X_ID = "1",
	parameter Y_ID = "1",
	parameter DIR_ID = {X_ID, "_", Y_ID}
)
(
	input 			clk_i			,
	input 			rst_n_i			,

	//read port A
	input [NURN_CNT_BIT_WIDTH+2-1:0] 					Addr_StatRd_A_i,
	input 												rdEn_StatRd_A_i,

	output [DSIZE-1:0]									data_StatRd_A_o,

	//write port B
	input [NURN_CNT_BIT_WIDTH+2-1:0] 					Addr_StatWr_B_i,
	input 												wrEn_StatWr_B_i,
	input [DSIZE-1:0]									data_StatWr_B_i,
	
	//read port C
	input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	Addr_StatRd_C_i,
	input 												rdEn_StatRd_C_i,

	output [STDP_WIN_BIT_WIDTH-1:0]						data_StatRd_C_o,

	//write port D
	input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	Addr_StatWr_D_i,
	input 												wrEn_StatWr_D_i,
	input [STDP_WIN_BIT_WIDTH-1:0]						data_StatWr_D_i,
	
	//read port E
	input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	Addr_StatRd_E_i,
	input 												rdEn_StatRd_E_i,

	output [DSIZE-1:0]									data_StatRd_E_o,
	
	//read port F
	input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	Addr_StatRd_F_i,
	input 												rdEn_StatRd_F_i,

	output [DSIZE-1:0]									data_StatRd_F_o,

	//write port G
	input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	Addr_StatWr_G_i,
	input 												wrEn_StatWr_G_i,
	input [DSIZE-1:0]									data_StatWr_G_i
);
	
	

	//MEMORY DECLARATION
	//--------------------------------------------------//
	reg [DSIZE-1:0] 			 Mem_1 [0:NUM_NURNS-1];
	reg [DSIZE-1:0] 			 Mem_2 [0:NUM_NURNS-1];
	reg [DSIZE-1:0] 			 Mem_3 [0:NUM_NURNS-1];
	reg [STDP_WIN_BIT_WIDTH-1:0] Mem_4 [0:NUM_NURNS-1];
	reg [STDP_WIN_BIT_WIDTH-1:0] Mem_5 [0:NUM_NURNS*NUM_AXONS-1];
	reg [DSIZE-1:0] 			 Mem_6 [0:NUM_NURNS*NUM_AXONS-1];

	//REGISTER DECLARATION
	//--------------------------------------------------//
	reg [DSIZE-1:0] 			 memOutReg_A;
	reg [STDP_WIN_BIT_WIDTH-1:0] memOutReg_C;
	reg [DSIZE-1:0] 			 memOutReg_E;
	reg [DSIZE-1:0] 			 memOutReg_F;

	//WIRE DECLARATION
	//--------------------------------------------------//
	wire [NURN_CNT_BIT_WIDTH+2-1:2] Addr_A_Mem1_4 ;
	wire [1:0] 						Sel_A_Mem1_4  ;
	wire [NURN_CNT_BIT_WIDTH+2-1:2] Addr_B_Mem1_4 ;
	wire [1:0] 						Sel_B_Mem1_4  ;	
// synthesis translate_off
	//simulation memory data initialization
	//--------------------------------------------------//
	
	`ifdef SIM_MEM_INIT
		reg [100*8:1] file_name;
		initial begin
			file_name = {"../data", DIR_ID, "/Bias.txt"};				$readmemh (file_name,Mem_1);
			file_name = {"../data", DIR_ID, "/MembPot.txt"};			$readmemh (file_name,Mem_2);
			file_name = {"../data", DIR_ID, "/Th.txt"};				$readmemh (file_name,Mem_3);
			file_name = {"../data", DIR_ID, "/PostSpikeHistory.txt"};	$readmemh (file_name,Mem_4);
			file_name = {"../data", DIR_ID, "/PreSpikeHistory.txt"};	$readmemh (file_name,Mem_5);
			file_name = {"../data", DIR_ID, "/Weights.txt"};			$readmemh (file_name,Mem_6);
		end
	`endif
// synthesis translate_off	

	//LOGIC
	//--------------------------------------------------//

	assign Addr_A_Mem1_4 = Addr_StatRd_A_i[NURN_CNT_BIT_WIDTH+2-1:2];
	assign Sel_A_Mem1_4  = Addr_StatRd_A_i[1:0];
	assign Addr_B_Mem1_4 = Addr_StatWr_B_i[NURN_CNT_BIT_WIDTH+2-1:2];
	assign Sel_B_Mem1_4  = Addr_StatWr_B_i[1:0];

	// Read status Memory
	always@(posedge clk_i or negedge rst_n_i)  begin
		if(rst_n_i == 1'b0) begin
			memOutReg_A	<= 0;
			memOutReg_C	<= 0;
			memOutReg_E	<= 0;    
			memOutReg_F	<= 0;    
	  	end
	  	else begin
	  		if(rdEn_StatRd_A_i == 1'b1) begin
	  			case (Sel_A_Mem1_4)
	        		2'b00: begin
	        			memOutReg_A   <=  Mem_1[Addr_A_Mem1_4] ;
	        		end
	        		2'b01: begin
	        			memOutReg_A   <=  Mem_2[Addr_A_Mem1_4] ;
	        		end
	        		2'b10: begin
	        			memOutReg_A   <=  Mem_3[Addr_A_Mem1_4] ;
	        		end
	        		default: begin//2'b11
	        			memOutReg_A   <=  Mem_4[Addr_A_Mem1_4] ;
	        		end
	        	endcase
        	end

        	if(rdEn_StatRd_C_i == 1'b1) begin
	        	memOutReg_C   <=  Mem_5[Addr_StatRd_C_i];
        	end

        	if(rdEn_StatRd_E_i == 1'b1) begin
	        	memOutReg_E   <=  Mem_6[Addr_StatRd_E_i];
        	end

        	if(rdEn_StatRd_F_i == 1'b1) begin
	        	memOutReg_F   <=  Mem_6[Addr_StatRd_F_i];
        	end
	  	end
	end

	//write status memory
	always @(posedge clk_i) begin
		if (wrEn_StatWr_B_i == 1'b1) begin
			case (Sel_B_Mem1_4)
        		2'b00: begin
        			Mem_1[Addr_B_Mem1_4] <= data_StatWr_B_i;
        		end
        		2'b01: begin
        			Mem_2[Addr_B_Mem1_4] <= data_StatWr_B_i;
        		end
        		2'b10: begin
        			Mem_3[Addr_B_Mem1_4] <= data_StatWr_B_i;
        		end
        		default: begin//2'b11
        			Mem_4[Addr_B_Mem1_4] <= data_StatWr_B_i;
        		end
        	endcase
		end
		if (wrEn_StatWr_D_i == 1'b1) begin
			Mem_5[Addr_StatWr_D_i] <= data_StatWr_D_i;
		end
		if (wrEn_StatWr_G_i == 1'b1) begin
			Mem_6[Addr_StatWr_G_i] <= data_StatWr_G_i;
		end
	end

	assign data_StatRd_A_o = memOutReg_A;
	assign data_StatRd_C_o = memOutReg_C;
	assign data_StatRd_E_o = memOutReg_E;
	assign data_StatRd_F_o = memOutReg_F;
	
endmodule
