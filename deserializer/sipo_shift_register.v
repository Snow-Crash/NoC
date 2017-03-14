module sipo_shift_register(data_in, data_out, reset, clk);

parameter input_size = 4;
parameter output_size = 32;

input [input_size - 1:0] data_in;
input clk, reset;
output [output_size - 1:0] data_out;

reg [output_size - 1:0] reg_memory;

 always @(posedge clk, reset) 
    begin
        if (reset)
            reg_memory <= 0;
        else
            begin
            //reg_memory[output_size - 1 : output_size - 4] <= data_in;
            reg_memory <= {data_in, reg_memory[output_size - 1:4]};
            end
    end

assign data_out = reg_memory;

endmodule

