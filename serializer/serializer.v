//`include "serializer_controller.v"
//`include "piso_shift_register.v"

module serializer (clk, reset, data_in, data_out, fifo_empty, serializer_idle, read_fifo);

localparam input_size = 32;
localparam output_size = 4;


input clk, reset, fifo_empty, read_fifo;
input [input_size - 1:0] data_in;
output serializer_idle;
output [output_size - 1:0] data_out;

wire shift_register_load;

piso_shift_register piso_shift_register_instance(.data_in(data_in), .data_out(data_out),
    .clk(clk), .load(shift_register_load), .reset(reset));

serializer_controller serializer_controller_instance(.clk(clk), .reset(reset), .fifo_empty(fifo_empty),
    .read_fifo(read_fifo), .shift_register_load(shift_register_load), .serializer_idle(serializer_idle));

endmodule
