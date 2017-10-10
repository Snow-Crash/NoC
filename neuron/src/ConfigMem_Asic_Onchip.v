//2017.10.10 config memory. Tested address convert for learn mode weight memory, correct.
//
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

	parameter LEARN_MODE_MEMORY_WIDTH = 4,
	

	parameter X_ID = "1",
	parameter Y_ID = "1",
	parameter DIR_ID = {X_ID, "_", Y_ID},
	parameter SYNTH_PATH = "D:/code/synth/data",
	parameter SIM_PATH = "D:/code/data"	

)
(
	input 												clk_i,
	input 												rst_n_i	,

	input 												write_LTP_LTD_Window,
	input 												write_LTP_LTD_LearnRate ,
	input 												write_LearnMode_Bias,
	input 												write_NeuronType_RandonThreshold ,
	input 												write_Mask_RestPotential ,
	input 												write_AER ,
	input 												write_FixedThreshold ,
	input 												write_LearnMode_weight ,
	input 												write_Number_Neuron_Axon ,

	input [DSIZE*2-1:0]									config_data_in,
	input [CONFIG_PARAMETER_NUMBER-1:0] 				config_write_enable,
	input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	config_write_address,

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
localparam NENRON_ID_SHIFT_BITS = $clog2(NUM_AXONS / LEARN_MODE_MEMORY_WIDTH);

wire [STDP_WIN_BIT_WIDTH*2-1:0] LTP_LTD_Window_wire;
wire [DSIZE*2-1:0] LTP_LTD_LearnRate_wire;
wire [1:0] NeuronType_RandomThreshold_wire;
wire [DSIZE*2-1:0] Mask_RestPotential_wire;

reg [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] Number_Neuron_Axon;


//address convert for learn mode weight
wire [LEARN_MODE_MEMORY_WIDTH-1:0] learn_mode;
wire [AXON_CNT_BIT_WIDTH-1:0] LearnMode_Weight_AxonID;
wire [NURN_CNT_BIT_WIDTH-1:0] LearnMode_Weight_NeuronID;
wire [LEARN_MODE_MEMORY_ADDRESS_WIDTH-1:0] LearnMode_Weight_AxonID_Mod;
wire [LEARN_MODE_MEMORY_ADDRESS_WIDTH - 1:0] LearnMode_Weight_BaseAddress;
wire learn_mode_o;
wire [LEARN_MODE_MEMORY_ADDRESS_WIDTH - 1:0] LearnMode_Weight_Address;
reg increase_offset;
reg read_LearnMode_Weight;
reg [NURN_CNT_BIT_WIDTH-1:0] LearnMode_Weight_Offset;
reg [LEARN_MODE_MEMORY_ADDRESS_WIDTH-1:0] LearnMode_Weight_AxonID_Mod_delay;

//
//reg [4:0] LearnMOde_ReadCounter;




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

//mux 

//LTP window and LTD windoe
generic_single_port_ram
#(.DATA_WIDTH(STDP_WIN_BIT_WIDTH*2),
.ADDRESS_WIDTH(NURN_CNT_BIT_WIDTH),
.SIM_FILE_PATH({SIM_PATH, DIR_ID, "/LTP_Win.txt"}),
.INIT_FILE_PATH(SYNTH_PATH))
LTP_LTD_Window
(.clk(clk), .addr(Addr_Config_A_i),
.data_in(config_data_in[STDP_WIN_BIT_WIDTH*2-1:0]),
.data_out(LTP_LTD_Window_wire), .write_enable(write_LTP_LTD_Window),
.read_enable(rdEn_Config_A_i));

assign LTP_Win_o = LTP_LTD_Window_wire [STDP_WIN_BIT_WIDTH*2-1 : STDP_WIN_BIT_WIDTH];
assign LTD_Win_o = LTP_LTD_Window_wire [STDP_WIN_BIT_WIDTH - 1:0];

//LTD and LTD learn rate
generic_single_port_ram
#(.DATA_WIDTH(DSIZE*2),
.ADDRESS_WIDTH(NURN_CNT_BIT_WIDTH),
.SIM_FILE_PATH({SIM_PATH, DIR_ID, "/LTP_Win.txt"}),
.INIT_FILE_PATH(SYNTH_PATH))
LTP_LTD_LearnRate
(.clk(clk_i), .addr(Addr_Config_A_i),
.data_in(config_data_in),
.data_out(LTP_LTD_LearnRate_wire), .write_enable(write_LTP_LTD_LearnRate),
.read_enable(rdEn_Config_A_i));

assign LTP_LrnRt_o = LTP_LTD_LearnRate_wire[DSIZE*2-1:DSIZE];
assign LTD_LrnRt_o = LTP_LTD_LearnRate_wire[DSIZE-1:0];

//Bias learn mode
generic_single_port_ram
#(.DATA_WIDTH(1),
.ADDRESS_WIDTH(NURN_CNT_BIT_WIDTH),
.SIM_FILE_PATH({SIM_PATH, DIR_ID, "/LTP_Win.txt"}),
.INIT_FILE_PATH(SYNTH_PATH))
LearnMode_Bias
(.clk(clk_i), .addr(Addr_Config_A_i),
.data_in(config_data_in[0]),
.data_out(biasLrnMode_o), .write_enable(write_LearnMode_Bias),
.read_enable(rdEn_Config_A_i));

//Neuron type and random threshold
generic_single_port_ram
#(.DATA_WIDTH(2),
.ADDRESS_WIDTH(NURN_CNT_BIT_WIDTH),
.SIM_FILE_PATH({SIM_PATH, DIR_ID, "/NeuronType_Threshold.txt"}),
.INIT_FILE_PATH(SYNTH_PATH))
NeuronType_RandomThreshold
(.clk(clk_i), .addr(Addr_Config_B_i),
.data_in(config_data_in[1:0]),
.data_out(NeuronType_RandomThreshold_wire), .write_enable(write_NeuronType_RandonThreshold),
.read_enable(rdEn_Config_B_i));

//Threshold Mask and rest potential
generic_single_port_ram
#(.DATA_WIDTH(DSIZE*2),
.ADDRESS_WIDTH(NURN_CNT_BIT_WIDTH),
.SIM_FILE_PATH({SIM_PATH, DIR_ID, "/LTP_Win.txt"}),
.INIT_FILE_PATH(SYNTH_PATH))
Mask_RestPotential
(.clk(clk_i), .addr(Addr_Config_B_i),
.data_in(config_data_in[DSIZE*2-1:0]),
.data_out(Mask_RestPotential_wire), .write_enable(write_Mask_RestPotential),
.read_enable(rdEn_Config_B_i));

//AER
generic_single_port_ram
#(.DATA_WIDTH(AER_BIT_WIDTH),
.ADDRESS_WIDTH(NURN_CNT_BIT_WIDTH),
.SIM_FILE_PATH({SIM_PATH, DIR_ID, "/LTP_Win.txt"}),
.INIT_FILE_PATH(SYNTH_PATH))
AER
(.clk(clk_i), .addr(Addr_Config_B_i),
.data_in(config_data_in),
.data_out(SpikeAER_o), .write_enable(write_AER),
.read_enable(rdEn_Config_B_i));

//Fixed threshold
generic_single_port_ram
#(.DATA_WIDTH(DSIZE),
.ADDRESS_WIDTH(NURN_CNT_BIT_WIDTH),
.SIM_FILE_PATH({SIM_PATH, DIR_ID, "/LTP_Win.txt"}),
.INIT_FILE_PATH(SYNTH_PATH))
FixedThreshold
(.clk(clk_i), .addr(Addr_Config_B_i),
.data_in(config_data_in[DSIZE-1:0]),
.data_out(FixedThreshold_o), .write_enable(write_FixedThreshold),
.read_enable(rdEn_Config_B_i));

//Learn mode weight
generic_single_port_ram
#(.DATA_WIDTH(1),
.ADDRESS_WIDTH(NURN_CNT_BIT_WIDTH + AXON_CNT_BIT_WIDTH),
.SIM_FILE_PATH({SIM_PATH, DIR_ID, "/LrnModeWght.txt"}),
.INIT_FILE_PATH(SYNTH_PATH))
LearnMode_Weight
(.clk(clk_i), .addr(Addr_Config_C_i),
.data_in(config_data_in[0]),
.data_out(axonLrnMode_o), .write_enable(write_LearnMode_weight),
.read_enable(rdEn_Config_C_i));

//Learn mode weight
generic_single_port_ram
#(.DATA_WIDTH(LEARN_MODE_MEMORY_WIDTH),
.ADDRESS_WIDTH(LEARN_MODE_MEMORY_ADDRESS_WIDTH),
.SIM_FILE_PATH({SIM_PATH, DIR_ID, "/LrnModeWght2.txt"}),
.INIT_FILE_PATH(SYNTH_PATH))
LearnMode_Weight2
(.clk(clk_i), .addr(LearnMode_Weight_Address),
.data_in(config_data_in[0]),
.data_out(learn_mode), .write_enable(0'b0),
.read_enable(read_LearnMode_Weight));


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