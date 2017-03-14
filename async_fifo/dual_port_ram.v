//synchronous write, clock comes from write domain
//asynchronous read
module dual_port_ram (write_clk, data_in, data_out, write_address, read_address, write_enable);

localparam address_size = 4;
localparam ram_depth = 2 **  address_size;
localparam input_size = 4;

input write_clk, write_enable;
input [address_size - 1:0] write_address, read_address;
input [input_size - 1:0] data_in;
output [input_size - 1:0] data_out;

reg [input_size - 1:0] ram[ram_depth - 1:0];	//

/*
always @(posedge write_clk) begin
	if (write_enable) 
	begin
		if (read_address == write_address) 	//if read address = write address, directly bypass
			begin
				ram[write_address] <= data_in;
				data_out <= data_in;
			end
		else 
			begin
				ram[write_address] <= data_in;
				data_out = ram[read_address];
			end
		end
	end
*/

always @(posedge write_clk)
	if (write_enable) 
		begin
			ram[write_address] <= data_in;  
		end

assign data_out = ram[read_address];

endmodule
