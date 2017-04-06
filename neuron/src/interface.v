//2017.3.23     Interface contains a async fifo. The fifo has a narrow input port and 
//              a wide output port. It can buffer packet and recover a complete packets 
//              from 8 flits.
//              Empty flag is also used to control read fifo. Fifo read request signal is
//              generated from empty signal through a NOT gate.
//              Beacuse fifo's output is valid 1 clock later after read request signal
//              read_req is sent to a FF write_spike, write_spike acts as write enabe signal
//              of spike reg.
//              axon_id is used to index spike reg and determines which bit will be set to 1
//2017.3.25     Add clear signal for spike_reg. spike_reg is cleared after start signal
//2017.4.6      line 74 blocking to non-blocking
module interface (router_clk, neuron_clk, rst_n, router_reset, write_en, start, data_in, spike, neuron_full);

parameter packet_size = 32;
parameter flit_size = 4;
parameter x_address_length = 8;
parameter y_address_length = 8;
parameter NUM_AXONS = 2;
parameter AXON_CNT_BIT_WIDTH = 1;

input router_clk, neuron_clk, rst_n, start, router_reset, write_en;
input [flit_size - 1:0] data_in;
output [NUM_AXONS - 1:0] spike;
//output read_req;
output neuron_full;

wire [packet_size - 1:0] data_out;

reg [NUM_AXONS - 1:0] spike_reg;
reg clear_spike_reg;

wire [AXON_CNT_BIT_WIDTH - 1:0] axon_address;
wire spikebuffer_empty, read_spikebuffer_req;
wire [AXON_CNT_BIT_WIDTH - 1:0] axon_id;
wire [packet_size - 1:0] packet;
reg write_spike;

spikebuf spikebuffer (
	.aclr ( router_reset ),
	.data ( data_in ),
	.rdclk ( neuron_clk ),
	.rdreq ( read_spikebuffer_req ),
	.wrclk ( router_clk ),
	.wrreq ( write_en ),
	.q ( packet ),
	.rdempty ( spikebuffer_empty ),
	.wrfull ( neuron_full )
	);

//decode
//assign decoded_spike = (enable) ? (1 << axon_address) : 0;
//assign decoded_spike = 1 << axon_address : 0;

assign read_spikebuffer_req = ~ spikebuffer_empty;

assign axon_id = packet[x_address_length + y_address_length + AXON_CNT_BIT_WIDTH - 1:x_address_length + y_address_length];

//write_spike signal is 1 clock later than read_spikebuffer_req
always @(posedge neuron_clk or negedge rst_n)
    begin
        if(rst_n == 0)
            write_spike <= 0;
        else
            write_spike <= read_spikebuffer_req;
    end

always @(posedge neuron_clk or negedge rst_n )
    begin
        if (rst_n == 0)
            spike_reg <= 0;
        else if(clear_spike_reg == 1)
            spike_reg <= 0;
        else if(write_spike)
            spike_reg[axon_id] <= 1'b1;
    end
assign spike = spike_reg;


always @(posedge neuron_clk)
    begin
        clear_spike_reg <= start;
    end


endmodule