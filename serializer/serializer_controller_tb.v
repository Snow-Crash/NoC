`include "serializer_controller.v"

module interface_controller_tb;

reg clk, reset, fifo_empty;
wire read_fifo, shift_register_load, serializer_idle;

serializer_controller dut(.clk(clk), .reset(reset), .fifo_empty(fifo_empty), 
.read_fifo(read_fifo), .shift_register_load(shift_register_load), .serializer_idle(serializer_idle));

always
    #10 clk = ~clk;

initial
    begin
        clk = 1'b0;
        reset = 0;
        fifo_empty = 1;
        reset = 1;
        #20 reset = 0;
        #20 fifo_empty = 0;
        #400 fifo_empty = 1;
    end

endmodule // 