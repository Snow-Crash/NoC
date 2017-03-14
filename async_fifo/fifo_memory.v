//`include "dual_port_ram.v"

module fifo_memory (data_in, data_out, read_address, write_address, write_clk, write_inc, write_full);



localparam input_size = 4;
localparam address_size = 4;

input [input_size - 1:0] data_in;
input [address_size - 1:0] read_address, write_address;
input write_clk, write_inc, write_full;
output [input_size - 1:0] data_out;

wire write_clk_enable;

//write_inc is write enable signal
//write_clk_enable connects to write_enable port.
//if write_inc is high, and write_full is high, write_clk_enable is low, cannot write data
assign write_clk_enable = !write_full && write_inc;

dual_port_ram fifo_memory(.data_in(data_in), .data_out(data_out),
 .write_clk(write_clk), .write_address(write_address),
  .read_address(read_address), .write_enable(write_clk_enable));



endmodule // data_in, data_out, 