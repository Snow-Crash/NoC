module memory_controller
#(

    parameter NURN_CNT_BIT_WIDTH   = 8 ,
	parameter AXON_CNT_BIT_WIDTH   = 8 ,
    parameter DSIZE = 16,
    parameter PARAMETER_SELECT_BIT = 4, 
    parameter PACKET_SIZE = PARAMETER_SELECT_BIT + NURN_CNT_BIT_WIDTH + DSIZE + DSIZE ,
    parameter CONFIG_PARAMETER_NUMBER = 9,
    parameter STATUS_PARAMETER_NUMBER = 6
)
(   
    input clk_i,
    input reset_n_i,
    //global config mode signal
    input en_config,

    //input from NI
    input [PACKET_SIZE-1:0] packet_in, 
    input NI_empty, 
    //read request NI fifo
    output reg read_NI, 

    //config memory
    //read address (from controller)
    input [NURN_CNT_BIT_WIDTH-1:0]                          read_address_config_A_i,
    input [NURN_CNT_BIT_WIDTH-1:0]                          read_address_config_B_i,
    input [NURN_CNT_BIT_WIDTH*AXON_CNT_BIT_WIDTH-1:0]       read_address_config_C_i,

    //config memory access address (used for both read and write)
    output [NURN_CNT_BIT_WIDTH-1:0]                         access_address_config_A_o,
    output [NURN_CNT_BIT_WIDTH-1:0]                         access_address_config_B_o,
    output [NURN_CNT_BIT_WIDTH*AXON_CNT_BIT_WIDTH-1:0]      access_address_config_C_o,
    //write enable signal used in config mode

    output reg config_LTP_LTD_Window_o,
    output reg config_LTP_LTD_LearnRate_o,
    output reg config_LearnMode_Bias_o,
    output reg config_NeuronType_RandomThreshold_o,
    output reg config_Mask_RestPotential_o,
    output reg config_AER_o,
    output reg config_FixedThreshold_o,
    output reg config_LearnMode_Weight_o,
    output reg config_Number_Neuron_Axon_o,

    //status memory write enable signal (from controller)
    input write_enable_Bias_controller_i,
    input write_enable_Potential_controller_i,
    input write_enable_Threshold_controller_i,
    input write_enable_Posthistory_controller_i,
    input write_enable_Prehistory_controller_i,
    input write_enable_Weight_controller_i,
    //status memory write enable (to status memory)
    output write_enable_Bias_o,
    output write_enable_Potential_o,
    output write_enable_Threshold_o,
    output write_enable_Posthistory_o,
    output write_enable_Prehistory_o,
    output write_enable_Weight_o,
    //status memory write address (from controller)
    input [NURN_CNT_BIT_WIDTH-1:0]                          Addr_StatWr_B_controller_i,
    input [NURN_CNT_BIT_WIDTH-1:0]                          Addr_StatWr_D_controller_i,
    input [NURN_CNT_BIT_WIDTH-1:0]                          Addr_StatWr_G_controller_i,
    //status memory write address (to status memory)
    output [NURN_CNT_BIT_WIDTH-1:0]                         Addr_StatWr_B_o,
    output [NURN_CNT_BIT_WIDTH-1:0]                         Addr_StatWr_D_o,
    output [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0]      Addr_StatWr_G_o,
    )

//define coding for different neuron parameters
parameter Set_LTP_LTD_Window = 4'd0;
parameter Set_LTP_LTD_LearnRate = 4'd1;
parameter Set_LearnMode_Bias = 4'd2;
parameter Set_NeuronType_RandomThreshold = 4'd3;
parameter Set_Mask_RestThreshold = 4'd4;
parameter Set_AER = 4'd5;
parameter Set_FixedThreshold = 4'd6;
parameter Set_LearnMode_Weight = 4'd7;
parameter Set_Number_Neuron_Axon = 4'd8;
//parameter Set_Number_Axon = 4'd9;
parameter Set_Bias = 4'd10;
parameter Set_Potential = 4'd11;
parameter Set_Threshold = 4'd12;
parameter Set_PostSynapticHistory = 4'd13;
parameter Set_PreSynapticHistory = 4'd14;
parameter Set_Weight = 4'd15;

reg config_Bias, config_Potential, config_Threshold, config_PostSynapticHistory, config_PreSynapticHistory, config_Weight;
reg config_address_B;
reg config_address_D;
reg config_address_G;


//split packet
wire [PARAMETER_SELECT_BIT-1:0]                     select_parameter;
wire [NURN_CNT_BIT_WIDTH-1:0]                       neuron_id;
wire [AXON_CNT_BIT_WIDTH-1:0]                       axon_id;
//wire [DSIZE*2-1:0]                                  config_parameter;

wire [NURN_CNT_BIT_WIDTH-1:0]                       config_mode_write_address_config_A;
wire [NURN_CNT_BIT_WIDTH-1:0]                       config_mode_write_address_config_B;
wire [NURN_CNT_BIT_WIDTH + AXON_CNT_BIT_WIDTH-1:0]  config_mode_write_address_config_C;

wire [STATUS_PARAMETER_NUMBER-1:0]                  config_mode_write_status;



assign select_parameter = packet_in[PACKET_SIZE - 1 : PACKET_SIZE - PARAMETER_SELECT_BIT];
assign neuron_id = packet_in [PACKET_SIZE - 1 - PARAMETER_SELECT_BIT : PACKET_SIZE - PARAMETER_SELECT_BIT - NURN_CNT_BIT_WIDTH];
assign axon_id = packet_in[PACKET_SIZE - 1 - PARAMETER_SELECT_BIT - NURN_CNT_BIT_WIDTH: PACKET_SIZE - PARAMETER_SELECT_BIT - NURN_CNT_BIT_WIDTH - AXON_CNT_BIT_WIDTH];
//assign config_parameter = packet_in [PACKET_SIZE - 1 - PARAMETER_SELECT_BIT - NURN_CNT_BIT_WIDTH : 0];

assign config_mode_write_address_config_A = neuron_id;
assign config_mode_write_address_config_B = neuron_id;
assign config_mode_write_address_config_C = {neuron_id, axon_id};


always @(posedge clk_i or negedge reset_n_i)
    begin
        if (reset_n_i == 1'b0)
            begin
                read_NI <= 1'b0;
                write_enable <= 0;
            end
        else
            if (en_config == 1'b1)
                begin
                    if (NI_empty == 1'b0)   //if NI is not empty, read from NI
                        read_NI <= 1'b1;
                    else
                        read_NI <= 1'b0;
                    config_mode_write_enable <= read_NI;
                end
    end

//decode 
always @(*)
    begin
        config_LTP_LTD_Window = 1'b0;
        config_LTP_LTD_LearnRate = 1'b0;
        config_LearnMode_Bias = 1'b0;
        config_NeuronType_RandomThreshold = 1'b0;
        config_Mask_RestPotential = 1'b0;
        config_AER = 1'b0;
        config_FixedThreshold = 1'b0;
        config_LearnMode_Weight = 1'b0;
        config_Number_Neuron_Axon = 1'b0;

        config_Bias = 1'b0;
        config_Potential = 1'b0;
        config_Threshold = 1'b0;
        config_PostSynapticHistory = 1'b0;
        config_PreSynapticHistory = 1'b0;
        config_Weight = 1'b0;

        if (config_mode_write_enable == 1'b1)
            begin
                case(select_parameter)
                    Set_LTP_LTD_Window :                    config_LTP_LTD_Window_o = 1'b1;                 //write_LTP_LTD_Window = 1'b1;
                    Set_LTP_LTD_LearnRate :                 config_LTP_LTD_LearnRate_o = 1'b1;              //write_LTP_LTD_LearnRate = 1'b1;
                    Set_LearnMode_Bias = :                  config_LearnMode_Bias_o = 1'b1;                 //write_LearnMode_Bias = 1'b1;
                    Set_NeuronType_RandomThreshold :        config_NeuronType_RandomThreshold_o = 1'b1;     //write_NeuronType_RandomThreshold = 1'b1;
                    Set_Mask_RestThreshold :                config_Mask_RestPotential_o = 1'b1;             //write_Mask_RestThreshold = 1'b1;
                    Set_AER :                               config_AER_o = 1'b1;                            //write_AER = 1'b1;
                    Set_FixedThreshold :                    config_FixedThreshold_o = 1'b1;                 //write_FixedThreshold = 1'b1;
                    Set_LearnMode_Weight :                  config_LearnMode_Weight_o = 1'b1;               //write_LearnMode_Weight = 1'b1;
                    Set_Number_Neuron_Axon :                config_Number_Neuron_Axon_o = 1'b1;             //write_Number_Neuron_Axon = 1'b1;
                endcase

                case (select_parameter)
                    Set_Bias :                              config_Bias = 1'b1;                     //write_Bias = 1'b1;
                    Set_Potential :                         config_Potential = 1'b1;                //
                    Set_Threshold :                         config_Threshold = 1'b1;                //write_Threshold = 1'b1;
                    Set_PostSynapticHistory :               config_PostSynapticHistory = 1'b1;      //write_PostSynapticHistory = 1'b1;
                    Set_PreSynapticHistory :                config_PreSynapticHistory = 1'b1;       //write_PreSynapticHistory = 1'b1;
                    Set_Weight :                            config_Weight = 1'b1;                   //write_Weight = 1'b1;
                endcase
            end
    end

//config memory address mux
always @(*)
    begin
        if (en_config == 1'b1)
            begin
                access_address_config_A = neuron_id;
                access_address_config_B = neuron_id;
                access_address_config_C = {neuron_id, axon_id};
            end
        else
            begin
                access_address_config_A = read_address_config_A;
                access_address_config_B = read_address_config_B;
                access_address_config_C = read_address_config_C;
            end
    end
//status memory write address mux
always @(*)
    begin
        if (en_config == 1'b1)
            begin
                Addr_StatWr_B_o = neuron_id;
                Addr_StatWr_D_o = neuron_id;
                Addr_StatWr_G_o = {neuron_id, axon_id};
            end
        else
            begin
                Addr_StatWr_B_o = Addr_StatWr_B_controller_i;
                Addr_StatWr_D_o = Addr_StatWr_D_controller_i;
                Addr_StatWr_G_o = Addr_StatWr_G_controller_i;
            end
    end

//status memory write enable mux
always @(*)
    begin
        if (en_config)
            write_enable_Bias_o = config_Bias;
            write_enable_Potential_o = config_Potential;
            write_enable_Threshold_o = config_Threshold;
            write_enable_Posthistory_o = config_PostSynapticHistory;
            write_enable_Prehistory_o = config_PreSynapticHistory;
            write_enable_Weight_o = config_Weight;
        else
            write_enable_Bias_o = write_enable_Bias_controller_i
            write_enable_Potential_o = write_enable_Potential_controller_i
            write_enable_Threshold_o = write_enable_Threshold_controller_i;
            write_enable_Posthistory_o = write_enable_Posthistory_controller_i
            write_enable_Prehistory_o = write_enable_Prehistory_controller_i
            write_enable_Weight_o = write_enable_Weight_controller_i;
    end


endmodule