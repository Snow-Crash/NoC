`include "piso_shift_register.v"

module piso_shift_register_tb;


reg clk, load, reset;
reg [31:0] data_in;

wire [3:0] data_out;

shift_register dut (.data_in(data_in), .clk(clk), .load(load), .reset(reset), .data_out(data_out));

always
    #10 clk = ~clk;

initial
    begin
        clk = 1'b0;
        reset = 0;
        load = 0;
        #10 reset = 1;
        #20 reset = 0;
        load = 1;
        data_in = 32'habcd1234;
        #20 load = 0;
        #200 load = 1;
    end
endmodule
