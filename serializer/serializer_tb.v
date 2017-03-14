`include "serializer.v"

module serializer_tb;

reg clk, reset, fifo_empty;
reg [31:0] data_in; 
wire [3:0] data_out;
wire serializer_idle, read_fifo;



serializer dut (.clk(clk), .reset(reset), .data_in(data_in), .data_out(data_out), 
    .fifo_empty(fifo_empty), .serializer_idle(serializer_idle), .read_fifo(read_fifo));

always
    #10 clk = ~clk;

initial
    begin
      clk = 0;
      reset = 0;
      fifo_empty = 0;
      data_in = 32'h12345678;
      #10 reset = 1;
      #20 reset = 0;
      #20 fifo_empty = 1;
      #180 fifo_empty = 0;
      data_in = 32'h87654321;
      #40 data_in = 32'habcd1234;
      #180 data_in = 32'ha0a0a0a0;
      #20 fifo_empty = 1;
      #200 fifo_empty = 0;
      

    end

endmodule