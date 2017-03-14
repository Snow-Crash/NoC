`include "deserializer_controller.v"

module deserializer_controller_tb;

reg clk, reset, receive;
wire deserializer_idle, deserializer_finish;


deserializer_controller dut (.clk(clk), .receive(receive), .deserializer_idle(deserializer_idle),
    .deserializer_finish(deserializer_finish), .reset(reset));

always
    #10 clk = ~clk;

initial
    begin
        clk = 0;
        receive = 0;
        reset = 0;
    #10 reset = 1;
    #20 reset = 0;
        receive = 1;
    #20 receive = 0;
    #140 receive = 1;
    #80 receive = 0;
    end

endmodule 
