// 

`include "neuron_define.v"
// `define USE_MODULE
// `define SIM_MEM_INIT
// `define NULL 0
// `define MEM_DECLARE

module ConfigMem_Asic
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

	input [NURN_CNT_BIT_WIDTH:0]						Addr_AER_i,
	input 												rdEn_AER_i,

	//read port C
	input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	Addr_Config_C_i,
	input 												rdEn_Config_C_i,

	output												axonLrnMode_o,
	input [AXON_CNT_BIT_WIDTH-1:0]						Addr_axon_scaling_i,
	output [1:0]										Axon_scaling_o,

    input                                               ce,

    input [NURN_CNT_BIT_WIDTH-1:0]						AER_pointer_i,
	output												read_next_AER_o,
	input												multicast_i,
	output [3:0]										AER_number_o

);

parameter CONFIG_A_WIDTH = STDP_WIN_BIT_WIDTH*2 + DSIZE*2 + 1;
parameter CONFIG_B_WIDTH = 1 + 1 + DSIZE*3 + 4;

//write signal for config mode

//wire for each memory output

reg [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] Number_Neuron_Axon;


reg [STDP_WIN_BIT_WIDTH*2+DSIZE*2+1-1:0]	config_A_reg;
reg [1+1+DSIZE*3+4-1:0]	config_B_reg;
reg [CONFIG_A_WIDTH-1:0]                      config_A_dout;
reg [CONFIG_B_WIDTH-1:0]                      config_B_dout;
reg [64-1:0]	                axon_mode_1_dout;
reg [64-1:0]	                axon_mode_2_dout;
reg [64-1:0]	                axon_mode_3_dout;
reg [64-1:0]	                axon_mode_4_dout;
reg [AER_BIT_WIDTH-1:0]         config_AER_dout;
wire [NURN_CNT_BIT_WIDTH-1:0]   neuron_id;
wire [AXON_CNT_BIT_WIDTH-1:0]   axon_id;
reg [AXON_CNT_BIT_WIDTH-1:0]    axon_id_reg;
reg [AXON_CNT_BIT_WIDTH+NURN_CNT_BIT_WIDTH-1:0] LearnMode_Weight_addr_reg;
wire [255:0]                    axon_mode_all;
reg [AER_BIT_WIDTH-1:0]			AER_reg;
reg [1:0]						axon_scaling_out;

//  //rwo registers store number of neuron and number of axon
// always @(posedge clk_i or negedge rst_n_i)
// 	begin
// 	  	if (rst_n_i == 1'b0)
// 		  	begin
// 				Number_Neuron_Axon <= 0;
// 			end
// 		else
// 			begin
// 				if(write_Number_Neuron_Axon == 1'b1)
// 					begin
// 						Number_Neuron_Axon <= config_data_in[NURN_CNT_BIT_WIDTH-1:0];
// 					end			
// 			end
// 	end
// assign Number_Neuron_o = Number_Neuron_Axon[NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:AXON_CNT_BIT_WIDTH];
// assign Number_Axon_o = Number_Neuron_Axon[AXON_CNT_BIT_WIDTH-1:0];


reg /*sparse*/ 						LearnMode_Weight 					[(1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH))-1:0];

// Mem A: ltp window, ltd window, ltp rate, ltd rate, bias learning mode
reg [CONFIG_A_WIDTH-1:0]                  config_A            [255:0];
// Mem B: neuron type, rand threshold, mask, rest potential, fixed th,aer number
reg [CONFIG_B_WIDTH-1:0]                  config_B      [255:0];
// Mem B: aer
reg [31:0]                  config_AER                              [255:0];
// Mem C: weight learning mode           
reg [63:0]                          axon_mode_1                    [255:0];
reg [63:0]                          axon_mode_2                    [255:0];
reg [63:0]                          axon_mode_3                    [255:0];
reg [63:0]                          axon_mode_4                    [255:0];
// axon sclaling
reg [1:0]							axon_scaling					[255:0];

`ifdef SIM_MEM_INIT
		integer file1, file2, file3, file4, file5, idx, file6, file7;
		reg [100*8:1] file_name;
		reg [STDP_WIN_BIT_WIDTH-1:0] data_S1, data_S2;
		reg [DSIZE-1:0] data_D1, data_D2, data_D3;
		reg data_B1, data_B2;
		reg [AER_BIT_WIDTH-1:0] data_A1;
		reg [256-1:0] data_learn_mode;
		reg [3:0] data_AER_num;
		integer idx2;
			
		initial begin

			// initialize mem_A
			file_name = {SIM_PATH, "data", DIR_ID, "/LTP_Win.txt"}; 		file1 = $fopen(file_name, "r+");
			if (file1 == `NULL) begin  $stop; end
			file_name = {SIM_PATH, "data", DIR_ID, "/LTD_Win.txt"}; 		file2 = $fopen(file_name, "r+");
			if (file2 == `NULL) begin  $stop; end
			file_name = {SIM_PATH, "data", DIR_ID, "/LTP_LrnRt.txt"}; 	file3 = $fopen(file_name, "r+");
			if (file3 == `NULL) begin  $stop; end
			file_name = {SIM_PATH, "data", DIR_ID, "/LTD_LrnRt.txt"}; 	file4 = $fopen(file_name, "r+");
			if (file4 == `NULL) begin  $stop; end
			file_name = {SIM_PATH, "data", DIR_ID, "/LrnModeBias.txt"}; 	file5 = $fopen(file_name, "r+");
			if (file5 == `NULL) begin  $stop; end

			for(idx = 0 ; idx <= ((1<<NURN_CNT_BIT_WIDTH) - 1) ; idx = idx + 1)
			begin
				$fscanf (file1, "%h\n", data_S1);       //ltp window
				$fscanf (file2, "%h\n", data_S2);       //ltd window
				$fscanf (file3, "%h\n", data_D1);       //ltp rate
				$fscanf (file4, "%h\n", data_D2);       //ltd rare
				$fscanf (file5, "%h\n", data_B1);       //bias mode
				config_A[idx] = {data_S1, data_S2, data_D1, data_D2, data_B1};
			end
		
			$fclose(file1);
			$fclose(file2);
			$fclose(file3);
			$fclose(file4);
			$fclose(file5);
			//-----------------------------

			// initialize mem_B
			file_name = {SIM_PATH, "data", DIR_ID, "/NurnType.txt"}; 	file1 = $fopen(file_name, "r+");
			if (file1 == `NULL) begin  $stop; end
			file_name = {SIM_PATH, "data", DIR_ID, "/RandTh.txt"}; 		file2 = $fopen(file_name, "r+");
			if (file1 == `NULL) begin  end
			file_name = {SIM_PATH, "data", DIR_ID, "/Th_Mask.txt"}; 		file3 = $fopen(file_name, "r+");
			if (file2 == `NULL) begin  $stop; end
			file_name = {SIM_PATH, "data", DIR_ID, "/RstPot.txt"};	 	file4 = $fopen(file_name, "r+");
			if (file3 == `NULL) begin  $stop; end
			file_name = {SIM_PATH, "data", DIR_ID, "/SpikeAER.txt"};	 	file5 = $fopen(file_name, "r+");
			if (file5 == `NULL) begin  $stop; end
			file_name = {SIM_PATH, "data", DIR_ID, "/FixedTh.txt"};	 	file6 = $fopen(file_name, "r+");
			if (file6 == `NULL) begin  $stop; end
            file_name = {SIM_PATH, "data", DIR_ID, "/AERnum.txt"};	 	file7 = $fopen(file_name, "r+");
			 if (file7 == `NULL) begin  $stop; end

			for(idx = 0 ; idx <= ((1<<NURN_CNT_BIT_WIDTH) - 1) ; idx = idx + 1)
			begin
				$fscanf (file1, "%h\n", data_B1);       //type
				$fscanf (file2, "%h\n", data_B2);       //rand
				$fscanf (file3, "%h\n", data_D1);       //mask
				$fscanf (file4, "%h\n", data_D2);       //rest 
				$fscanf (file5, "%h\n", data_A1);       //aer
				$fscanf (file6, "%h\n", data_D3);       //fixed th
				$fscanf (file7, "%h\n", data_AER_num);       //fixed th
                config_B[idx] = {data_B1, data_B2, data_D1, data_D2, data_D3, data_AER_num};
                //config_AER[idx] = data_A1;
			end
			$readmemh ({SIM_PATH, "data", DIR_ID, "/SpikeAER.txt"},config_AER);
			
			$fclose(file1);
			$fclose(file2);
			$fclose(file3);
			$fclose(file4);
			$fclose(file5);
			$fclose(file6);
			//-----------------------------
			
			// initialize mem_C
			file_name = {SIM_PATH, "data", DIR_ID, "/AxonScaling.txt"};
			$readmemh (file_name,axon_scaling);

			//initialize memc2
			file_name = {SIM_PATH, "data", DIR_ID, "/LrnModeWght.txt"}; 	file1 = $fopen(file_name, "r+");
            
            for(idx = 0 ; idx <= ((1<<NURN_CNT_BIT_WIDTH) - 1) ; idx = idx + 1)
                begin
                    for (idx2 = 0; idx2 <= 255; idx2 = idx2 + 1)
                        $fscanf (file1, "%h\n", data_learn_mode[idx2]);
                    
                    axon_mode_4[idx] = data_learn_mode[255:192];
                    axon_mode_3[idx] = data_learn_mode[191:128];
                    axon_mode_2[idx] = data_learn_mode[127:64];
                    axon_mode_1[idx] = data_learn_mode[63:0];
                end

			$fclose(file1);
			//-----------------------------

			//initialize axon sclaling
			file_name = {SIM_PATH, "data", DIR_ID, "/AxonScaling.txt"};
			$readmemh (file_name,LearnMode_Weight);
		end
`endif

assign neuron_id = Addr_Config_C_i[NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:AXON_CNT_BIT_WIDTH];
assign axon_id = Addr_Config_C_i[AXON_CNT_BIT_WIDTH-1:0];

always  @(posedge clk_i)
begin
    if(ce)
        begin
            if(config_write_enable)
                begin
                    config_A[Addr_Config_A_i] <= config_data_in;
                    config_A_dout <= config_data_in;
                end
            else
                config_A_dout <= config_A[Addr_Config_A_i];
        end
end

always  @(posedge clk_i)
begin
    if(ce)
        begin
            if(config_write_enable)
                begin
                    config_B[Addr_Config_B_i] <= config_data_in;
                    config_B_dout <= config_data_in;
                end
            else
                config_B_dout <= config_B[Addr_Config_B_i];
        end
end

always  @(posedge clk_i)
begin
    if(ce)
        begin
            if(config_write_enable)
                begin
                    config_AER[Addr_AER_i] <= config_data_in;
                    config_AER_dout <= config_data_in;
                end
            else
                config_AER_dout <= config_AER[Addr_AER_i];
        end
end

always  @(posedge clk_i)
begin
    if(ce)
        begin
            if(config_write_enable)
                begin
                    axon_mode_1[neuron_id] <= config_data_in;
                    axon_mode_1_dout <= config_data_in;
                end
            else
                axon_mode_1_dout <= axon_mode_1[neuron_id];
        end
end

always  @(posedge clk_i)
begin
    if(ce)
        begin
            if(config_write_enable)
                begin
                    axon_mode_2[neuron_id] <= config_data_in;
                    axon_mode_2_dout <= config_data_in;
                end
            else
                axon_mode_2_dout <=axon_mode_2[neuron_id];
        end
end

always  @(posedge clk_i)
begin
    if(ce)
        begin
            if(config_write_enable)
                begin
                    axon_mode_3[neuron_id] <= config_data_in;
                    axon_mode_3_dout <= config_data_in;
                end
            else
                axon_mode_3_dout <= axon_mode_3[neuron_id];
        end
end

always  @(posedge clk_i)
begin
    if(ce)
        begin
            if(config_write_enable)
                begin
                    axon_mode_4[neuron_id] <= config_data_in;
                    axon_mode_4_dout <= config_data_in;
                end
            else
                axon_mode_4_dout <= axon_mode_4[neuron_id];
        end
end

always @(posedge clk_i or negedge rst_n_i)
    begin
        if (rst_n_i == 1'b0)
            axon_id_reg <= 0;
        else
            axon_id_reg <= axon_id;
    end
assign axon_mode_all = {axon_mode_4_dout, axon_mode_3_dout, axon_mode_2_dout, axon_mode_1_dout};
assign axon_mode_o = axon_mode_all[axon_id_reg];


//weight leanrning mode
always @ (posedge clk_i)
    begin
        if (config_write_enable)
            LearnMode_Weight[Addr_Config_C_i] <= config_data_in[DSIZE-1];
        LearnMode_Weight_addr_reg <= Addr_Config_C_i;  
    end
//assign axonLrnMode_o = LearnMode_Weight[LearnMode_Weight_addr_reg];
assign axonLrnMode_o = axon_mode_all[axon_id_reg];

always  @(posedge clk_i)
begin
    if(ce)
        begin
            if(config_write_enable)
                begin
                    axon_scaling[Addr_axon_scaling_i] <= config_data_in;
                    axon_scaling_out <= config_data_in;
                end
            else
                axon_scaling_out <= axon_scaling[Addr_axon_scaling_i];
        end
end
assign Axon_scaling_o = axon_scaling_out;


//registers to store memory output
always @(posedge clk_i or negedge rst_n_i)
	begin
		if (rst_n_i == 1'b0)
			begin
                config_A_reg <= 0;
                config_B_reg <= 0;
				AER_reg <= 0;
			end
		else
			begin
				if (rdEn_Config_A_i == 1'b1)
					begin
                        config_A_reg <= config_A_dout;
					end
				if (rdEn_Config_B_i == 1'b1)
					begin
                        config_B_reg <= config_B_dout;
					end
				if (rdEn_AER_i == 1'b1)
					AER_reg <= config_AER_dout;
			end
	end

// Mem A: ltp window, ltd window, ltp rate, ltd rate, bias learning mode
assign LTP_Win_o =config_A_reg[STDP_WIN_BIT_WIDTH*2+DSIZE*2+1-1:STDP_WIN_BIT_WIDTH+DSIZE*2+1];
assign LTD_Win_o = config_A_reg [STDP_WIN_BIT_WIDTH+DSIZE*2+1-1:DSIZE*2+1];
assign LTP_LrnRt_o = config_A_reg[DSIZE*2+1-1:DSIZE+1];
assign LTD_LrnRt_o = config_A_reg[DSIZE+1-1:1];
assign biasLrnMode_o = config_A_reg[0];
// Mem B: neuron type, rand threshold, mask, rest potential, fixed th,aer number
assign NurnType_o = config_B_reg[1+1+DSIZE*3+4-1];
assign RandTh_o = config_B_reg[1+DSIZE*3+4-1];
assign Th_Mask_o = config_B_reg[DSIZE*3+4-1:DSIZE*2+4];
assign RstPot_o = config_B_reg[DSIZE*2+4-1:DSIZE+4];
assign FixedThreshold_o = config_B_reg[DSIZE+4-1:4];
assign AER_number_o = config_B_reg[3:0];
assign SpikeAER_o = (multicast_i == 1'b0)? AER_reg : config_AER_dout;
assign read_next_AER_o = config_AER_dout[AER_BIT_WIDTH-1];



endmodule