`include "deserializer.v"

module deserializer_tb;

parameter input_size = 4;
parameter output_size = 32;

reg clk, reset, receive;
reg [input_size - 1:0] data_in;
wire [output_size - 1:0] data_out;
wire deserializer_idle, deserializer_finish;


deserializer dut(.clk(clk),. reset(reset), .receive(receive),
    .deserializer_finish(deserializer_finish), .deserializer_idle(deserializer_idle), .data_in(data_in), .data_out(data_out));


always 
    #10 clk = ~clk;

initial
    begin
      clk = 0;
      reset = 0;
      receive = 0;
      #10 reset = 1;
      #21 reset = 0;
      receive = 1;
      data_in = 4'ha;
      #20 data_in = 4'hb;
      receive = 0;
      #20 data_in = 4'hc;
      #20 data_in = 4'hd;
      #20 data_in = 4'h1;
      #20 data_in = 4'h2;
      #20 data_in = 4'h3;
      #20 data_in = 4'h4;
      #20 data_in = 4'h5;
      receive = 1;
      #20 data_in = 4'h6;
      receive = 0;
      #20 data_in = 4'h7;
      #20 data_in = 4'h8;
      #20 data_in = 4'ha;
      #20 data_in = 4'hb;
      #20 data_in = 4'hc;
      #20 data_in = 4'hd;
      #20 receive = 0;
      #200 receive = 1;

    end

endmodule