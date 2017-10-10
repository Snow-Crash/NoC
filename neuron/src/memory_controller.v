module memory_controller
#(

    parameter NURN_CNT_BIT_WIDTH   = 8 ,
	parameter AXON_CNT_BIT_WIDTH   = 8 ,
    parameter DSIZE = 16,
    parameter PARAMETER_SELECT_BIT = 4, 
    parameter PACKET_SIZE = PARAMETER_SELECT_BIT + NURN_CNT_BIT_WIDTH + DSIZE + DSIZE ,
    parameter CONFIG_PARAMETER_NUMBER = 9,
    parameter STATUS_PARAMETER_NUMBER = 5
)
(input clk_i,
 input reset_n_i,
 input en_config, 
 input [PACKET_SIZE-1:0] packet_in, 
 input NI_empty, 
 output [CONFIG_PARAMETER_NUMBER-1:0] write_config_memory, 
 output [STATUS_PARAMETER_NUMBER-1:0] write_status_memory, 
 output reg read_NI, )

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

reg write_LTP_LTD_Window, write_LTP_LTD_LearnRate, write_LearnMode_Bias, write_NeuronType_RandomThreshold; 
reg write_Mask_RestThreshold, write_AER, write_FixedThreshold, write_LearnMode_Weight, write_Number_Neuron, write_Number_Axon;
reg write_Bias, write_Potential, write_Threshold, write_PostSynapticHistory, write_PreSynapticHistory, write_Weight;
reg write_config_enable;
 
//input packet format
//{parameter_code[3:0], neuron_id[7:0], parameter[15:0], 10'b0}
//{parameter_code[3:0], neuron_id[7:0], axon_id[7:0], parameter[15:0]}
//

//split packet
wire [PARAMETER_SELECT_BIT-1:0] select_parameter;
wire [NURN_CNT_BIT_WIDTH-1:0] neuron_id;
wire [AXON_CNT_BIT_WIDTH-1:0] axon_id;
wire [DSIZE*2-1:0] config_parameter;

wire [NURN_CNT_BIT_WIDTH-1:0] address_config_A;
wire [NURN_CNT_BIT_WIDTH-1:0] address_config_B;
wire [NURN_CNT_BIT_WIDTH + AXON_CNT_BIT_WIDTH-1:0] address_config_C;



assign select_parameter = packet_in[PACKET_SIZE - 1 : PACKET_SIZE - PARAMETER_SELECT_BIT];
assign neuron_id = packet_in [PACKET_SIZE - 1 - PARAMETER_SELECT_BIT : PACKET_SIZE - PARAMETER_SELECT_BIT - NURN_CNT_BIT_WIDTH];
assign axon_id = packet_in[PACKET_SIZE - 1 - PARAMETER_SELECT_BIT - NURN_CNT_BIT_WIDTH: PACKET_SIZE - PARAMETER_SELECT_BIT - NURN_CNT_BIT_WIDTH - AXON_CNT_BIT_WIDTH];
assign config_parameter = packet_in [PACKET_SIZE - 1 - PARAMETER_SELECT_BIT - NURN_CNT_BIT_WIDTH : 0];

assign address_config_A = neuron_id;
assign address_config_B = neuron_id;
assign address_config_C = {neuron_id, axon_id};


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
                    
                    write_enable <= read_NI;

                end
    end

//decode 
always @(*)
    begin
        write_config_memory = 9'd0;
        write_status_memory = 6'd0;

        if (write_enable == 1'b1)
            begin
                case(select_parameter)
                    Set_LTP_LTD_Window :                    write_config_memory = 9'b100000000    //write_LTP_LTD_Window = 1'b1;
                    Set_LTP_LTD_LearnRate :                 write_config_memory = 9'b010000000    //write_LTP_LTD_LearnRate = 1'b1;
                    Set_LearnMode_Bias = :                  write_config_memory = 9'b001000000    //write_LearnMode_Bias = 1'b1;
                    Set_NeuronType_RandomThreshold :        write_config_memory = 9'b000100000    //write_NeuronType_RandomThreshold = 1'b1;
                    Set_Mask_RestThreshold :                write_config_memory = 9'b000010000    //write_Mask_RestThreshold = 1'b1;
                    Set_AER :                               write_config_memory = 9'b000001000    //write_AER = 1'b1;
                    Set_FixedThreshold :                    write_config_memory = 9'b000000100    //write_FixedThreshold = 1'b1;
                    Set_LearnMode_Weight :                  write_config_memory = 9'b000000010    //write_LearnMode_Weight = 1'b1;
                    Set_Number_Neuron_Axon :                write_config_memory = 9'b000000001    //write_Number_Neuron_Axon = 1'b1;
                    //Set_Number_Axon :                     write_config_memory = 10'b0000000001    //write_Number_Axon = 1'b1;
                    Set_Bias_Potential :                    write_status_memory = 5'b10000         //write_Bias = 1'b1;
                    Set_Threshold :                         write_status_memory = 5'b01000         //write_Threshold = 1'b1;
                    Set_PostSynapticHistory :               write_status_memory = 5'b00100         //write_PostSynapticHistory = 1'b1;
                    Set_PreSynapticHistory :                write_status_memory = 5'b00010         //write_PreSynapticHistory = 1'b1;
                    Set_Weight :                            write_status_memory = 5'b00001         //write_Weight = 1'b1;
                endcase
            end
    end