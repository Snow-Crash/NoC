//`include "write_pointer_full_generate.v"
//`include "read_pointer_empty_generate.v"
//`include "read_to_write_sync.v"
//`include "write_to_read_sync.v"
//`include "fifo_memory.v"

module async_fifo (data_in, data_out, write_clk, read_clk, write_reset, read_reset, 
    write_inc, read_inc, write_full, read_empty);

localparam input_size = 4;
localparam address_size = 4;

input [input_size - 1:0] data_in;
output [input_size - 1:0] data_out;
input write_clk, read_clk, write_reset, read_reset, write_inc, read_inc;
output write_full, read_empty;


wire [address_size - 1: 0] read_address_wire, write_address_wire;
wire write_full_wire;
wire [address_size:0] write_gray_pointer_wire,read_gray_pointer_wire, synchronized_write_pointer2_wire, synchronized_read_pointer2_wire;

assign write_full = write_full_wire;

fifo_memory fifo_mem (.data_in(data_in), .data_out(data_out), .read_address(read_address_wire), 
    .write_address(write_address_wire), .write_clk(write_clk), .write_inc(write_inc), .write_full(write_full_wire));

read_pointer_empty_generate read_logic(.read_address(read_address_wire), .read_gray_pointer(read_gray_pointer_wire),
    .read_clk(read_clk), .read_reset(read_reset), .read_inc(read_inc), .read_empty(read_empty), .synchronized_write_pointer2(synchronized_write_pointer2_wire));

write_pointer_full_generate write_logic(.write_clk(write_clk), .write_reset(write_reset), .write_inc(write_inc), 
    .synchronized_read_pointer2(synchronized_read_pointer2_wire), .write_full(write_full_wire), .write_address(write_address_wire),
    .write_gray_pointer(write_gray_pointer_wire));

read_to_write_sync read_to_write(.read_pointer(read_gray_pointer_wire), .write_clk(write_clk), .write_reset(write_reset),
    .synchronized_read_pointer2(synchronized_read_pointer2_wire));

write_to_read_sync write_to_read(.write_pointer(write_gray_pointer_wire), .read_clk(read_clk), .read_reset(read_reset),
.synchronized_write_pointer2(synchronized_write_pointer2_wire));


endmodule