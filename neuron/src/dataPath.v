//------------------------------------------------------------------------
// Title       : data path
// Version     : 0.1
// Author      : Khadeer Ahmed
// Date created: 12/13/2016
// -----------------------------------------------------------------------
// Discription : data path for the neuron
// NurnTyp_i: 0: I&F
//			  1: ReLU
// NOTE:
// 		the priority quantization is not parameterized. if integer/fraction
// 		data  width is greater than 32 bits then additional entries in the 
// 		quantization LUT must be added
// -----------------------------------------------------------------------
// Maintainance History
// -ver x.x : date : auth
//		details
//------------------------------------------------------------------------

`timescale 1ns/100ps

module dataPath
#(
	parameter NUM_NURNS    = 256  ,
	parameter NUM_AXONS    = 256  ,

	parameter DATA_BIT_WIDTH_INT    = 8 ,
	parameter DATA_BIT_WIDTH_FRAC   = 8 ,

	parameter NURN_CNT_BIT_WIDTH   = 8 ,
	parameter AXON_CNT_BIT_WIDTH   = 8 ,

	parameter STDP_WIN_BIT_WIDTH = 8 ,
	
	parameter AER_BIT_WIDTH = 32 ,

	parameter PRIORITY_ENC_OUT_BIT_WIDTH = 3,

	parameter SEED = 0
)
(
	input 													clk_i			,
	input 													rst_n_i			,

	//config memory
	input  [DATA_BIT_WIDTH_INT+DATA_BIT_WIDTH_FRAC-1:0] 	RstPot_i		,
	input 													NurnType_i 		,
	input 													RandTh_i 		,
	input  [DATA_BIT_WIDTH_INT+DATA_BIT_WIDTH_FRAC-1:0] 	Th_Mask_i		,
	input  [STDP_WIN_BIT_WIDTH-1:0] 						LTP_Win_i		,
	input  [STDP_WIN_BIT_WIDTH-1:0] 						LTD_Win_i		,
	input  													axonLrnMode_i 	,
	input  [DATA_BIT_WIDTH_INT+DATA_BIT_WIDTH_FRAC-1:0] 	LTP_LrnRt_i		,
	input  [DATA_BIT_WIDTH_INT+DATA_BIT_WIDTH_FRAC-1:0] 	LTD_LrnRt_i		,

	//status memory
	input  [DATA_BIT_WIDTH_INT+DATA_BIT_WIDTH_FRAC-1:0] 	data_StatRd_A_i	,
	input  [STDP_WIN_BIT_WIDTH-1:0] 						data_StatRd_C_i	,
	input  [DATA_BIT_WIDTH_INT+DATA_BIT_WIDTH_FRAC-1:0] 	data_StatRd_E_i	,
	input  [DATA_BIT_WIDTH_INT+DATA_BIT_WIDTH_FRAC-1:0] 	data_StatRd_F_i	,

	output reg [DATA_BIT_WIDTH_INT+DATA_BIT_WIDTH_FRAC-1:0] data_StatWr_B_o	,
	output [STDP_WIN_BIT_WIDTH-1:0] 						data_StatWr_D_o	,
	output [DATA_BIT_WIDTH_INT+DATA_BIT_WIDTH_FRAC-1:0] 	data_StatWr_G_o	,

	//in spike buffer
	input 													rcl_inSpike_i	,
	input 													lrn_inSpike_i	,

	//Router
	output 													outSpike_o 		,

	//controller
	input 													rstAcc_i 		,
	input 													accEn_i 		,
	input 													cmp_th_i 		,
	input  [1:0]											sel_rclAdd_B_i 	,
	input  [1:0]											sel_wrBackStat_B_i,
	input 													buffMembPot_i 	,
	input 													updtPostSpkHist_i,
	input 													addLrnRt_i 		,
	input 													enQuant_i 		,
	input 													buffBias_i 		,
	input 													lrnUseBias_i 	,
	input 													cmpSTDP_i 		

);
	parameter DSIZE = DATA_BIT_WIDTH_INT + DATA_BIT_WIDTH_FRAC;

	//SELECT LINE ENCODING
	//--------------------------------------------------//
	//recall adder select lines
	parameter [1:0] RCL_ADD_B_WT       = 2'b00;
	parameter [1:0] RCL_ADD_B_BIAS     = 2'b01;
	parameter [1:0] RCL_ADD_B_MEMB_POT = 2'b10;
	parameter [1:0] RCL_ADD_B_NEG_TH   = 2'b11;

	//status port B writeback select lines
	parameter [1:0] WR_BACK_STAT_B_BIAS      = 2'b00;
	parameter [1:0] WR_BACK_STAT_B_MEMB_POT  = 2'b01;
	parameter [1:0] WR_BACK_STAT_B_TH        = 2'b10;
	parameter [1:0] WR_BACK_STAT_B_POST_HIST = 2'b11;

	//REGISTER DECLARATION
	//--------------------------------------------------//
	reg [DSIZE-1:0]	AccReg, rclAdd_A, rclAdd_B;
	reg [DSIZE-1:0]	bufMembPot, bufBias, bufTh;
	reg comp_out, lrnOutSpikeReg, enLTP, enLTD, expPreHist/* synthesis preserve */;
	reg [1:0] rclOutSpikeReg_dly, rdLFSR_dly/* synthesis noprune */;
	reg [STDP_WIN_BIT_WIDTH-1:0] PostSpkHist;
	reg [STDP_WIN_BIT_WIDTH-1:0] PreSpikeHist_Ppln[0:4] /* synthesis noprune */;
	reg [DSIZE-1:0] WeightBias_Ppln[0:2];
	reg [DSIZE-1:0] updtReg_WeightBias, delta_WtBias;
	reg [4:0] enLrn_Ppln;
	reg [DSIZE-1:0] eta_prime, sign_WtBias, quant_Dlta_Wt_Bias_reg/* synthesis noprune */;
	reg [DATA_BIT_WIDTH_INT-2:0] pEnc_in;
	reg shiftRight, shiftRight_dly, deltaAdder_signed;
	reg [PRIORITY_ENC_OUT_BIT_WIDTH-1:0] quantVal/* synthesis preserve */;
	reg [DSIZE-1:0] deltaAdder_inA, deltaAdder_inB;
	reg [STDP_WIN_BIT_WIDTH-1:0] preSpikeHist;
	reg valid_PreHist, lrnUseBias_dly;

	//WIRE DECLARATION
	//--------------------------------------------------//
	wire [DSIZE-1:0] lfsr_data, delta_WtBias_Th, quant_Dlta_Wt_Bias;
	wire [DSIZE:0] negTh, negWtBias, negDelta_WtBias;
	wire valid_PostHist, CorSpike;
	wire [DATA_BIT_WIDTH_INT-1:0] shifter_in_int;
	wire [DATA_BIT_WIDTH_FRAC-1:0] shifter_in_frac;
	wire [PRIORITY_ENC_OUT_BIT_WIDTH-1:0] pEnc_out;
	wire [DSIZE-1:0] updt_WeightBias, WtBias_in, accIn;
	wire [DSIZE-STDP_WIN_BIT_WIDTH-1:0] postSpike_pad;

	integer i;

	//LOGIC
	//--------------------------------------------------//

	//registers
	always @(posedge clk_i or negedge rst_n_i) begin
		if (rst_n_i == 1'b0) begin
			AccReg <= 0;
			bufMembPot <= 0;
			bufBias <= 0;
			rclOutSpikeReg_dly <= 2'b0;
			bufTh <= 0;
			lrnOutSpikeReg <= 0;
			rdLFSR_dly <= 2'b0;
			PostSpkHist <= 0;
		end else begin
			if (rstAcc_i == 1'b1) begin
				AccReg <= 0;
			end else if (accEn_i) begin
				AccReg <= accIn;
			end

			if (buffMembPot_i == 1'b1) begin
				bufMembPot <= AccReg;
			end

			if (buffBias_i == 1'b1) begin
				bufBias <= data_StatRd_A_i;
			end

			if (cmp_th_i == 1'b1) begin
				bufTh <= data_StatRd_A_i;
				rclOutSpikeReg_dly <= {comp_out,comp_out};
				lrnOutSpikeReg <= comp_out;
			end else begin
				rclOutSpikeReg_dly <= {1'b0,rclOutSpikeReg_dly[1]};
			end
			rdLFSR_dly <= {cmp_th_i,rdLFSR_dly[1]};

			//post spike history
			if (updtPostSpkHist_i == 1'b1) begin
				if (lrnOutSpikeReg == 1'b1) begin
					PostSpkHist <= 0;
				end else if (comp_out == 1'b1) begin
					PostSpkHist <= data_StatRd_A_i[STDP_WIN_BIT_WIDTH-1:0] + 1;
				end else begin
					PostSpkHist <= data_StatRd_A_i[STDP_WIN_BIT_WIDTH-1:0];
				end
			end
		end
	end
	assign outSpike_o = rclOutSpikeReg_dly[0] & (~rclOutSpikeReg_dly[1]);//generates a pulse
	
	//recall adder inputs
	assign negTh = (~data_StatRd_A_i) + 1;
	always @(*)	begin
		//port A
		rclAdd_A = AccReg;

		//Port B
		case (sel_rclAdd_B_i)
			RCL_ADD_B_WT      : rclAdd_B = (rcl_inSpike_i == 1'b1) ? data_StatRd_E_i : 0;
			RCL_ADD_B_BIAS    : rclAdd_B = data_StatRd_A_i;
			RCL_ADD_B_MEMB_POT: rclAdd_B = data_StatRd_A_i;
			default           : rclAdd_B = negTh[DSIZE-1:0];//RCL_ADD_B_NEG_TH
		endcase
	end

	// Comparator:
	// 1) Recall  : Compare Threshold & Accumulated MembPot
	// 2) Learning: Compare Post Synaptic Tracker and Pre Synaptic Tracker history
	//              to select LTP or LTD Learning Rate
	//              Based on LTP or LTD, Weight's 2's compliments will be used in learning Adder1  
	always@(*) begin
		comp_out  =  1'b0 ;
		if(cmp_th_i == 1'b1) begin
			if(AccReg >= data_StatRd_A_i) begin//change to 2's complement comparator
				comp_out  =  1'b1 ;
			end
		end

		if (updtPostSpkHist_i == 1'b1) begin
			if (data_StatRd_A_i[STDP_WIN_BIT_WIDTH-1:0] <= LTD_Win_i) begin
				comp_out  =  1'b1 ;
			end
		end
	end

	//writeback
	assign postSpike_pad = 0;
	always@(*) begin
		case(sel_wrBackStat_B_i)
			WR_BACK_STAT_B_BIAS: begin 
			 	data_StatWr_B_o = updtReg_WeightBias; 
			end
			WR_BACK_STAT_B_MEMB_POT: begin
				if (rclOutSpikeReg_dly[0] == 1'b1) begin
					if (NurnType_i == 1'b1) begin
						data_StatWr_B_o = AccReg;
					end else begin
						data_StatWr_B_o = RstPot_i;	
					end
				end else begin
					data_StatWr_B_o = bufMembPot;
				end
			end 
			WR_BACK_STAT_B_TH: begin
				data_StatWr_B_o = bufTh;
				if (rclOutSpikeReg_dly[0] == 1'b1) begin
					if (RandTh_i == 1'b1) begin
						data_StatWr_B_o = delta_WtBias_Th;	
					end
				end
			end
			default: begin //WR_BACK_STAT_B_POST_HIST
				data_StatWr_B_o = {postSpike_pad,PostSpkHist}; 
			end 
		endcase
	end
	assign data_StatWr_D_o = PreSpikeHist_Ppln[0];
	assign data_StatWr_G_o = updtReg_WeightBias;

	//DELTA_WT_BIAS_ADDER input mux
	always @ (*) begin
		case(sel_wrBackStat_B_i)
			WR_BACK_STAT_B_TH: begin
				deltaAdder_inA = (lfsr_data & Th_Mask_i);
				deltaAdder_inB = bufTh;
				deltaAdder_signed = 1'b0;
			end
			default: begin
				deltaAdder_inA = eta_prime;
				deltaAdder_inB = sign_WtBias;
				deltaAdder_signed = 1'b1;
			end
		endcase
	end

	//STDP tracking
	assign valid_PostHist = (PostSpkHist <= LTD_Win_i) ? 1'b1 : 1'b0;
	assign CorSpike = (preSpikeHist >= PostSpkHist) ? 1'b1 : 1'b0;//corelated spike
	always @ (*) begin
		
		if (lrn_inSpike_i == 1'b1) begin
			preSpikeHist = 0;
			valid_PreHist = 1'b1;
		end else begin
			if (data_StatRd_C_i > LTP_Win_i) begin
				preSpikeHist = data_StatRd_C_i;
				valid_PreHist = 1'b0;
			end else begin //if (data_StatRd_C_i <= LTP_Win_i)
				preSpikeHist = data_StatRd_C_i + 1;
				valid_PreHist = 1'b1;
			end
		end
	end

	//eta_prime +/- weight data mux and priority encoder input
	assign WtBias_in = (lrnUseBias_dly == 1'b0) ? data_StatRd_F_i : bufBias;
	assign negWtBias = (~WtBias_in) + 1;
	assign negDelta_WtBias = (~delta_WtBias) + 1;
	always @ (*) begin
		if (enLTP == 1'b1) begin
			eta_prime = LTP_LrnRt_i;
			sign_WtBias =  negWtBias[DSIZE-1:0];
			end 
		else if (enLTD == 1'b1) 
			begin
			eta_prime = LTD_LrnRt_i;
			sign_WtBias =  WtBias_in;
			end
		else
			begin
			eta_prime = 0;
			sign_WtBias =  0;
			end
		end

		if (delta_WtBias[DSIZE-1] == 1'b1) begin
			shiftRight = 1'b1;
			pEnc_in = negDelta_WtBias[DSIZE-2:DATA_BIT_WIDTH_FRAC];
		end else begin
			shiftRight = 1'b0;
			pEnc_in = delta_WtBias[DSIZE-2:DATA_BIT_WIDTH_FRAC];
		end
	end
	assign shifter_in_int = 1;
	assign shifter_in_frac = 0;

	//quantization look up
	always @ (posedge clk_i or negedge rst_n_i) begin
		if (rst_n_i == 1'b0) begin
			quantVal <= 0;
		end else begin
			case (pEnc_out)
				1: quantVal <= 2;
				2: quantVal <= 4;
				3: quantVal <= 8;
				4: quantVal <= 16;
				5: quantVal <= 32;
				default: quantVal <= 0;
			endcase
		end
	end

	//learn pipeline reg
	always @(posedge clk_i or negedge rst_n_i) begin
		if (rst_n_i == 1'b0) begin
			enLTP <= 1'b0;
			enLTD <= 1'b0;
			expPreHist <= 1'b0;

			delta_WtBias <= 0;
			quant_Dlta_Wt_Bias_reg <= 0;

			for(i = 0; i <= 4; i = i + 1)
				PreSpikeHist_Ppln[i] <= 0;
			enLrn_Ppln <= 5'b0;
			shiftRight_dly <= 1'b0;
			lrnUseBias_dly <= 1'b0;
			for(i = 0; i <= 2; i = i + 1)
				WeightBias_Ppln[i] <= 0;
			updtReg_WeightBias <= 0;
		
		end else begin

			enLTP <= 1'b0;
			enLTD <= 1'b0;
			expPreHist <= 1'b0;
			if ((axonLrnMode_i == 1'b1) && (lrnUseBias_i == 1'b0)) begin
				if ((valid_PostHist == 1'b1) && (valid_PreHist == 1'b1) && (CorSpike == 1'b1)) begin
					enLTP <= 1'b1;
					expPreHist <= 1'b1;
				end else if ((valid_PostHist == 1'b1) && (valid_PreHist == 1'b0) && (CorSpike == 1'b1)) begin
					enLTD <= 1'b1;
				end else if ((valid_PostHist == 1'b1) && (valid_PreHist == 1'b1) && (CorSpike == 1'b0)) begin
					enLTD <= 1'b1;
					expPreHist <= 1'b1;
				end
			end else if (lrnUseBias_i == 1'b1) begin
				if (valid_PostHist == 1'b1) begin
					enLTP <= 1'b1;
				end else begin
					enLTD <= 1'b1;	
				end
			end

			delta_WtBias <= delta_WtBias_Th;
			quant_Dlta_Wt_Bias_reg <= quant_Dlta_Wt_Bias;

			if (expPreHist == 1'b1) begin
				PreSpikeHist_Ppln[3] <= LTP_Win_i + 1;
			end else if (axonLrnMode_i == 1'b1) begin
				PreSpikeHist_Ppln[4] <= preSpikeHist;	
			end
			for(i = 0; i < 4; i = i + 1)
				PreSpikeHist_Ppln[i] <= PreSpikeHist_Ppln[i+1];

			lrnUseBias_dly <= lrnUseBias_i;
			if (lrnUseBias_dly == 1'b1) begin
				WeightBias_Ppln[2] <= bufBias;
			end else begin
				WeightBias_Ppln[2] <= data_StatRd_F_i;
			end
			for(i = 0; i < 2; i = i + 1)
				WeightBias_Ppln[i] <= WeightBias_Ppln[i+1];
			updtReg_WeightBias <= updt_WeightBias;

			enLrn_Ppln <= {axonLrnMode_i,enLrn_Ppln[4:1]};

			shiftRight_dly <= shiftRight;
		end
	end


	//MODULE INSTANTIATIONS
	//--------------------------------------------------//
	Adder_2sComp
	#(
		.DSIZE    ( DSIZE )
	)
	RECALL_ADDER
	(
		.A_din_i		( rclAdd_A ),
		.B_din_i		( rclAdd_B ),
		.twos_cmplmnt_i	( 1'b1 ),
		
		.clipped_sum_o	( accIn ),
		.sum_o			(  ),
		.carry_o 		(  ),
		.overflow_o 	(  ),
		.underflow_o 	(  )
	);

	Adder_2sComp
	#(
		.DSIZE    ( DSIZE )
	)
	DELTA_WT_BIAS_ADDER
	(
		.A_din_i		( deltaAdder_inA 	),
		.B_din_i		( deltaAdder_inB 	),
		.twos_cmplmnt_i	( deltaAdder_signed	),
		
		.clipped_sum_o	( delta_WtBias_Th ),
		.sum_o			(  ),
		.carry_o 		(  ),
		.overflow_o 	(  ),
		.underflow_o 	(  )
	);

	Adder_2sComp
	#(
		.DSIZE    ( DSIZE )
	)
	UPDATE_WT_BIAS_ADDER
	(
		.A_din_i		( WeightBias_Ppln[0] ),
		.B_din_i		( quant_Dlta_Wt_Bias_reg ),
		.twos_cmplmnt_i	( 1'b1 			),
		
		.clipped_sum_o	( updt_WeightBias ),
		.sum_o			(  ),
		.carry_o 		(  ),
		.overflow_o 	(  ),
		.underflow_o 	(  )
	);

	Lfsr 
	#(
		.DSIZE    ( DSIZE ),
		.SEED     ( SEED  )
	) 
	RAND_NUM
	(
		.clk_i		( clk_i			),
		.reset_n_i	( rst_n_i 		),
	
		.rd_rand_i	( rdLFSR_dly[0] & outSpike_o),
		.lfsr_dat_o ( lfsr_data 	)
	);

	PriorityEncoder
	#(
		.IN_DSIZE	( DATA_BIT_WIDTH_INT-1		),
		.OUT_DSIZE	( PRIORITY_ENC_OUT_BIT_WIDTH)
	)
	ENCODER
	(
		.in_data_i 		( pEnc_in 	), 

		.valid_bit_o 	( 	), 
		.out_data_o 	( pEnc_out 	)
	);

	barrel_shifter
	#(	
		.DSIZE		( DSIZE ),
		.SHIFTSIZE	( PRIORITY_ENC_OUT_BIT_WIDTH )
	)
	SHIFTER
	(
		.shift_in 		( {shifter_in_int,shifter_in_frac} ),
		.rightshift_i 	( shiftRight_dly ),
		.shift_by_i 	( quantVal ),

		.shift_out_o	( quant_Dlta_Wt_Bias )
	);


endmodule