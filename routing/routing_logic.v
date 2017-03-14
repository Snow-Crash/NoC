`include "address_compute.v"
`include "routing_controller.v"
`include "routing_controller_2.v"

module routing_logic(clk, reset, compute_address, 
stall, address_flit_in, 
destination_port, 
next_address_flit, 
send_finish, 
next_address_ready, 
current_address_ready);

parameter input_size = 4;
parameter address_size = 16;
localparam address_flit_number = address_size / input_size;

input clk, reset, compute_address, stall;
input [input_size - 1:0] address_flit_in;

output [2:0] destination_port;
output [input_size - 1:0] next_address_flit;
//output [address_size - 1:0] current_address;
output send_finish, next_address_ready, current_address_ready;


reg [address_size - 1:0] current_address_reg;
reg [address_size - 1:0] next_address_reg;
reg [2:0] destination_port_reg;


wire [address_size-1:0] next_address;
wire [address_size-1:0] current_address;
wire [2:0] destination_port_wire;
wire shift_current_address;
wire load_destination_port;
wire shift_next_address;
wire load_next_address;

address_compute address_compute_unit(.address_in(current_address),
 .next_address(next_address),
 .destination_port(destination_port_wire));


routing_controller2 routing_controller_unit2(.clk(clk), .reset(reset),
.compute_address(compute_address), 
.shift_current_address(shift_current_address), 
.stall(stall),
.current_address_ready(current_address_ready),
.next_address_ready(next_address_ready), 
.send_finish(send_finish),
.load_destination_port(load_destination_port), 
.shift_next_address(shift_next_address), 
.load_next_address(load_next_address));


//destination_port register
//load destination port when current address is completely loaded
always @(posedge clk or reset)
    begin
        if(reset)
            destination_port_reg <= 0;
        else if(load_destination_port)
            destination_port_reg <= destination_port_wire;
    end
assign destination_port = destination_port_reg;

// current address register
// a shift register, convert serial flit to 16 bits paraller address
// connect to address compute unit
always @(posedge clk or reset)
    begin
        if(reset)
            begin
                current_address_reg <= 0;
            end
        else if (shift_current_address)
            begin
                current_address_reg[address_size - 5:0] <= current_address_reg[address_size - 1:4];
                current_address_reg[address_size - 1:address_size - 4] <= address_flit_in;
            end
    end
assign current_address = current_address_reg;

//next address register
//load from address compute unit when current address is avaliable
//when sending packet, start to shift, every clock shift 4 bits
always @(posedge clk or reset)
    begin
        if  (reset)
                next_address_reg <= 0;
        else if (load_next_address)
                next_address_reg <= next_address;
        else if (shift_next_address)
                //next_address_reg <= next_address_reg >> 4;
                next_address_reg <= {4'h0, next_address_reg[address_size - 1:4]};
    end

assign next_address_flit = next_address_reg[3:0];

endmodule