`include "address_compute.v"
`include "routing_controller.v"
`include "routing_logic.v"
module routing_logic_tb;

parameter flit_size = 4;
parameter address_siz4 = 16;

reg clk, reset, compute_address, stall;
reg [flit_size - 1:0] address_flit_in;

wire [2:0] destination_port;
wire [flit_size - 1:0] next_address_flit;
wire send_finish, next_address_ready, current_address_ready; 

routing_logic dut(.clk(clk), .reset(reset), 
.compute_address(compute_address), 
.stall(stall), .address_flit_in(address_flit_in), 
.destination_port(destination_port), 
.next_address_flit(next_address_flit), 
.send_finish(send_finish), 
.next_address_ready(next_address_ready), 
.current_address_ready(current_address_ready));

always 
    #10 clk = ~clk;

initial
    begin
        clk = 1;
        reset = 1;
        compute_address = 0;
        stall = 0;
        address_flit_in = 4'h0;
        #20
        reset = 0;
        compute_address = 1;
        address_flit_in = 4'h1;
        #20
        compute_address = 0;
        address_flit_in = 4'h2;
        #20
        address_flit_in = 4'h3;
        #20
        address_flit_in = 4'h4;
        #20
        address_flit_in = 4'h5;
        #20 stall = 1;
        #80 stall = 0;
    end
endmodule
