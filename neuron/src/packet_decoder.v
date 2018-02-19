module packet_decoder(neuron_clk, neuron_rst, start, activate_decoder, stall_decoder, flit_in, spike_out, mem_data_out, class_type_in);

parameter NUM_AXONS = 256;
parameter AXON_CNT_BIT_WIDTH = 8;
parameter NURN_CNT_BIT_WIDTH = 8;
parameter STDP_WIN_BIT_WIDTH = 8;
parameter DSIZE = 16;


parameter FLIT_WIDTH = 38;
parameter VIRTUAL_CHANNEL = 4;
parameter PAYLOAD_WIDTH = 32;

input neuron_clk, neuron_rst, start;
input [FLIT_WIDTH-1:0] flit_in;
output [NUM_AXONS:0] spike_out;
input [2:0] class_type_in;
input activate_decoder, stall_decoder;
output [63:0] mem_data_out;

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

wire [2+VIRTUAL_CHANNEL+PAYLOAD_WIDTH-1:2+VIRTUAL_CHANNEL+PAYLOAD_WIDTH-2] header;
wire [3:0] flit_type;
wire [1:0] parameter_type;
wire [1:0] axon_offset;
wire [1:0] axon_range;
wire [AXON_CNT_BIT_WIDTH-1:0] axon_id_weight, axon_id_spike, axon_id_prehistory;
wire [NURN_CNT_BIT_WIDTH-1:0] neuron_id;

//class type
parameter CLASS_TYPE_SPIKE = 3'd0;
parameter CLASS_TYPE_WEIGHT = 1'd1;
parameter CLASS_TYPE_INITIALIZE = 3'd2;

//packet type define
parameter FLIT_TYPE_BIAS = 4'd0;
parameter FLIT_TYPE_THRESHOLD = 4'd1;
parameter FLIT_TYPE_POTENTIAL = 4'd2;
parameter FLIT_TYPE_POSTHISTORY = 4'd3;
parameter FLIT_TYPE_PREHISTORY = 4'd4;
parameter FLIT_TYPE_CONFIG_A = 4'd5;
parameter FLIT_TYPE_COMFIG_B = 4'd6;
parameter FLIT_TYPE_AER = 4'd7;
parameter FLIT_AXON_MODE = 4'd8;
parameter FLIT_AXON_SCLAING = 4'd9;
parameter FLIT_CORE_CONFIG = 4'd10;

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

reg [NUM_AXONS-1:0] spike_buffer;
reg load_bias, load_potential, load_threshold, load_posthistory;
reg load_prehistory, load_weight, load_ltp_rate, load_ltd_rate, load_window;
reg load_type_rand_aernumber, load_mask, load_rest_potential, load_fixed_threshold;
reg load_coordinate, load_payload;
reg load_axon_mode;

//fields
assign flit_type = flit_in[FLIT_WIDTH-1-2-VIRTUAL_CHANNEL:FLIT_WIDTH-2-VIRTUAL_CHANNEL-4];
assign parameter_type = flit_in[19:18];
assign neuron_id = flit_in[27:20];
assign axon_id_weight = flit_in[23:16];
assign axon_id_spike = flit_in[23:16];
assign axon_id_prehistory = flit_in[15:8];
assign axon_range = flit_in[19:18];
assign axon_offset = flit_in[17:16];
assign header = flit_in[2+VIRTUAL_CHANNEL+PAYLOAD_WIDTH-1:2+VIRTUAL_CHANNEL+PAYLOAD_WIDTH-2];

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
					else if ((class_type_reg == 3'd1) ||(class_type_reg == 3'd2) )
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

always @(posedge neuron_clk or negedge neuron_rst)
	begin
		if (neuron_rst == 1'b0)
			packet_buffer <= 0;
		else
			begin
				if (load_buffer == 1'b1)
					begin
						case(flit_type)
							FLIT_TYPE_POTENTIAL:
								packet_buffer[15:0] <= flit_in[15:0];
							FLIT_TYPE_THRESHOLD:
								packet_buffer[15:0] <= flit_in[15:0];
							FLIT_TYPE_POSTHISTORY:
								packet_buffer[15:0] <= flit_in[15:0];
							FLIT_TYPE_BIAS:
								packet_buffer[15:0] <= flit_in[15:0];
							FLIT_TYPE_PREHISTORY:
								packet_buffer[7:0] <= flit_in[7:0];
							FLIT_TYPE_CONFIG_A:
								begin
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
							FLIT_TYPE_COMFIG_B:
								begin
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
							FLIT_TYPE_AER:
								begin
									if (parameter_type == PARAMETER_COORDINATE)
										packet_buffer[15:0] <= flit_in[15:0];
									else if (parameter_type == PARAMETER_PAYLOAD)
										packet_buffer[31:16] = flit_in[31:16];
								end
							FLIT_AXON_MODE:
								begin
									if (axon_offset == PARAMETER_AXON_OFFSET_15_0)
										packet_buffer[15:0] <= flit_in[15:0];
									else if (axon_offset == PARAMETER_AXON_OFFSET_31_16)
										packet_buffer[31:16] <= flit_in[15:0];
									else if (axon_offset == PARAMETER_AXON_OFFSET_47_32)
										packet_buffer[47:32] <= flit_in[15:0];
									else if (axon_offset == PARAMETER_AXON_OFFSET_63_48)
										packet_buffer[63:48] <= flit_in[15:0];
								end
						endcase
					end
			end

	end

always @(*)
	begin



	end


endmodule