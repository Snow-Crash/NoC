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
//2017.4.11 split mem_6 into two memory: mem_6 and mem_7. Because quartus doesn't support 3-port memory
//			mem_7 has the same content as mem_6. Verified and works OK.
//2017.4.15 mem 6 is a three port memory, which is not supported by cyclone v. 
//			split mem_6 into two memory can solve this problem but wastes a lot resource.
//			use a fifo to solve it. fifo's input connects to output of mem_6,
//			fifo's output connects to memOut_F_fifo, and assign memOut_F_fifo to output port data_StatRd_F_o,
//			hence memOutReg_F is removed.
//			if rdEn_StatRd_E_i == 1'b1, output of mem_6 is pushed into fifo.
//			if rdEn_StatRd_F_i == 1'b1, read from fifo and output to output port data_StatRd_F_o
//			tested, in learn mode works ok.
//2017.4.17 rewrite entire status memory because quartus cannot infer ram coorecly.
//			This one works fine, tested recall mode and compared with original version. 
//			spike results are the same. 
//2017.4.24 add two parameter SYNTH_PATH and SIM_PATH.
//2017.4.30 add reset to memOutReg_C of memory5. Doesn't affect timing and function.
//			Need to verify if it can be synthesized as RAM.
//2017.9.7  Add input expired_post_history_write_back_i, which comes from controller.
//			It determines memory port b mux select signal. When it's 1, select post history.
//2017.9.16 Revert changed made on 9.16. Changed controller, so controller can generate right address and select signal.

//todo		fifo clear signal: it is not mandatory. if use async signal, and if it's cleared,
//			output of fifo is red line. Need to test sync clear.
//			need to test learn mode.

//`timescale 1ns/100ps

`define SIM_MEM_INIT
`define NULL 0
`define DUMP_MEMORY

module StatusMem
#(
	`ifdef DUMP_MEMORY
		parameter STOP_STEP = 5,
	`endif
	parameter NUM_NURNS    = 256  ,
	parameter NUM_AXONS    = 256  ,

	parameter DSIZE    = 16 ,

	parameter NURN_CNT_BIT_WIDTH   = 8 ,
	parameter AXON_CNT_BIT_WIDTH   = 8 ,

	parameter STDP_WIN_BIT_WIDTH = 8,

	
	parameter X_ID = "1",
	parameter Y_ID = "1",
	parameter DIR_ID = {X_ID, "_", Y_ID},
	parameter SIM_PATH = "D:/code/data",
	parameter SYNTH_PATH = "D:/code/synth/data",

	parameter BIAS_MIF_PATH = {SYNTH_PATH, DIR_ID, "/Bias.mif"},
	parameter MEMBPOT_MIF_PATH = {SYNTH_PATH, DIR_ID, "/MembPot.mif"},
	parameter TH_MIF_PATH ={SYNTH_PATH, DIR_ID, "/Th.mif"},
	parameter POSTSPIKEHISTORY_MIF_PATH ={SYNTH_PATH, DIR_ID, "/PostSpikeHistory.mif"},
	parameter PRESPIKEHISTORY_MIF_PATH = {SYNTH_PATH, DIR_ID, "/PreSpikeHistory.mif"},
	parameter WEIGHTS_MIF_PATH = {SYNTH_PATH, DIR_ID, "/Weights.mif"}
	
)
(
	`ifdef DUMP_MEMORY
		input start_i,
	`endif
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
	`ifdef SIM_MEM_INIT
		reg [DSIZE-1:0] 			 Mem_1 [0:NUM_NURNS-1];
		reg [DSIZE-1:0] 			 Mem_2 [0:NUM_NURNS-1];
		reg [DSIZE-1:0] 			 Mem_3 [0:NUM_NURNS-1];
		reg [STDP_WIN_BIT_WIDTH-1:0] Mem_4 [0:NUM_NURNS-1];
		reg [STDP_WIN_BIT_WIDTH-1:0] Mem_5 [0:NUM_NURNS*NUM_AXONS-1];
		reg [DSIZE-1:0] 			 Mem_6 [0:NUM_NURNS*NUM_AXONS-1];
	`else
		(* ram_init_file = BIAS_MIF_PATH *) reg [DSIZE-1:0] 			 Mem_1 [0:NUM_NURNS-1];
		(* ram_init_file = MEMBPOT_MIF_PATH *) reg [DSIZE-1:0] 			 Mem_2 [0:NUM_NURNS-1];
		(* ram_init_file = TH_MIF_PATH *) reg [DSIZE-1:0] 			 Mem_3 [0:NUM_NURNS-1];
		(* ram_init_file = POSTSPIKEHISTORY_MIF_PATH *) reg [STDP_WIN_BIT_WIDTH-1:0] Mem_4 [0:NUM_NURNS-1];
		(* ram_init_file = PRESPIKEHISTORY_MIF_PATH *) reg [STDP_WIN_BIT_WIDTH-1:0] Mem_5 [0:NUM_NURNS*NUM_AXONS-1];
		(* ram_init_file = WEIGHTS_MIF_PATH *) reg [DSIZE-1:0] 			 Mem_6 [0:NUM_NURNS*NUM_AXONS-1];
	`endif
	//REGISTER DECLARATION
	//--------------------------------------------------//
	reg [DSIZE-1:0] 			 memOutReg_A;
	reg [STDP_WIN_BIT_WIDTH-1:0] memOutReg_C;
	reg [DSIZE-1:0] 			 memOutReg_E;
	reg [DSIZE-1:0] 			 memOutReg_F;
	wire [DSIZE-1:0]			memOut_F_fifo;
	//WIRE DECLARATION
	//--------------------------------------------------//
	wire [NURN_CNT_BIT_WIDTH+2-1:2] Addr_A_Mem1_4 ;
	wire [1:0] 						Sel_A_Mem1_4  ;
	wire [NURN_CNT_BIT_WIDTH+2-1:2] Addr_B_Mem1_4 ;
	wire [1:0] 						Sel_B_Mem1_4  ;	
	//--------------------------------------------------//
	reg Wr_En_Mem_1,  Wr_En_Mem_2,  Wr_En_Mem_3,  Wr_En_Mem_4;
	reg [DSIZE-1:0] memOutReg_A_1, memOutReg_A_2, memOutReg_A_3, memOutReg_A_4;
// synthesis translate_off
	//simulation memory data initialization
	//--------------------------------------------------//
	
	`ifdef SIM_MEM_INIT
		reg [100*8:1] file_name;
		initial begin
			file_name = {SIM_PATH, DIR_ID, "/Bias.txt"};				$readmemh (file_name,Mem_1);
			file_name = {SIM_PATH, DIR_ID, "/MembPot.txt"};			$readmemh (file_name,Mem_2);
			file_name = {SIM_PATH, DIR_ID, "/Th.txt"};				$readmemh (file_name,Mem_3);
			file_name = {SIM_PATH, DIR_ID, "/PostSpikeHistory.txt"};	$readmemh (file_name,Mem_4);
			file_name = {SIM_PATH, DIR_ID, "/PreSpikeHistory.txt"};	$readmemh (file_name,Mem_5);
			file_name = {SIM_PATH, DIR_ID, "/Weights.txt"};			$readmemh (file_name,Mem_6);
			//file_name = {"../data", DIR_ID, "/Weights.txt"};			$readmemh (file_name,Mem_7);
		end
	`endif
// synthesis translate_on

	//LOGIC
	//--------------------------------------------------//

	assign Addr_A_Mem1_4 = Addr_StatRd_A_i[NURN_CNT_BIT_WIDTH+2-1:2];
	assign Sel_A_Mem1_4  = Addr_StatRd_A_i[1:0];
	assign Addr_B_Mem1_4 = Addr_StatWr_B_i[NURN_CNT_BIT_WIDTH+2-1:2];
	assign Sel_B_Mem1_4  = Addr_StatWr_B_i[1:0];



	//Mem_1, Mem_2, Mem_3, Mem_4 Write_enable signal

	always @(*)
		begin
		  	if(wrEn_StatWr_B_i == 1'b1) 
				begin
					case (Sel_B_Mem1_4)
						2'b00: 
							begin
								Wr_En_Mem_1 = 1'b1;
								Wr_En_Mem_2 = 1'b0; 
								Wr_En_Mem_3 = 1'b0; 
								Wr_En_Mem_4 = 1'b0;
							end
						2'b01: 
							begin
								Wr_En_Mem_1 = 1'b0; 
								Wr_En_Mem_2 = 1'b1; 
								Wr_En_Mem_3 = 1'b0; 
								Wr_En_Mem_4 = 1'b0;
							end
						2'b10: 
							begin
								Wr_En_Mem_1 = 1'b0; 
								Wr_En_Mem_2 = 1'b0; 
								Wr_En_Mem_3 = 1'b1; 
								Wr_En_Mem_4 = 1'b0;
							end
						default: 
							begin//2'b11
								Wr_En_Mem_1 = 1'b0; 
								Wr_En_Mem_2 = 1'b0; 
								Wr_En_Mem_3 = 1'b0; 
								Wr_En_Mem_4 = 1'b1;
							end
					endcase
		        end
            else
                begin
                    Wr_En_Mem_1 = 1'b0; Wr_En_Mem_2 = 1'b0; Wr_En_Mem_3 = 1'b0; Wr_En_Mem_4 = 1'b0;
                end
	    end

	//-----------------------Mem_1---------------------------
	//						Mem_1 (0x00) - Bias
	always @ (posedge clk_i)
	begin
		if (Wr_En_Mem_1)
			Mem_1[Addr_B_Mem1_4] <= data_StatWr_B_i;
		//if (rdEn_StatRd_A_i == 1'b1)
			memOutReg_A_1 <= Mem_1[Addr_A_Mem1_4];
	end

	//-----------------------Mem_2---------------------------
	//						Mem_2 (0x01) - MembPot

	always @ (posedge clk_i)
	begin
		if (Wr_En_Mem_2)
			Mem_2[Addr_B_Mem1_4] <= data_StatWr_B_i;
		//if (rdEn_StatRd_A_i == 1'b1)
			memOutReg_A_2 <= Mem_2[Addr_A_Mem1_4];
	end

	//-----------------------Mem_3---------------------------
	//						Mem_3 (0x10) - Th
	//reg [DSIZE-1:0] memOutReg_A_3;
	always @ (posedge clk_i)
	begin
		if (Wr_En_Mem_3)
			Mem_3[Addr_B_Mem1_4] <= data_StatWr_B_i;
		//if (rdEn_StatRd_A_i == 1'b1)
			memOutReg_A_3 <= Mem_3[Addr_A_Mem1_4];
	end

	//-----------------------Mem_4---------------------------
	//						Mem_4 (0x11) - PostSpikeHist
	//reg [DSIZE-1:0] memOutReg_A_4;
	always @ (posedge clk_i)
	begin
		if (Wr_En_Mem_4)
			Mem_4[Addr_B_Mem1_4] <= data_StatWr_B_i;
		//if (rdEn_StatRd_A_i == 1'b1)
			memOutReg_A_4 <= Mem_4[Addr_A_Mem1_4];
	end
	//-----------------MUX memOutReg_A----------------
	always @(posedge clk_i)
	begin
		if (rdEn_StatRd_A_i == 1'b1) begin
		case (Sel_A_Mem1_4)
	        2'b00: begin
	        	memOutReg_A = memOutReg_A_1 ;//Bias
	        end
	        2'b01: begin
	        	memOutReg_A = memOutReg_A_2 ;//MembPot
	        end
	        2'b10: begin
	        	memOutReg_A = memOutReg_A_3 ;//Th
	        end
	        default: begin//2'b11
	        	memOutReg_A = memOutReg_A_4 ;//PostSpikeHist
	        end
		endcase
		end
	end

	//--------------------------Mem_5------------
	//						Mem_5 - PreSpikeHistory
	always @ (posedge clk_i or negedge rst_n_i)
	begin
		if (wrEn_StatWr_D_i == 1'b1)
			Mem_5[Addr_StatWr_D_i] <= data_StatWr_D_i;
		if (rst_n_i == 1'b0)
			memOutReg_C <= 0;
		else if(rdEn_StatRd_C_i == 1'b1)
			memOutReg_C <= Mem_5[Addr_A_Mem1_4];
	end
	//-------------------------Mem_6
	//						Mem_6 - Weights
	always @ (posedge clk_i)
	begin
		if (wrEn_StatWr_G_i == 1'b1)
			Mem_6[Addr_StatWr_G_i] <= data_StatWr_G_i;
		if(rdEn_StatRd_E_i == 1'b1)
			memOutReg_E <= Mem_6[Addr_StatRd_E_i];
	end

	reg weight_fifo_WrReq;
	wire [2:0] usedw;
	wire weight_fifo_full, weight_fifo_empty;

	always @(posedge clk_i or negedge rst_n_i)
		begin
			if (rst_n_i == 1'b0)
				weight_fifo_WrReq <= 1'b0;
			else
				weight_fifo_WrReq <= rdEn_StatRd_E_i;
		end

	weight_fifo	weight_fifo_inst (
	.aclr ( 1'b0),
	.clock ( clk_i ),
	.data ( memOutReg_E ),
	.rdreq ( rdEn_StatRd_F_i),
	.wrreq ( weight_fifo_WrReq ),
	.empty ( weight_fifo_empty ),
	.full ( weight_fifo_full ),
	.q ( memOut_F_fifo ),
	.usedw ( usedw )
	);

	assign data_StatRd_A_o = memOutReg_A;
	assign data_StatRd_C_o = memOutReg_C;
	assign data_StatRd_E_o = memOutReg_E;
	assign data_StatRd_F_o = memOut_F_fifo;


//dump memory contents
`ifdef DUMP_MEMORY

	//counter
	integer clock_counter;
	integer step_counter;

	initial
		begin
			clock_counter = 0;
			step_counter = 0;
		end

	always @(posedge clk_i)
		clock_counter = clock_counter + 1;
	
	always @(posedge clk_i)
		if (start_i == 1'b1)
			step_counter = step_counter + 1;

	//file output
	integer f1, f2, f3, f4, f5, f6, i;
	initial
		begin
			f1 = $fopen("Bias.txt","w");
			f2 = $fopen("MembPot.txt","w");
			f3 = $fopen("Threshold.txt","w");
			f4 = $fopen("PostHist.txt","w");
			f5 = $fopen("PreHist.txt","w");
			f6 = $fopen("Weights.txt","w");
			//write header
			$fwrite(f1, "step,");
			$fwrite(f2, "step,");
			$fwrite(f3, "step,");
			$fwrite(f4, "step,");
			$fwrite(f5, "step,");
			$fwrite(f6, "step,");
			for (i = 0; i < NUM_NURNS; i = i+1)
				begin
					$fwrite(f1, "%h,", i);			//address
					$fwrite(f2, "%h,", i);			//address
					$fwrite(f3, "%h,", i);			//address
					$fwrite(f4, "%h,", i);			//address
				end

			for (i = 0; i < NUM_NURNS * NUM_AXONS; i = i+1)
				begin
					$fwrite(f5, "%h,", i);			//address
					$fwrite(f6, "%h,", i);			//address
				end
			$fwrite(f1, "\n");
			$fwrite(f2, "\n");
			$fwrite(f3, "\n");
			$fwrite(f4, "\n");
			$fwrite(f5, "\n");
			$fwrite(f6, "\n");
		end

	always @(posedge clk_i)
		begin
			if (step_counter < STOP_STEP)
				begin
					if (start_i == 1'b1)
						begin
							//dump bias
							$fwrite(f1, "%0d,",step_counter);
							for (i = 0; i < NUM_NURNS; i = i+1)
								begin
									//$fwrite(f1, "%h:", i);			//address
									$fwrite(f1, "%h,", Mem_1[i]);	//every word
								end
								$fwrite(f1, "\n");
							//dump membpot
							$fwrite(f2, "%0d,",step_counter);
							for (i = 0; i < NUM_NURNS; i = i + 1)
								begin
									//$fwrite(f2, "%h:", i);			//address
									$fwrite(f2, "%h,", Mem_2[i]);	//word
								end
							$fwrite(f2, "\n");
							//Threshold
							$fwrite(f3, "%0d,",step_counter);
							for (i = 0; i < NUM_NURNS; i = i+1)
								begin
									//$fwrite(f3, "%h:",i);
									$fwrite(f3, "%h,", Mem_3[i]);
								end
							$fwrite(f3, "\n");
							//Post synaptic history
							$fwrite(f4, "%0d,",step_counter);
							for (i = 0; i < NUM_NURNS; i = i+1)
								begin
									//$fwrite(f4, "%h:",i);
									$fwrite(f4, "%h,", Mem_4[i]);
								end
							$fwrite(f4, "\n");
							//Pre synaptic history
							$fwrite(f5, "%0d,",step_counter);
							for (i = 0; i < NUM_NURNS * NUM_AXONS; i = i+1)
								begin
									//$fwrite(f5, "%h:",i);
									$fwrite(f5, "%h,", Mem_5[i]);
								end
							$fwrite(f5, "\n");
							//Weights
							$fwrite(f6, "%0d,",step_counter);
							for (i = 0; i < NUM_NURNS * NUM_AXONS; i = i+1)
								begin
									//$fwrite(f6, "%h:",i);
									$fwrite(f6, "%h,", Mem_6[i]);
								end
							$fwrite(f6, "\n");
						end
				end
			else
				begin
					$fclose(f1);
					$fclose(f2);
					$fclose(f3);
					$fclose(f4);
					$fclose(f5);
					$fclose(f6);
				end
		end

			

`endif
	
endmodule
