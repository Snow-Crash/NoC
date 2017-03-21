// 2017.2.20 posedge reset
// 2017.3.13 change port name. buffer_empty to fifo_empty
//           read_buffer to read_fifo

module port(clk, reset, fifo_empty,
stall, flit_in, 
destination_port, 
//next_address_flit, 
//send_finish, 
//routing_result_ready, 
current_address_ready,
read_fifo,
flit_out, request_vector,
destination_full_vector);

parameter packet_size = 32;
parameter address_size = 16;
parameter flit_size = 4;

input clk, reset, fifo_empty, stall;
input [4:0] destination_full_vector;
input [flit_size - 1:0] flit_in;
output [flit_size - 1:0] flit_out;
output [2:0] destination_port;
output current_address_ready, read_fifo;
//output send_flit;
output reg [4:0] request_vector;

reg [address_size - 1:0] current_address_reg;
reg [address_size - 1:0] next_address_reg;
reg [2:0] destination_port_reg;
reg [4:0] request_reg;

wire mux_select;
wire [flit_size - 1:0] mux_out, mux_input1, mux_input2;
wire [2:0] destination_port_wire;
wire shift_current_address, shift_next_address;
wire load_next_address, load_destination_port;
wire [address_size - 1:0] current_address, next_address;
wire [4:0] request_vector_wire;
wire clear_request_reg_wire;
reg destination_full;

address_compute address_compute_unit(.address_in(current_address),
 .next_address(next_address),
 .destination_port(destination_port_wire), .request_vector(request_vector_wire));

port_controller port_controller_unit(.clk(clk), .reset(reset), 
.stall(stall), .current_address_ready(current_address_ready), 
.read_fifo(read_fifo), 
.fifo_empty(fifo_empty), 
.mux_select(mux_select),
.shift_current_address(shift_current_address),
.load_destination_port(load_destination_port),
.shift_next_address(shift_next_address),
.load_next_address(load_next_address),
.clear_request_reg(clear_request_reg_wire),
.destination_full(destination_full));

//mux
//true input1 false input2
assign mux_out = (mux_select) ? mux_input1 : mux_input2;

assign flit_out = mux_out;
assign mux_input1 = flit_in;
assign mux_input2 = next_address_reg[3:0];

//destination_port register
//load destination port when current address is completely loaded
always @(posedge clk or posedge reset)
    begin
        if(reset)
            destination_port_reg <= 0;
        else if(load_destination_port)
            destination_port_reg <= destination_port_wire;
    end
assign destination_port = destination_port_reg;

////////////////////add 2017.2.14//////////////////////////
//request register
//load request vector when current address is completely loaded
//2.17 removeed
always @(posedge clk or posedge clear_request_reg_wire)
    begin
        if(clear_request_reg_wire)
            request_reg <= 0;
        else if(load_destination_port)
            request_reg <= request_vector_wire;
    end

////////////////////add 2017.2.15//////////////////////////
//mux
//when current address is ready, request vector is already obtained from 
//address compute unit, but it has to wait for 1 clk to be written into register
//therefor port cannot request arbiter immediately
//to eliminate this delay, mux select between
//the request output of address compute and request register
always @(*)
    begin
        if (current_address_ready)
            request_vector = request_vector_wire;
        else
            request_vector = request_reg;
    end

// current address register
// a shift register, convert serial flit to 16 bits paraller address
// connect to address compute unit
always @(posedge clk or posedge reset)
    begin
        if(reset)
            begin
                current_address_reg <= 0;
            end
        else if (shift_current_address)
            begin
                current_address_reg[address_size - 5:0] <= current_address_reg[address_size - 1:4];
                current_address_reg[address_size - 1:address_size - 4] <= flit_in;
            end
    end
assign current_address = current_address_reg;

//next address register
//load from address compute unit when current address is avaliable
//when sending packet, start to shift, every clock shift 4 bits
always @(posedge clk or posedge reset)
    begin
        if  (reset)
                next_address_reg <= 0;
        else if (load_next_address)
                next_address_reg <= next_address;
        else if (shift_next_address)
                //next_address_reg <= next_address_reg >> 4;
                next_address_reg <= {4'h0, next_address_reg[address_size - 1:4]};
    end

//full signal mux
always @(*)
    begin
        case(request_vector)
            5'b10000:
                destination_full = destination_full_vector[4];
            5'b01000:
                destination_full = destination_full_vector[3];
            5'b00100:
                destination_full = destination_full_vector[2];
            5'b00010:
                destination_full = destination_full_vector[1];
            5'b00001:
                destination_full = destination_full_vector[0];
            default:
                destination_full = 0;
        endcase
    end

endmodule