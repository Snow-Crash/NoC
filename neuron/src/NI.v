`timescale 1ns/100ps
module NI(router_clk, router_rst, flit_in_wr, flit_in, credit_in, flit_out_wr, flit_out, credit_out,
        neuron_clk, neuron_rst, start, packet_out, spike_packet_in);

parameter VIRTUAL_CHANNEL = 4;
parameter ADDRESS_WIDTH = 5;
parameter FLIT_WIDTH = 38;

parameter NUM_NURNS = 128;



input router_clk, router_rst, neuron_clk, neuron_rst, start;
//input [ADDRESS_WIDTH-1:0] current_x, current_y;
input [VIRTUAL_CHANNEL-1:0] credit_in;
input [2+VIRTUAL_CHANNEL+32-1:0] flit_in;
input flit_in_wr;
input spike_packet_in;

output flit_out_wr;
output [2+VIRTUAL_CHANNEL+32-1:0] flit_out;
output reg [VIRTUAL_CHANNEL-1:0] credit_out;
output packet_out;

parameter IDLE = 4'd0;
parameter SET_CHANNEL = 4'd1;
parameter RECEIVE = 4'd2;
parameter STALL = 4'd3;
parameter DONE = 4'd4;


parameter DC_IDLE = 3'b0;
parameter DC_SET_TYPE = 3'b1;
parameter DC_BUFFER = 3'b2;
parameter DC_STALL = 3'b3;
parameter DC_DECODE = 3'b4;

//wires for buffers
wire [FLIT_WIDTH-1:0] vc_0_do, vc_1_do, vc_2_do, vc_3_do;
//MSB stnads for vc 3, LSB stands for vc 0
wire [3:0] vc_buffer_empty, vc_buffer_full;
reg vc_0_buffer_wr, vc_1_buffer_wr, vc_2_buffer_wr, vc_3_buffer_wr;
reg vc_0_buffer_rd, vc_1_buffer_rd, vc_2_buffer_rd, vc_3_buffer_rd;

wire [1:0] header;

//receive state machine
reg [3:0] current_state, next_state;
// transmission status, 0 for idle, 1 for transmission is not finished
reg [VIRTUAL_CHANNEL-1:0] channel_state;
reg [1:0] avaliable_channel_id;
reg [FLIT_WIDTH-1:0] vc_buffer_out_mux;
reg set_current_channel, set_channel_used, set_channel_idle;
reg current_channel_empty;
//reg [3:0] current_channel_reg;	//one hot
reg [2:0] current_channel_id;	//
reg vc_buffer_rd, receive_done;
reg stall_decoder, activate_decoder, pipeline_reg_load;

//decode packet state machine
reg [3:0] decoder_cs, decoder_ns;

//decoder regs
reg [FLIT_WIDTH-1:0] pipeline_reg;
reg write_memory, shift_reg, set_packet_type;
reg [2:0] packet_type;
reg [NUM_NURNS-1:0] shifter;


//decoce state machine

//credit out and vc buffer write en generate
always @(*)
	begin
		vc_0_buffer_wr = 1'b0;
		vc_1_buffer_wr = 1'b0;
		vc_2_buffer_wr = 1'b0;
		vc_3_buffer_wr = 1'b0;

		if (vc_buffer_full[0] == 1'b0)
			begin
				credit_out = 4'b0001;
				vc_0_buffer_wr = flit_in_wr;
			end
		else if (vc_buffer_full[1] == 1'b0)
			begin
				credit_out = 4'b0010;
				vc_1_buffer_wr = flit_in_wr;
			end
		else if (vc_buffer_full[2] == 1'b0)
			begin
				credit_out = 4'b0100;
				vc_2_buffer_wr = flit_in_wr;
			end
		else if (vc_buffer_full[3] == 1'b0)
			begin
				credit_out = 4'b1000;
				vc_3_buffer_wr = flit_in_wr;
			end
		else
			begin
				credit_out = 4'b0000;
				vc_0_buffer_wr = 1'b0;
				vc_1_buffer_wr = 1'b0;
				vc_2_buffer_wr = 1'b0;
				vc_3_buffer_wr = 1'b0;
			end
	end


//combinational logics
always @(*)
	begin
		vc_0_buffer_rd = 1'b0;
		vc_1_buffer_rd = 1'b0;
		vc_2_buffer_rd = 1'b0;
		vc_3_buffer_rd = 1'b0;
		avaliable_channel_id = 2'd0;

		//based on buffer status, select a channel as current channel
		//channel 0 has highest priority
		if (vc_buffer_empty[0] != 1'b1)
				avaliable_channel_id = 2'd0;
		else if (vc_buffer_empty[1] != 1'b1)
				avaliable_channel_id = 2'd1;
		else if (vc_buffer_empty[2] != 1'b1)
				avaliable_channel_id = 2'd2;
		else if (vc_buffer_empty[3] != 1'b1)
				avaliable_channel_id = 2'd3;

		current_channel_empty = vc_buffer_empty[current_channel_id];
		
		if (vc_buffer_rd == 1'b1)
			begin
				if (current_channel_id == 3'd0)
					vc_0_buffer_rd = 1'b1;
				else if (current_channel_id == 3'd1)
					vc_1_buffer_rd = 1'b1;
				else if (current_channel_id == 3'd2)
					vc_2_buffer_rd = 1'b1;
				else if (current_channel_id == 3'd3)
					vc_3_buffer_rd = 1'b1;
			end
		
		//mux select vc buffer output
		if (current_channel_id == 3'd0)
			vc_buffer_out_mux = vc_0_do;
		else if (current_channel_id == 3'd1)
			vc_buffer_out_mux = vc_1_do;
		else if (current_channel_id == 3'd2)
			vc_buffer_out_mux = vc_2_do;
		else if (current_channel_id == 3'd3)
			vc_buffer_out_mux = vc_3_do;
		else
			vc_buffer_out_mux = 0;
	end

assign header = vc_buffer_out_mux[2+VIRTUAL_CHANNEL+32-1:2+VIRTUAL_CHANNEL+32-2];

//registers
always @(posedge neuron_clk or posedge neuron_rst)
    begin
        if (router_rst == 1'b0)
			begin
            	current_channel_id <= 0;
				channel_state <= 0;
				pipeline_reg <= 0;
			end
        else
            begin
				//set current channel
                if (set_current_channel == 1'b1)
						current_channel_id <= avaliable_channel_id;
				
				if (set_channel_used == 1'b1)
					channel_state[avaliable_channel_id] <= 1'b1;
				
				if (set_channel_idle == 1'b1)
					channel_state[current_channel_id] <= 1'b0;
				
				if (pipeline_reg_load == 1'b1)
					pipeline_reg_load <= vc_buffer_out_mux;

            end
    end


// state machine
always @(posedge neuron_clk or posedge neuron_rst)
    begin
        if (router_rst == 1'b1)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

//state transition
always @(*)
    begin
        case(current_state)
            IDLE:
                begin
					//not all channel empty
                    if (vc_buffer_empty != 4'b1111)
						next_state = SET_CHANNEL;
					else
						next_state = IDLE;
                end
			SET_CHANNEL:
				begin
					next_state = RECEIVE;
				end
			RECEIVE:
				if (header == 2'b01)
					next_state = DONE;
				//receive is not done, but buffer is empty
				else if (current_channel_empty == 1'b1)
					next_state = STALL;
				else
					next_state = RECEIVE;
			DONE:
				begin
					if (vc_buffer_empty != 4'b1111)
						next_state = SET_CHANNEL;
					else
						next_state = IDLE;
				end
			STALL:
				if (current_channel_empty != 1'b1)
					next_state = RECEIVE;
				else
					next_state = STALL;
			default:
				next_state = IDLE;
		endcase
    end


//combination logic output of state machine
always @(*)
	begin
		set_channel_used = 1'b0;
		set_current_channel = 1'b0;
		vc_buffer_rd = 1'b0;
		set_channel_idle = 1'b0;
		receive_done = 1'b0;
		activate_decoder = 1'b0;
		stall_decoder = 1'b0;
		pipeline_reg_load = 1'b0;

		case(current_state)
			IDLE:
				vc_buffer_rd = 1'b0;
			SET_CHANNEL:
				begin
					set_channel_used = 1'b1;
					set_current_channel = 1'b1;
					vc_buffer_rd = 1'b1;
					activate_decoder = 1'b1;
				end
			RECEIVE:
				begin
					if (current_channel_empty == 1'b1)
						vc_buffer_rd = 1'b0;
					else
						vc_buffer_rd = 1'b1;

					if (header == 2'b01)
						begin
							vc_buffer_rd = 1'b0;
						end
					pipeline_reg_load = 1'b1;
				end
			DONE:
				begin
					receive_done = 1'b1;
					set_channel_idle = 1'b1;
				end
			STALL:
				begin
					vc_buffer_rd = 1'b0;
					stall_decoder = 1'b1;
				end
		endcase
	end

always @(posedge neuron_rst or posedge neuron_clk)
	begin
		if (router_rst == 1'b1)
			decoder_cs <= IDLE;
		else
			decoder_cs <= decoder_ns;
	end

always @(*)
	begin
		case(decoder_cs):
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
	end
// decode combinational logic outpus
always @(*)
	begin

		case(decoder_cs)
			DC_IDLE:
				begin
					write_memory = 1'b0;
					set_packet_type = 1'b0;
					shift_reg = 1'b0;
				end
			DC_SET_TYPE:
				begin
					set_packet_type = 1'b1;
				end
			DC_BUFFER:
				begin
					write_memory = 1'b0;
					shift_reg = 1'b1;
					shift_reg = 1'b0;
				end
			DC_STALL:
				begin
					write_memory = 1'b0;
					set_packet_type = 1'b0;
					shift_reg = 1'b0;
				end
			DC_WRITE:
				begin
					write_memory = 1'b1;
					set_packet_type = 1'b0;
					shift_reg = 1'b0;
				end
			default:
				begin
					write_memory = 1'b0;
					set_packet_type = 1'b0;
					shift_reg = 1'b0;
				end
	end

//decoder registers
always @(posedge neuron_clk or posedge neuron_rst)
	begin
		if (neuron_rst == 1'b1)
			begin
				packet_out = 0;
				shifter = 0;
			end
		else
			begin
				if (set_packet_type == 1'b1)



			end



	end


// 	end

generic_fifo_dc_gray
#(
	.dw(FLIT_WIDTH),
	.aw(3)
)
vc_0_fifo
(	.rd_clk(neuron_clk), 
	.wr_clk(router_clk), 
	.rst(~router_rst), 
	.clr(start), 
	.din(flit_in), 
	.we(vc_0_buffer_wr),
	.dout(vc_0_do), 
	.re(vc_0_buffer_rd), 
	.full(vc_buffer_full[0]), 
	.empty(vc_buffer_empty[0]), 
	.wr_level(), 
	.rd_level() 
);

generic_fifo_dc_gray
#(
	.dw(FLIT_WIDTH),
	.aw(3)
)
vc_1_fifo
(	.rd_clk(neuron_clk), 
	.wr_clk(router_clk), 
	.rst(~router_rst), 
	.clr(start), 
	.din(flit_in), 
	.we(vc_1_buffer_wr),
	.dout(vc_1_do), 
	.re(vc_1_buffer_rd), 
	.full(vc_buffer_full[1]), 
	.empty(vc_buffer_empty[1]), 
	.wr_level(), 
	.rd_level() 
);

generic_fifo_dc_gray
#(
	.dw(FLIT_WIDTH),
	.aw(3)
)
vc_2_fifo
(	.rd_clk(neuron_clk), 
	.wr_clk(router_clk), 
	.rst(~router_rst), 
	.clr(start), 
	.din(flit_in), 
	.we(vc_2_buffer_wr),
	.dout(vc_2_do), 
	.re(vc_2_buffer_rd), 
	.full(vc_buffer_full[2]), 
	.empty(vc_buffer_empty[2]), 
	.wr_level(), 
	.rd_level() 
);

generic_fifo_dc_gray
#(
	.dw(FLIT_WIDTH),
	.aw(3)
)
vc_3_fifo
(	.rd_clk(neuron_clk), 
	.wr_clk(router_clk), 
	.rst(~router_rst), 
	.clr(start), 
	.din(flit_in), 
	.we(vc_3_buffer_wr),
	.dout(vc_3_do), 
	.re(vc_3_buffer_rd), 
	.full(vc_buffer_full[3]), 
	.empty(vc_buffer_empty[3]), 
	.wr_level(), 
	.rd_level() 
);

/*
//virtual channel 0 fifo
generic_fifo_sc_b
#(
	.dw(38),
	.aw(3)
)
vc_0_fifo
(
	.clk(router_clk), 
	.rst(~router_rst), 
	.clr(start_i), 
	.din(flit_in), 
	.we(vc_0_buffer_wr), 
	.dout(vc_0_do), 
	.re(vc_0_buffer_rd),
	.full(vc_buffer_full[0]), 
	.empty(vc_buffer_empty[0]), 
	.full_r(),
	.empty_r(),
	.full_n(), 
	.empty_n(), 
	.full_n_r(), 
	.empty_n_r(),
	.level()
);

//virtual channel 0 fifo
generic_fifo_sc_b
#(
	.dw(38),
	.aw(3)
)
vc_1_fifo
(
	.clk(router_clk), 
	.rst(~router_rst), 
	.clr(start_i), 
	.din(flit_in), 
	.we(vc_1_buffer_wr), 
	.dout(vc_1_do), 
	.re(vc_1_buffer_rd),
	.full(vc_buffer_full[1]), 
	.empty(vc_buffer_empty[1]), 
	.full_r(),
	.empty_r(),
	.full_n(), 
	.empty_n(), 
	.full_n_r(), 
	.empty_n_r(),
	.level()
);

//virtual channel 0 fifo
generic_fifo_sc_b
#(
	.dw(38),
	.aw(3)
)
vc_2_fifo
(
	.clk(router_clk), 
	.rst(~router_rst), 
	.clr(start_i), 
	.din(flit_in), 
	.we(vc_2_buffer_wr), 
	.dout(vc_2_do), 
	.re(vc_2_buffer_rd),
	.full(vc_buffer_full[2]), 
	.empty(vc_buffer_empty[2]), 
	.full_r(),
	.empty_r(),
	.full_n(), 
	.empty_n(), 
	.full_n_r(), 
	.empty_n_r(),
	.level()
);

//virtual channel 0 fifo
generic_fifo_sc_b
#(
	.dw(38),
	.aw(3)
)
vc_3_fifo
(
	.clk(router_clk), 
	.rst(~router_rst), 
	.clr(start_i), 
	.din(flit_in), 
	.we(vc_3_buffer_wr), 
	.dout(vc_3_do), 
	.re(vc_3_buffer_rd),
	.full(vc_buffer_full[3]), 
	.empty(vc_buffer_empty[3]), 
	.full_r(),
	.empty_r(),
	.full_n(), 
	.empty_n(), 
	.full_n_r(), 
	.empty_n_r(),
	.level()
);
*/

endmodule