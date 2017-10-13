//2017.10.10 config memory. Tested address convert for learn mode weight memory, correct.
//
`define USE_MODULE
`define SIM_MEM_INIT
`define NULL 0
//`define USE_MODULE

module ConfigMem_Asic_Onchip
#(
	parameter NUM_NURNS    = 256  ,
	parameter NUM_AXONS    = 256  ,

	parameter DSIZE    = 16 ,

	parameter NURN_CNT_BIT_WIDTH   = 8 ,
	parameter AXON_CNT_BIT_WIDTH   = 8 ,

	parameter STDP_WIN_BIT_WIDTH = 8 ,

	parameter AER_BIT_WIDTH = 32 ,

	parameter CONFIG_PARAMETER_NUMBER = 9,

	parameter LEARN_MODE_MEMORY_WIDTH = 2,
	

	parameter X_ID = "1",
	parameter Y_ID = "1",
	parameter DIR_ID = {X_ID, "_", Y_ID},
	parameter SYNTH_PATH = "D:/code/synth/data",
	parameter SIM_PATH = "D:/code/data"	

)
(
	input 												clk_i,
	input 												rst_n_i	,


	//input data port for config mode
	input [DSIZE*2-1:0]									config_data_in,
	input [CONFIG_PARAMETER_NUMBER-1:0] 				config_write_enable,

	output [DSIZE-1:0] 									FixedThreshold_o,
	output [NURN_CNT_BIT_WIDTH-1:0] 					Number_Neuron_o,
	output [AXON_CNT_BIT_WIDTH-1:0] 					Number_Axon_o,

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

localparam LEARN_MODE_MEMORY_ADDRESS_WIDTH = $clog2(NUM_NURNS * NUM_AXONS / LEARN_MODE_MEMORY_WIDTH);
localparam LEARN_MODE_MEMORY_ADDRESS_OFFSET_WIDTH = $clog2(NUM_NURNS / LEARN_MODE_MEMORY_WIDTH);
localparam NENRON_ID_SHIFT_BITS = $clog2(NUM_AXONS / LEARN_MODE_MEMORY_WIDTH);

//write signal for config mode
wire write_LTP_LTD_Window, rite_LTP_LTD_LearnRate, write_LearnMode_Bias, write_NeuronType_RandonThreshold, write_Mask_RestPotential;
wire write_AER, write_FixedThreshold, write_LearnMode_weight, write_Number_Neuron_Axon;


//wire for each memory output
wire [STDP_WIN_BIT_WIDTH*2-1:0] LTP_LTD_Window_wire;
wire [DSIZE*2-1:0] LTP_LTD_LearnRate_wire;
wire [1:0] NeuronType_RandomThreshold_wire;
wire [DSIZE*2-1:0] Mask_RestPotential_wire;
wire LearnMode_Bias_wire;
wire [AER_BIT_WIDTH-1:0] AER_wire;
wire [DSIZE-1:0] FixedThreshold_wire;

reg [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] Number_Neuron_Axon;

//address convert for learn mode weight
wire [LEARN_MODE_MEMORY_WIDTH-1:0] learn_mode;
wire [AXON_CNT_BIT_WIDTH-1:0] LearnMode_Weight_AxonID;
wire [NURN_CNT_BIT_WIDTH-1:0] LearnMode_Weight_NeuronID;
wire [LEARN_MODE_MEMORY_ADDRESS_WIDTH-1:0] LearnMode_Weight_AxonID_Mod;
wire [LEARN_MODE_MEMORY_ADDRESS_WIDTH - 1:0] LearnMode_Weight_BaseAddress, LearnMode_Weight_BaseAddress2;
wire learn_mode_o;
wire [LEARN_MODE_MEMORY_ADDRESS_WIDTH - 1:0] LearnMode_Weight_Address;
reg increase_offset;
reg read_LearnMode_Weight;
reg [LEARN_MODE_MEMORY_ADDRESS_OFFSET_WIDTH-1:0] LearnMode_Weight_Offset;
reg [LEARN_MODE_MEMORY_ADDRESS_WIDTH-1:0] LearnMode_Weight_AxonID_Mod_delay;

reg [STDP_WIN_BIT_WIDTH*2-1:0] LTP_LTD_Window_reg;
reg [DSIZE*2-1:0] LTP_LTD_LearnRate_reg;
reg LearnMode_Bias_reg;
reg [1:0] NeuronType_RandomThreshold_reg;
reg [DSIZE*2-1:0]Mask_RestPotential_reg;
reg [AER_BIT_WIDTH-1:0] AER_reg;
reg [DSIZE-1:0] FixedThreshold_reg;
reg [31:0] LearnMode_Weight_reg;

assign  write_LTP_LTD_Window = config_write_enable[8];
assign  write_LTP_LTD_LearnRate = config_write_enable[7];
assign  write_LearnMode_Bias = config_write_enable[6];
assign  write_NeuronType_RandonThreshold = config_write_enable[5];
assign  write_Mask_RestPotential = config_write_enable[4];
assign  write_AER = config_write_enable[3];
assign  write_FixedThreshold = config_write_enable[2];
assign  write_LearnMode_weight = config_write_enable[1];
assign  write_Number_Neuron_Axon = config_write_enable[0];

`ifdef USE_MODULE
	reg [NURN_CNT_BIT_WIDTH-1:0]	LTP_LTD_Window_addr_reg;
	reg [NURN_CNT_BIT_WIDTH-1:0]	LTP_LTD_LearnRate_addr_reg;
	reg [NURN_CNT_BIT_WIDTH-1:0]	LearnMode_Bias_addr_reg;
	reg [NURN_CNT_BIT_WIDTH-1:0]	NeuronType_RandomThreshold_addr_reg;
	reg [NURN_CNT_BIT_WIDTH-1:0]	Mask_RestPotential_addr_reg;
	reg [NURN_CNT_BIT_WIDTH-1:0]	AER_addr_reg;
	reg [NURN_CNT_BIT_WIDTH-1:0]	FixedThreshold_addr_reg;
	reg [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0]	LearnMode_Weight_addr_reg;
	reg [LEARN_MODE_MEMORY_ADDRESS_WIDTH-1:0]	LearnMode_Weight_addr_reg2;
`endif



 //rwo registers store number of neuron and number of axon
always @(posedge clk_i or negedge rst_n_i)
	begin
	  	if (rst_n_i == 1'b0)
		  	begin
				Number_Neuron_Axon <= 0;
			end
		else
			begin
				if(write_Number_Neuron_Axon == 1'b1)
					begin
						Number_Neuron_Axon <= config_data_in[NURN_CNT_BIT_WIDTH-1:0];
					end			
			end
	end
assign Number_Neuron_o = Number_Neuron_Axon[NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:AXON_CNT_BIT_WIDTH];
assign Number_Axon_o = Number_Neuron_Axon[AXON_CNT_BIT_WIDTH-1:0];




`ifdef QUARTUS_SYN_INIT
	(* ram_init_file = INIT_FILE_PATH *) reg [STDP_WIN_BIT_WIDTH*2-1:0] LTP_LTD_Window 		[(1<<NURN_CNT_BIT_WIDTH) -1:0];
	(* ram_init_file = INIT_FILE_PATH *) reg [DSIZE*2-1:0] LTP_LTD_LearnRate 				[(1<<NURN_CNT_BIT_WIDTH) -1:0];
	(* ram_init_file = INIT_FILE_PATH *) reg LearnMode_Bias 								[(1<<NURN_CNT_BIT_WIDTH) -1:0];
	(* ram_init_file = INIT_FILE_PATH *) reg [1:0] NeuronType_RandomThreshold 				[(1<<NURN_CNT_BIT_WIDTH) -1:0];
	(* ram_init_file = INIT_FILE_PATH *) reg [DSIZE*2-1:0] Mask_RestPotential 				[(1<<NURN_CNT_BIT_WIDTH) -1:0];
	(* ram_init_file = INIT_FILE_PATH *) reg [AER_BIT_WIDTH-1:0] AER 						[(1<<NURN_CNT_BIT_WIDTH) -1:0];
	(* ram_init_file = INIT_FILE_PATH *) reg [DSIZE-1:0] FixedThreshold 					[(1<<NURN_CNT_BIT_WIDTH) -1:0];
	(* ram_init_file = INIT_FILE_PATH *) reg LearnMode_Weight 								[(1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH))-1:0];
`else
	reg [STDP_WIN_BIT_WIDTH*2-1:0] 		LTP_LTD_Window 						[(1<<NURN_CNT_BIT_WIDTH) -1:0];
	reg [DSIZE*2-1:0] 					LTP_LTD_LearnRate 					[(1<<NURN_CNT_BIT_WIDTH) -1:0];
	reg 								LearnMode_Bias 						[(1<<NURN_CNT_BIT_WIDTH) -1:0];
	reg [1:0] 							NeuronType_RandomThreshold 			[(1<<NURN_CNT_BIT_WIDTH) -1:0];
	reg [DSIZE*2-1:0] 					Mask_RestPotential 					[(1<<NURN_CNT_BIT_WIDTH) -1:0];
	reg [AER_BIT_WIDTH-1:0] 			AER 								[(1<<NURN_CNT_BIT_WIDTH) -1:0];
	reg [DSIZE-1:0] 					FixedThreshold 						[(1<<NURN_CNT_BIT_WIDTH) -1:0];
	reg 								LearnMode_Weight 					[(1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH))-1:0];
	reg [LEARN_MODE_MEMORY_WIDTH-1:0]	LearnMode_Weight2 					[(1<<LEARN_MODE_MEMORY_ADDRESS_WIDTH)-1:0];
`endif

`ifdef SIM_MEM_INIT
		integer file1, file2, file3, file4, file5, idx, file6;
		reg [100*8:1] file_name;
		reg [STDP_WIN_BIT_WIDTH-1:0] data_S1, data_S2;
		reg [DSIZE-1:0] data_D1, data_D2, data_D3;
		reg data_B1, data_B2;
		reg [AER_BIT_WIDTH-1:0] data_A1;
		reg [LEARN_MODE_MEMORY_WIDTH-1:0] data_learn_mode;
		integer idx2;
			
		initial begin

			// initialize mem_A
			file_name = {SIM_PATH, DIR_ID, "/LTP_Win.txt"}; 		file1 = $fopen(file_name, "r+");
			if (file1 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end
			file_name = {SIM_PATH, DIR_ID, "/LTD_Win.txt"}; 		file2 = $fopen(file_name, "r+");
			if (file2 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end
			file_name = {SIM_PATH, DIR_ID, "/LTP_LrnRt.txt"}; 	file3 = $fopen(file_name, "r+");
			if (file3 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end
			file_name = {SIM_PATH, DIR_ID, "/LTD_LrnRt.txt"}; 	file4 = $fopen(file_name, "r+");
			if (file4 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end
			file_name = {SIM_PATH, DIR_ID, "/LrnModeBias.txt"}; 	file5 = $fopen(file_name, "r+");
			if (file5 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end

			for(idx = 0 ; idx <= (NUM_NURNS - 1) ; idx = idx + 1)
			begin
				$fscanf (file1, "%h\n", data_S1);
				$fscanf (file2, "%h\n", data_S2);
				$fscanf (file3, "%h\n", data_D1);
				$fscanf (file4, "%h\n", data_D2);
				$fscanf (file5, "%h\n", data_B1);
				LTP_LTD_Window[idx] = {data_S1, data_S2};
				LTP_LTD_LearnRate[idx] = {data_D1,data_D2};
				LearnMode_Bias[idx] = data_B1;
			end
		
			$fclose(file1);
			$fclose(file2);
			$fclose(file3);
			$fclose(file4);
			$fclose(file5);
			//-----------------------------

			// initialize mem_B
			file_name = {SIM_PATH, DIR_ID, "/NurnType.txt"}; 	file1 = $fopen(file_name, "r+");
			if (file1 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end
			file_name = {SIM_PATH, DIR_ID, "/RandTh.txt"}; 		file2 = $fopen(file_name, "r+");
			if (file1 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end
			file_name = {SIM_PATH, DIR_ID, "/Th_Mask.txt"}; 		file3 = $fopen(file_name, "r+");
			if (file2 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end
			file_name = {SIM_PATH, DIR_ID, "/RstPot.txt"};	 	file4 = $fopen(file_name, "r+");
			if (file3 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end
			file_name = {SIM_PATH, DIR_ID, "/SpikeAER.txt"};	 	file5 = $fopen(file_name, "r+");
			if (file4 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end
			file_name = {SIM_PATH, DIR_ID, "/FixedTh.txt"};	 	file6 = $fopen(file_name, "r+");
			if (file4 == `NULL) begin $error("ERROR: File open : %s", file_name); $stop; end

			for(idx = 0 ; idx <= (NUM_NURNS - 1) ; idx = idx + 1)
			begin
				$fscanf (file1, "%h\n", data_B1);
				$fscanf (file2, "%h\n", data_B2);
				$fscanf (file3, "%h\n", data_D1);
				$fscanf (file4, "%h\n", data_D2);
				$fscanf (file5, "%h\n", data_A1);
				$fscanf (file6, "%h\n", data_D3);
				NeuronType_RandomThreshold[idx] = {data_B1, data_B2};
				Mask_RestPotential[idx] = {data_D1, data_D2};
				AER[idx] = data_A1;
				FixedThreshold[idx] = data_D3;
			end
		
			$fclose(file1);
			$fclose(file2);
			$fclose(file3);
			$fclose(file4);
			$fclose(file5);
			$fclose(file6);
			//-----------------------------
			
			// initialize mem_C
			file_name = {SIM_PATH, DIR_ID, "/LrnModeWght.txt"};
			$readmemh (file_name,LearnMode_Weight);
			//$readmemh (file_name, LearnMode_Weight2);
			//initialize memc2
			file_name = {SIM_PATH, DIR_ID, "/LrnModeWght.txt"}; 	file1 = $fopen(file_name, "r+");

			for (idx = 0; idx <=((1<<LEARN_MODE_MEMORY_ADDRESS_WIDTH) - 1); idx = idx + 1)
				begin
					for(idx2 = 0; idx2 < LEARN_MODE_MEMORY_WIDTH; idx2 = idx2 + 1)
						begin
							$fscanf (file1, "%h\n", data_learn_mode[idx2]);
						end
					LearnMode_Weight2[idx] = data_learn_mode;
				end
			$fclose(file1);
			//-----------------------------
				
		end
`endif

`ifdef USE_MODULE

	//window
	always @ (posedge clk_i)
		begin
			if (write_LTP_LTD_Window)
				LTP_LTD_Window[Addr_Config_A_i] <= config_data_in[DSIZE*2-1:DSIZE*2-STDP_WIN_BIT_WIDTH*2];
			LTP_LTD_Window_addr_reg <= Addr_Config_A_i;  
		end
	assign LTP_LTD_Window_wire = LTP_LTD_LearnRate[LTP_LTD_Window_addr_reg];

	//LTP LTD learn rate
	always @ (posedge clk_i)
		begin
			if (write_LTP_LTD_LearnRate)
				LTP_LTD_LearnRate[Addr_Config_A_i] <= config_data_in;
			LTP_LTD_LearnRate_addr_reg <= Addr_Config_A_i;  
		end
	assign LTP_LTD_LearnRate_wire = LTP_LTD_LearnRate[LTP_LTD_LearnRate_addr_reg];

	//bias learn mode
	always @ (posedge clk_i)
		begin
			if (write_LearnMode_Bias)
				LearnMode_Bias[Addr_Config_A_i] <= config_data_in[DSIZE*2-1];
			LearnMode_Bias_addr_reg <= Addr_Config_A_i;  
		end
	assign LearnMode_Bias_wire = LTP_LTD_LearnRate[LearnMode_Bias_addr_reg];

	//neuron type and random threshold mode
	always @ (posedge clk_i)
		begin
			if (write_NeuronType_RandonThreshold)
				NeuronType_RandomThreshold[Addr_Config_B_i] <= config_data_in[DSIZE*2-1:DSIZE*2-2];
			NeuronType_RandomThreshold_addr_reg <= Addr_Config_B_i;  
		end
	assign NeuronType_RandomThreshold_wire = LTP_LTD_LearnRate[NeuronType_RandomThreshold_addr_reg];

	//Mask and potential
	always @ (posedge clk_i)
		begin
			if (write_Mask_RestPotential)
				Mask_RestPotential[Addr_Config_B_i] <= config_data_in;
			Mask_RestPotential_addr_reg <= Addr_Config_B_i;  
		end
	assign Mask_RestPotential_wire = LTP_LTD_LearnRate[Mask_RestPotential_addr_reg];

	//AER
	always @ (posedge clk_i)
		begin
			if (write_AER)
				AER[Addr_Config_B_i] <= config_data_in;
			AER_addr_reg <= Addr_Config_B_i;  
		end
	assign AER_wire = AER[AER_addr_reg];

	//fixed threshold
	always @ (posedge clk_i)
		begin
			if (write_FixedThreshold)
				FixedThreshold[Addr_Config_B_i] <= config_data_in[DSIZE*2-1:DSIZE];
			FixedThreshold_addr_reg <= Addr_Config_B_i;  
		end
	assign FixedThreshold_wire = FixedThreshold[FixedThreshold_addr_reg];

	//weight leanrning mode
	always @ (posedge clk_i)
		begin
			if (write_LearnMode_weight)
				LearnMode_Weight[Addr_Config_B_i] <= config_data_in[DSIZE-1];
			LearnMode_Weight_addr_reg <= Addr_Config_C_i;  
		end
	assign axonLrnMode_o = LearnMode_Weight[LearnMode_Weight_addr_reg];

	//weight leanrning mode
	always @ (posedge clk_i)
		begin
			if (write_LearnMode_weight)
				LearnMode_Weight2[Addr_Config_B_i] <= config_data_in[DSIZE-1];
			LearnMode_Weight_addr_reg2 <= LearnMode_Weight_Address;  
		end
	assign learn_mode = LearnMode_Weight2[LearnMode_Weight_addr_reg2];

 `else
	//LTP window and LTD window
	generic_single_port_ram
		#(
			.DATA_WIDTH							(STDP_WIN_BIT_WIDTH*2),
			.ADDRESS_WIDTH						(NURN_CNT_BIT_WIDTH),
			.SIM_FILE_PATH						({SIM_PATH, DIR_ID, "/LTP_Win.txt"}),
			.INIT_FILE_PATH						(SYNTH_PATH)
		)
		LTP_LTD_Window
		(
			.clk								(clk), 
			.addr								(Addr_Config_A_i),
			.data_in							(config_data_in[DSIZE*2-1:DSIZE-STDP_WIN_BIT_WIDTH*2]),
			.data_out							(LTP_LTD_Window_wire), 
			.write_enable						(write_LTP_LTD_Window)
			//.read_enable						(rdEn_Config_A_i)
		);

	//LTD and LTD learn rate
	generic_single_port_ram
		#(
			.DATA_WIDTH							(DSIZE*2),
			.ADDRESS_WIDTH						(NURN_CNT_BIT_WIDTH),
			.SIM_FILE_PATH						({SIM_PATH, DIR_ID, "/LTP_Win.txt"}),
			.INIT_FILE_PATH						(SYNTH_PATH)
		)
	LTP_LTD_LearnRate
		(
			.clk								(clk_i),
			.addr								(Addr_Config_A_i),
			.data_in							(config_data_in),
			.data_out							(LTP_LTD_LearnRate_wire),
			.write_enable						(write_LTP_LTD_LearnRate)
			//.read_enable						(rdEn_Config_A_i)
		);

	//Bias learn mode
	generic_single_port_ram
		#(
			.DATA_WIDTH							(1),
			.ADDRESS_WIDTH						(NURN_CNT_BIT_WIDTH),
			.SIM_FILE_PATH						({SIM_PATH, DIR_ID, "/LTP_Win.txt"}),
			.INIT_FILE_PATH						(SYNTH_PATH)
		)
	LearnMode_Bias
		(
			.clk								(clk_i), 
			.addr								(Addr_Config_A_i),
			.data_in							(config_data_in[DSIZE*2-1]),
			.data_out							(LearnMode_Bias_wire), 
			.write_enable						(write_LearnMode_Bias)
			//.read_enable						(rdEn_Config_A_i)
		);

	//Neuron type and random threshold
	generic_single_port_ram
		#(
			.DATA_WIDTH							(2),
			.ADDRESS_WIDTH						(NURN_CNT_BIT_WIDTH),
			.SIM_FILE_PATH						({SIM_PATH, DIR_ID, "/NeuronType_Threshold.txt"}),
			.INIT_FILE_PATH						(SYNTH_PATH)
		)
	NeuronType_RandomThreshold
		(
			.clk								(clk_i), 
			.addr								(Addr_Config_B_i),
			.data_in							(config_data_in[DSIZE*2-1:DSIZE*2-2]),
			.data_out							(NeuronType_RandomThreshold_wire), 
			.write_enable						(write_NeuronType_RandonThreshold)
			//.read_enable							(rdEn_Config_B_i)
		);

	//Threshold Mask and rest potential
	generic_single_port_ram
		#(
			.DATA_WIDTH							(DSIZE*2),
			.ADDRESS_WIDTH						(NURN_CNT_BIT_WIDTH),
			.SIM_FILE_PATH						({SIM_PATH, DIR_ID, "/LTP_Win.txt"}),
			.INIT_FILE_PATH						(SYNTH_PATH)
		)
	Mask_RestPotential
		(
			.clk								(clk_i), 
			.addr								(Addr_Config_B_i),
			.data_in							(config_data_in),
			.data_out							(Mask_RestPotential_wire), 
			.write_enable						(write_Mask_RestPotential)
			//.read_enable						(rdEn_Config_B_i)
		);

	//AER
	generic_single_port_ram
		#(
			.DATA_WIDTH							(AER_BIT_WIDTH),
			.ADDRESS_WIDTH						(NURN_CNT_BIT_WIDTH),
			.SIM_FILE_PATH						({SIM_PATH, DIR_ID, "/LTP_Win.txt"}),
			.INIT_FILE_PATH						(SYNTH_PATH)
		)
	AER
		(
			.clk								(clk_i), 
			.addr								(Addr_Config_B_i),
			.data_in							(config_data_in),
			.data_out							(AER_wire), 
			.write_enable						(write_AER)
			//.read_enable						(rdEn_Config_B_i)
		);

	//Fixed threshold
	generic_single_port_ram
		#(
			.DATA_WIDTH							(DSIZE),
			.ADDRESS_WIDTH						(NURN_CNT_BIT_WIDTH),
			.SIM_FILE_PATH						({SIM_PATH, DIR_ID, "/LTP_Win.txt"}),
			.INIT_FILE_PATH						(SYNTH_PATH)
		)
	FixedThreshold
		(
			.clk								(clk_i), 
			.addr								(Addr_Config_B_i),
			.data_in							(config_data_in[DSIZE*2-1:DSIZE]),
			.data_out							(FixedThreshold_wire), 
			.write_enable						(write_FixedThreshold)
			//.read_enable						(rdEn_Config_B_i)
		);

	//Learn mode weight
	generic_single_port_ram
		#(
			.DATA_WIDTH							(1),
			.ADDRESS_WIDTH						(NURN_CNT_BIT_WIDTH + AXON_CNT_BIT_WIDTH),
			.SIM_FILE_PATH						({SIM_PATH, DIR_ID, "/LrnModeWght.txt"}),
			.INIT_FILE_PATH						(SYNTH_PATH)
		)
	LearnMode_Weight
		(
			.clk								(clk_i), 
			.addr								(Addr_Config_C_i),
			.data_in							(config_data_in[DSIZE*2-1]),
			.data_out							(axonLrnMode_o), 
			.write_enable						(write_LearnMode_weight)
			//.read_enable						(rdEn_Config_C_i)
		);

	//Learn mode weight
	generic_single_port_ram
		#(
			.DATA_WIDTH							(LEARN_MODE_MEMORY_WIDTH),
			.ADDRESS_WIDTH						(LEARN_MODE_MEMORY_ADDRESS_WIDTH),
			.SIM_FILE_PATH						({SIM_PATH, DIR_ID, "/LrnModeWght2.txt"}),
			.INIT_FILE_PATH						(SYNTH_PATH)
		)
	LearnMode_Weight2
		(
			.clk								(clk_i), 
			.addr								(LearnMode_Weight_Address),
			.data_in							(config_data_in[0]),
			.data_out							(learn_mode), 
			.write_enable						(0'b0)
			//.read_enable						(read_LearnMode_Weight)
		);
`endif


//registers to store memory output
always @(posedge clk_i or negedge rst_n_i)
	begin
		if (rst_n_i == 1'b0)
			begin
				LTP_LTD_Window_reg <= 0;
				LTP_LTD_LearnRate_reg <= 0;
				LearnMode_Bias_reg <= 0;
				NeuronType_RandomThreshold_reg <= 0;
				Mask_RestPotential_reg <= 0;
				AER_reg <= 0;
				FixedThreshold_reg <= 0;
				LearnMode_Weight_reg <= 0;
			end
		else
			begin
				if (rdEn_Config_A_i == 1'b1)
					begin
						LTP_LTD_Window_reg <= LTP_LTD_Window_wire;
						LTP_LTD_LearnRate_reg <= LTP_LTD_LearnRate_wire;
						LearnMode_Bias_reg <= LearnMode_Bias_wire;
					end
				if (rdEn_Config_B_i == 1'b1)
					begin
						NeuronType_RandomThreshold_reg <= NeuronType_RandomThreshold_wire;
						Mask_RestPotential_reg <= Mask_RestPotential_wire;
						AER_reg <= AER_wire;
						FixedThreshold_reg <= FixedThreshold_wire;
					end
			end
	end


assign LTP_Win_o = LTP_LTD_Window_reg [STDP_WIN_BIT_WIDTH*2-1 : STDP_WIN_BIT_WIDTH];
assign LTD_Win_o = LTP_LTD_Window_reg [STDP_WIN_BIT_WIDTH - 1:0];
assign LTP_LrnRt_o = LTP_LTD_LearnRate_reg[DSIZE*2-1:DSIZE];
assign LTD_LrnRt_o = LTP_LTD_LearnRate_reg[DSIZE-1:0];
assign biasLrnMode_o = LearnMode_Bias_reg;
assign NurnType_o = NeuronType_RandomThreshold_reg[1];
assign RandTh_o = NeuronType_RandomThreshold_reg[0];
assign Th_Mask_o = Mask_RestPotential_reg[DSIZE*2-1:DSIZE];
assign RstPot_o = Mask_RestPotential_reg[DSIZE-1:0];
assign SpikeAER_o = AER_reg;


//Address convert
assign LearnMode_Weight_NeuronID = Addr_Config_C_i[NURN_CNT_BIT_WIDTH + AXON_CNT_BIT_WIDTH-1:AXON_CNT_BIT_WIDTH];
assign LearnMode_Weight_AxonID = Addr_Config_C_i[AXON_CNT_BIT_WIDTH-1:0];
assign LearnMode_Weight_AxonID_Mod = LearnMode_Weight_AxonID % LEARN_MODE_MEMORY_WIDTH;
assign LearnMode_Weight_BaseAddress = LearnMode_Weight_NeuronID * NUM_AXONS / LEARN_MODE_MEMORY_WIDTH;	//change to shift operation
assign LearnMode_Weight_BaseAddress2 = LearnMode_Weight_NeuronID << NENRON_ID_SHIFT_BITS;

always @(*)
	begin
		if ((LearnMode_Weight_AxonID_Mod == LEARN_MODE_MEMORY_WIDTH-1) && rdEn_Config_C_i == 1'b1)
			increase_offset = 1'b1;
		else
			increase_offset = 1'b0;

		if ((LearnMode_Weight_AxonID_Mod == 5'b0) && rdEn_Config_C_i == 1'b1)
			read_LearnMode_Weight = 1'b1;
		else
			read_LearnMode_Weight = 1'b0;
	end

always @(posedge clk_i or negedge rst_n_i)
	begin
		if (rst_n_i == 1'b0)
			begin
				LearnMode_Weight_Offset <= 0;
				//LearnMOde_ReadCounter <= 0;
				LearnMode_Weight_AxonID_Mod_delay <= 0;
			end
		else
			begin
				if(increase_offset == 1'b1)
					LearnMode_Weight_Offset <= LearnMode_Weight_Offset + 1'b1;
				//if (rdEn_Config_C_i == 1'b1)
					//LearnMOde_ReadCounter <= LearnMOde_ReadCounter + 1'b1;
				//if (read_LearnMode_Weight == 1'b1)
					LearnMode_Weight_AxonID_Mod_delay = LearnMode_Weight_AxonID_Mod;
				
			end
	end

assign LearnMode_Weight_Address = LearnMode_Weight_BaseAddress + LearnMode_Weight_Offset;
assign learn_mode_o = learn_mode[LearnMode_Weight_AxonID_Mod_delay];



endmodule