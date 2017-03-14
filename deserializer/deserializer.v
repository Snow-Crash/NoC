`include "sipo_shift_register.v"
`include "deserializer_controller.v"

module deserializer (clk, reset, receive, deserializer_idle, deserializer_finish,
 data_in, data_out);

parameter input_size = 4;
parameter output_size = 32;

input clk, reset, receive;
output deserializer_finish, deserializer_idle;
input [input_size-1:0] data_in;
output [output_size - 1:0] data_out;

sipo_shift_register sipo_reg(.clk(clk), .data_in(data_in), .data_out(data_out), .reset(reset));

deserializer_controller deserializer_controll(.clk(clk), .reset(reset), .receive(receive),
    .deserializer_idle(deserializer_idle), .deserializer_finish(deserializer_finish));

endmodule // 