//shift register parallel load, serial out, every time 4 bits
//synchronous load, asynchronous reset
//2017.2.20  posedge reset
module piso_shift_register (data_in, clk, load, reset, data_out); 
localparam input_size = 32;
localparam output_size = 4;

input  load, clk, reset;
input [input_size - 1:0] data_in; 
output [output_size - 1:0] data_out; 
reg [input_size - 1:0] reg_memory; 
 
  always @(posedge clk or posedge reset) 
  begin 
    if (reset) 
      reg_memory <= 32'h00000000; //
    else if (load)
      reg_memory <= data_in;
    else
      reg_memory <= {4'b0000, reg_memory[input_size - 1:4]};
  end 
  assign data_out  = reg_memory[3:0]; 
endmodule 
