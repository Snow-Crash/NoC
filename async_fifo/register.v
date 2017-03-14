//2017.2.22  posedge reset
module register (clk, data_in, reset, data_out); 
parameter input_size = 32;

input clk, reset;
input [input_size - 1:0] data_in;
output [input_size -1:0] data_out; 

reg [input_size - 1:0] data_out;

 
always @(posedge clk or posedge reset) 
    begin 
        if (reset) 
            data_out <= 32'h00000000; 
        else 
            data_out <= data_in; 
        end 
endmodule