`include "sipo_shift_register.v"

module sipo_shift_register_tb;

localparam input_size = 4;
localparam output_size = 32;

reg [input_size - 1:0] data_in;
reg clk, reset;
wire [output_size - 1:0] data_out;


sipo_shift_register dut(.data_in(data_in), .data_out(data_out), .reset(reset), .clk(clk));

always
    #10 clk = ~clk;

initial
    begin
    clk = 0;
    #10 reset = 1;
    #20 reset = 0;
    data_in = 4'hd;
    #20 data_in = 4'hc;
    #20 data_in = 4'hb;
    #20 data_in = 4'ha;
    end

endmodule
