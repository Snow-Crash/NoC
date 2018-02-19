`timescale 1ns/100ps
module network_interface(router_clk, router_rst, flit_in_wr, flit_in, credit_in, flit_out_wr, flit_out, credit_out,
        neuron_clk, neuron_rst, start, flit_to_decoder, spike_packet_in, activate_decoder, stall_decoder, class_type_out);

parameter VIRTUAL_CHANNEL = 4;
parameter ADDRESS_WIDTH = 5;
parameter PAYLOAD_WIDTH = 32;
parameter FLIT_WIDTH = PAYLOAD_WIDTH + 2 + VIRTUAL_CHANNEL;

parameter NUM_NURNS = 128;

input router_clk, router_rst, neuron_clk, neuron_rst, start;
//input [ADDRESS_WIDTH-1:0] current_x, current_y;

// input from router
input [VIRTUAL_CHANNEL-1:0] credit_in;
input [2+VIRTUAL_CHANNEL+PAYLOAD_WIDTH-1:0] flit_in;
input flit_in_wr;

// output to router
output flit_out_wr;
output [2+VIRTUAL_CHANNEL+PAYLOAD_WIDTH-1:0] flit_out;
output [VIRTUAL_CHANNEL-1:0] credit_out;

//input from neuron
input spike_packet_in;

//output to decoder
output [2+VIRTUAL_CHANNEL+PAYLOAD_WIDTH-1:0] flit_to_decoder;
output reg stall_decoder, activate_decoder;
output [2:0] class_type_out;


parameter IDLE = 4'd0;
parameter READ_HEADER = 4'd1;
parameter RECEIVE = 4'd2;
parameter STALL = 4'd3;
parameter DONE = 4'd4;



//packet fields
wire [1:0] header;
wire [2:0] class_type;

wire vc_buffer_full, vc_buffer_empty;

//receive state machine
reg [3:0] current_state, next_state;
// transmission status, 0 for idle, 1 for transmission is not finished
reg [FLIT_WIDTH-1:0] pipeline_reg;
wire [FLIT_WIDTH-1:0] vc_buffer_out;
reg vc_buffer_rd, receive_done, set_class_type;
reg pipeline_reg_load;
reg [2:0] class_type_reg;



//decoce state machine

//credit out and vc buffer write en generate
assign credit_out = {~vc_buffer_full, 4'b0000};

assign header = vc_buffer_out[2+VIRTUAL_CHANNEL+PAYLOAD_WIDTH-1:2+VIRTUAL_CHANNEL+PAYLOAD_WIDTH-2];
assign class_type = vc_buffer_out[FLIT_WIDTH-2-VIRTUAL_CHANNEL-1:FLIT_WIDTH-2-VIRTUAL_CHANNEL-3];

assign flit_to_decoder = pipeline_reg;
assign vc_buffer_wr = flit_in_wr;
assign class_type_out = class_type;

//registers
always @(posedge neuron_clk or negedge neuron_rst)
    begin
        if (neuron_rst == 1'b0)
			begin
				pipeline_reg <= 0;
				class_type_reg <= 0;
			end
        else
            begin
				//set current channel
				if (pipeline_reg_load == 1'b1)
					pipeline_reg <= vc_buffer_out;
				
				if (set_class_type == 1'b1)
					class_type_reg <= class_type;

            end
    end

// state machine
always @(posedge neuron_clk or negedge neuron_rst)
    begin
        if (neuron_rst == 1'b0)
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
                    if (vc_buffer_empty != 1'b1)
						next_state = READ_HEADER;
					else
						next_state = IDLE;
                end
			READ_HEADER:
				begin
					next_state = RECEIVE;
				end
			RECEIVE:
				if (header == 2'b01)
					next_state = DONE;
				//receive is not done, but buffer is empty
				else if (vc_buffer_empty == 1'b1)
					next_state = STALL;
				else
					next_state = RECEIVE;
			DONE:
				begin
					if (vc_buffer_empty != 1'b1)
						next_state = READ_HEADER;
					else
						next_state = IDLE;
				end
			STALL:
				if (vc_buffer_empty != 1'b1)
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
		vc_buffer_rd = 1'b0;
		receive_done = 1'b0;
		activate_decoder = 1'b0;
		stall_decoder = 1'b0;
		pipeline_reg_load = 1'b0;
		set_class_type = 1'b0;

		case(current_state)
			IDLE:
				vc_buffer_rd = 1'b0;
			READ_HEADER:
				begin
					vc_buffer_rd = 1'b1;
					activate_decoder = 1'b1;
				end
			RECEIVE:
				begin
					if (vc_buffer_empty == 1'b1)
						vc_buffer_rd = 1'b0;
					//read tail
					else if (header == 2'b01)
						vc_buffer_rd = 1'b0;
					else
						vc_buffer_rd = 1'b1;

					if (header == 2'b10)
						begin
							set_class_type = 1'b1;
						end

					pipeline_reg_load = 1'b1;
				end
			DONE:
				begin
					receive_done = 1'b1;
				end
			STALL:
				begin
					vc_buffer_rd = 1'b0;
					stall_decoder = 1'b1;
				end
		endcase
	end




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
	.we(vc_buffer_wr),
	.dout(vc_buffer_out), 
	.re(vc_buffer_rd), 
	.full(vc_buffer_full), 
	.empty(vc_buffer_empty), 
	.wr_level(), 
	.rd_level() 
);

endmodule