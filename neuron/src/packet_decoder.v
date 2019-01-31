module packet_decoder
#(
	parameter NUM_AXONS = 256,
	parameter AXON_CNT_BIT_WIDTH = 8,
	parameter NURN_CNT_BIT_WIDTH = 7,
	parameter STDP_WIN_BIT_WIDTH = 8,
	parameter DSIZE = 16,
	parameter FLIT_WIDTH = 38,
	parameter VIRTUAL_CHANNEL = 4,
	parameter PAYLOAD_WIDTH = 32
)
(
input neuron_clk, 
input neuron_rst, 
input start, 
input activate_decoder, 
input stall_decoder, 
input [FLIT_WIDTH-1:0] flit_in,
output [AXON_CNT_BIT_WIDTH-1:0] buffered_spike_out, 
input mem_data_out, 
input [2:0] class_type_in,

//output to write status memory
output reg wr_en_potential_o,
output reg wr_en_threshold_o,
output reg wr_en_bias_o,
output reg wr_en_posthistory_o,
output reg wr_en_prehistory_o,
// address to status memory
output [NURN_CNT_BIT_WIDTH-1:0] address_bias,
output [NURN_CNT_BIT_WIDTH-1:0] address_potential,
output [NURN_CNT_BIT_WIDTH-1:0] address_threshold,
output [NURN_CNT_BIT_WIDTH-1:0] address_posthistory,
output [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] address_preshistory,
output [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] address_weight,

//output to write config memory
output reg wr_en_configA_o,
output reg wr_en_configB_o,
output reg wr_en_AER_o,
output reg wr_en_weight_o,
output reg wr_en_axonmode_o,
output reg wr_en_coreconfig_o,
output reg wr_en_axonmode_1_o,
output reg wr_en_axonmode_2_o,
output reg wr_en_axonmode_3_o,
output reg wr_en_axonmode_4_o,
output reg wr_en_scaling_o,

//address to config memory
output [NURN_CNT_BIT_WIDTH-1:0] address_config_A,
output [NURN_CNT_BIT_WIDTH-1:0] address_config_B,
output [NURN_CNT_BIT_WIDTH-1:0] address_axonmode,
output [NURN_CNT_BIT_WIDTH:0] address_AER,
output [AXON_CNT_BIT_WIDTH-1:0] address_axon_scaling,

output [63:0] config_data_out
);


// states
parameter DC_IDLE = 4'd0;
parameter DC_SET_TYPE = 4'd1;
parameter DC_BUFFER = 4'd2;
parameter DC_STALL = 4'd3;
parameter DC_WRITE =4'd4;

//decoder regs
reg [FLIT_WIDTH-1:0] pipeline_reg;
reg write_memory, set_class_type;
reg [2:0] class_type_reg;
reg [64-1:0] packet_buffer;
reg set_spike_buffer;
reg load_buffer;
reg [NURN_CNT_BIT_WIDTH-1:0] neuron_id_reg;
reg [AXON_CNT_BIT_WIDTH-1:0] axon_id_reg;
reg load_neuron_id, load_axon_id;
reg [1:0] axon_range_reg;
reg [3:0] packet_type_reg;

wire [2+VIRTUAL_CHANNEL+PAYLOAD_WIDTH-1:2+VIRTUAL_CHANNEL+PAYLOAD_WIDTH-2] header;
wire [3:0] packet_type;
wire [1:0] parameter_type;
wire [1:0] axon_offset;
wire [1:0] axon_range;
wire [AXON_CNT_BIT_WIDTH-1:0] axon_id_weight, axon_id_spike, axon_id_prehistory, axon_id_scaling;
wire [NURN_CNT_BIT_WIDTH-1:0] neuron_id;

//class type
parameter CLASS_TYPE_SPIKE = 3'd0;
parameter CLASS_TYPE_INITIALIZE = 3'd1;

//packet type define
parameter PACKET_TYPE_SPIKE = 5'd0;
parameter PACKET_TYPE_BIAS = 5'd1;
parameter PACKET_TYPE_THRESHOLD = 5'd2;
parameter PACKET_TYPE_POTENTIAL = 5'd3;
parameter PACKET_TYPE_POSTHISTORY = 5'd4;
parameter PACKET_TYPE_PREHISTORY = 5'd5;
parameter PACKET_TYPE_CONFIG_A = 5'd6;
parameter PACKET_TYPE_CONFIG_B = 5'd7;
parameter PACKET_TYPE_AER = 5'd8;
parameter PACKET_AXON_MODE = 5'd9;
parameter PACKET_AXON_SCALING = 5'd10;
parameter PACKET_CORE_CONFIG = 5'd11;
parameter PACKET_TYPE_WEIGHT = 5'd12;

//parameter type define
//status mem A
// parameter PARAMETER_BIAS = 2'b0;
// parameter PARAMETER_THRESHOLD = 2'b1;
// parameter PARAMETER_POTENTIAL = 2'b2;
// parameter PARAMETER_POSTHISTORY = 2'b3;
//config mem A
parameter PARAMETER_LTP_RATE = 2'd0;
parameter PARAMETER_LTD_RATE = 2'd1;
parameter PARAMETER_STDP_WINDOW = 2'd2;
//config mem B
parameter PARAMETER_TYPE_RAND_AERNUMBER = 2'b00;
parameter PARAMETER_MASK = 2'b01;
parameter PARAMETER_REST_POTENTIAL = 2'b10;
parameter PARAMETER_FIXED_THRESOLD = 2'b11;
// AER memory
parameter PARAMETER_COORDINATE = 2'b00;
parameter PARAMETER_PAYLOAD = 2'b01;

//axon offset
parameter PARAMETER_AXON_OFFSET_15_0 = 2'b0;
parameter PARAMETER_AXON_OFFSET_31_16 = 2'b01;
parameter PARAMETER_AXON_OFFSET_47_32 = 2'b10;
parameter PARAMETER_AXON_OFFSET_63_48 = 2'b11;
//axon range
parameter PARAMETER_AXON_63_0 = 2'b00;
parameter PARAMETER_AXON_127_64 = 2'b01;
parameter PARAMETER_AXON_191_128 = 2'b10;
parameter PARAMETER_AXON_255_192 = 2'b11;
//weight
parameter PARAMETER_TYPE_WEIGHT_ADDRESS = 2'b00;
parameter PARAMETER_TYPE_WEIGHT_VALUE = 2'b01;

reg [NUM_AXONS-1:0] spike_buffer;
reg load_bias, load_potential, load_threshold, load_posthistory;
reg load_prehistory, load_weight, load_ltp_rate, load_ltd_rate, load_window;
reg load_type_rand_aernumber, load_mask, load_rest_potential, load_fixed_threshold;
reg load_coordinate, load_payload;
reg load_axon_mode;

//fields
assign packet_type = flit_in[FLIT_WIDTH-1-2-VIRTUAL_CHANNEL:FLIT_WIDTH-2-VIRTUAL_CHANNEL-4];
assign parameter_type = flit_in[18:17];
assign neuron_id = flit_in[26:19];
assign axon_id_weight = flit_in[15:8];
assign axon_id_spike = flit_in[15:8];
assign axon_id_prehistory = flit_in[15:8];
assign axon_range = flit_in[19:18];
assign axon_offset = flit_in[17:16];
assign header = flit_in[2+VIRTUAL_CHANNEL+PAYLOAD_WIDTH-1:2+VIRTUAL_CHANNEL+PAYLOAD_WIDTH-2];
assign axon_id_scaling = flit_in[15:8];

//decode packet state machine
reg [3:0] decoder_cs, decoder_ns;

always @(posedge neuron_clk or negedge neuron_rst)
	begin
		if (neuron_rst == 1'b0)
			decoder_cs <= DC_IDLE;
		else
			decoder_cs <= decoder_ns;
	end

always @(*)
	begin
		case(decoder_cs)
			DC_IDLE:
				begin
					if (activate_decoder == 1'b1)
						decoder_ns = DC_SET_TYPE;
					else
						decoder_ns = DC_IDLE;
				end
			DC_SET_TYPE:
				decoder_ns = DC_BUFFER;
			DC_BUFFER:
				begin
					if (header == 2'b01)
						decoder_ns = DC_WRITE;
					else if (stall_decoder == 1'b1)
						decoder_ns = DC_STALL;
					else
						decoder_ns = DC_BUFFER;
				end
			DC_WRITE:
				begin
					if (activate_decoder == 1'b1)
						decoder_ns = DC_SET_TYPE;
					else
						decoder_ns = DC_IDLE;
				end
			DC_STALL:
				begin
					if (stall_decoder == 1'b1)
						decoder_ns = DC_STALL;
					else
						decoder_ns = DC_BUFFER;
				end
		endcase
	end
// decode combinational logic outpus
always @(*)
	begin
		write_memory = 1'b0;
		set_class_type = 1'b0;
		load_buffer = 1'b0;
		set_spike_buffer = 1'b0;

		case(decoder_cs)
			DC_IDLE:
				begin
					write_memory = 1'b0;
					set_class_type = 1'b0;
				end
			DC_SET_TYPE:
				begin
					set_class_type = 1'b1;
				end
			DC_BUFFER:
				begin
					if (header == 2'b10)
						load_buffer = 1'b0;
					// if class type is weight or mem intialize
					else if (class_type_reg == 3'd1 )
						load_buffer = 1'b1;
					// if packet type is spike
					if (header == 2'b10)
						set_spike_buffer = 1'b0;
					else if (class_type_reg == 3'd0)
						set_spike_buffer = 1'b1;
				end
			DC_STALL:
				begin
					write_memory = 1'b0;
					set_class_type = 1'b0;
				end
			DC_WRITE:
				begin
					write_memory = 1'b1;
				end
			default:
				begin
					write_memory = 1'b0;
					set_class_type = 1'b0;
				end
		endcase
	end

//decoder registers
//spike packet decode
always @(posedge neuron_clk or negedge neuron_rst)
	begin
		if (neuron_rst == 1'b0)
			begin
				//packet_out <= 0;
				packet_buffer <= 0;
				class_type_reg <= 0;
				spike_buffer <= 0;
			end
		else
			begin
				if (set_class_type == 1'b1)
					class_type_reg <= class_type_in;			

				if (start == 1'b1)
					spike_buffer <= 0;
				else if (set_spike_buffer == 1'b1)
					spike_buffer[axon_id_spike] <= 1'b1;
			end
	end
assign buffered_spike_out = spike_buffer;

always @(posedge neuron_clk or negedge neuron_rst)
	begin
		if (neuron_rst == 1'b0)
			begin
				packet_buffer <= 0;
				packet_type_reg <=0;
				axon_id_reg <= 0;
				neuron_id_reg <= 0;
				axon_range_reg <= 0;
			end
		else
			begin
				if (load_buffer == 1'b1)
					begin
						case(packet_type)
							PACKET_TYPE_POTENTIAL:
								begin
									packet_buffer[15:0] <= flit_in[15:0];
									neuron_id_reg <= neuron_id;
								end
							PACKET_TYPE_THRESHOLD:
								begin
									packet_buffer[15:0] <= flit_in[15:0];
									neuron_id_reg <= neuron_id;
								end
							PACKET_TYPE_POSTHISTORY:
								begin
									packet_buffer[15:0] <= flit_in[15:0];
									neuron_id_reg <= neuron_id;
								end
							PACKET_TYPE_BIAS:
								begin
									packet_buffer[15:0] <= flit_in[15:0];
									neuron_id_reg <= neuron_id;
								end
							PACKET_TYPE_PREHISTORY:
								begin
									packet_buffer[7:0] <= flit_in[7:0];
									axon_id_reg <= axon_id_prehistory;
									neuron_id_reg <= neuron_id;
								end
							PACKET_TYPE_CONFIG_A:
								begin
									neuron_id_reg <= neuron_id;
									if (parameter_type == PARAMETER_LTP_RATE)
										packet_buffer[DSIZE*2+1-1:DSIZE+1] <= flit_in[15:0];
									else if (parameter_type == PARAMETER_LTD_RATE)
										packet_buffer[DSIZE+1-1:1] <= flit_in[15:0];
									else if (parameter_type == PARAMETER_STDP_WINDOW)
										begin
											packet_buffer[STDP_WIN_BIT_WIDTH*2+DSIZE*2+1-1:DSIZE*2+1] <= flit_in[15:0];
											packet_buffer[0] <= flit_in[16];
										end
								end
							PACKET_TYPE_CONFIG_B:
								begin
									neuron_id_reg <= neuron_id;
									if (parameter_type == PARAMETER_TYPE_RAND_AERNUMBER)
										begin
											packet_buffer[1+1+DSIZE*3+4-1] <= flit_in[5];
											packet_buffer[1+1+DSIZE*3+4-2] <= flit_in[4];
											packet_buffer[3:0] <= flit_in[3:0];
										end
									else if (parameter_type == PARAMETER_MASK)
										packet_buffer[DSIZE*3+4-1:DSIZE*2+4] <= flit_in[15:0];
									else if (parameter_type == PARAMETER_REST_POTENTIAL)
										packet_buffer[DSIZE*2+4-1:DSIZE+4] <= flit_in[15:0];
									else if (parameter_type == PARAMETER_FIXED_THRESOLD)
										packet_buffer[DSIZE+4-1:DSIZE] <= flit_in[15:0];
								end
							PACKET_TYPE_AER:
								begin
									neuron_id_reg <= neuron_id;
									if (parameter_type == PARAMETER_COORDINATE)
										packet_buffer[15:0] <= flit_in[15:0];
									else if (parameter_type == PARAMETER_PAYLOAD)
										packet_buffer[31:16] = flit_in[31:16];
								end
							PACKET_AXON_MODE:
								begin
									neuron_id_reg <= neuron_id;
									axon_range_reg <= axon_range;
									if (axon_offset == PARAMETER_AXON_OFFSET_15_0)
										packet_buffer[15:0] <= flit_in[15:0];
									else if (axon_offset == PARAMETER_AXON_OFFSET_31_16)
										packet_buffer[31:16] <= flit_in[15:0];
									else if (axon_offset == PARAMETER_AXON_OFFSET_47_32)
										packet_buffer[47:32] <= flit_in[15:0];
									else if (axon_offset == PARAMETER_AXON_OFFSET_63_48)
										packet_buffer[63:48] <= flit_in[15:0];
								end
							PACKET_TYPE_WEIGHT:
								begin
									if (parameter_type == PARAMETER_TYPE_WEIGHT_ADDRESS)
										begin
											neuron_id_reg <= neuron_id;
											axon_id_reg <= axon_id_weight;
										end
									else if (parameter_type == PARAMETER_TYPE_WEIGHT_VALUE)
										packet_buffer <= flit_in[15:0];
								end
							PACKET_CORE_CONFIG:
								begin
									packet_buffer <= flit_in[16:0];
								end
							PACKET_AXON_SCALING:
								begin
									packet_buffer <= flit_in[1:0];
									axon_id_reg <= axon_id_scaling;
								end
						endcase
					end
			end

	end

//generate write signal
always @(*)
	begin
		wr_en_potential_o = 1'b0;
		wr_en_threshold_o = 1'b0;
		wr_en_bias_o = 1'b0;
		wr_en_posthistory_o = 1'b0;
		wr_en_configA_o = 1'b0;
		wr_en_configB_o = 1'b0;
		wr_en_AER_o = 1'b0;
		wr_en_weight_o = 1'b0;
		wr_en_prehistory_o = 1'b0;
		wr_en_axonmode_1_o = 1'b0;
		wr_en_axonmode_2_o = 1'b0;
		wr_en_axonmode_3_o = 1'b0;
		wr_en_axonmode_4_o = 1'b0;
		wr_en_coreconfig_o = 1'b0;
		wr_en_scaling_o = 1'b10;

		if (write_memory == 1'b1)
			begin
				case (flit_type_reg)
					FLIT_TYPE_POTENTIAL:
						wr_en_potential_o = 1'b1;
					FLIT_TYPE_THRESHOLD:
						wr_en_threshold_o = 1'b1;
					FLIT_TYPE_BIAS:
						wr_en_bias_o = 1'b1;
					FLIT_TYPE_POSTHISTORY:
						wr_en_posthistory_o = 1'b1;
					FLIT_TYPE_CONFIG_A:
						wr_en_configA_o = 1'b1;
					FLIT_TYPE_CONFIG_B:
						wr_en_configB_o = 1'b1;
					FLIT_TYPE_AER:
						wr_en_AER_o = 1'b1;
					FLIT_TYPE_WEIGHT:
						wr_en_weight_o = 1'b1;
					FLIT_TYPE_PREHISTORY:
						wr_en_prehistory_o = 1'b1;
					FLIT_AXON_MODE:
						begin
							if (axon_range_reg == 2'b00)
								wr_en_axonmode_1_o = 1'b1;
							else if (axon_range_reg == 2'b01)
								wr_en_axonmode_2_o = 1'b1;
							else if (axon_range_reg == 2'b01)
								wr_en_axonmode_3_o = 1'b1;
							else if (axon_range_reg == 2'b01)
								wr_en_axonmode_4_o = 1'b1;
						end			
					FLIT_CORE_CONFIG:
						wr_en_coreconfig_o = 1'b1;
					FLIT_AXON_SCALING:
						wr_en_scaling_o = 1'b1;
				endcase
			end
	end

// address generate
assign address_bias = neuron_id_reg;
assign address_potential = neuron_id_reg;
assign address_threshold = neuron_id_reg;
assign address_posthistory = neuron_id_reg;
assign address_preshistory = {neuron_id_reg, axon_id_reg};
assign address_weight = {neuron_id_reg, axon_id_reg};
assign address_config_A = neuron_id_reg;
assign address_config_B = neuron_id_reg;
assign address_axonmode = neuron_id_reg;
assign address_AER = neuron_id_reg;
assign address_axon_scaling = axon_id_reg;

endmodule