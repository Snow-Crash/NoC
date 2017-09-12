// One read port and one write port. One port for read address and one port for write address.
// Read address is registered. data_in, write_address are not registered.


module generic_dual_port_ram(
	clk, rst, read_address, write_address,
	read_enable, write_enable, data_in, data_out
);

	parameter address_width = 8;  					// number of bits in address-bus
	parameter data_width = 16; 						// number of bits in data-bus

	input           clk;  							// read clock, rising edge trigger
	input           rst;  							// read port reset, active high
	// read port
	input  [address_width - 1:0] read_address; 		// read address
    input                       read_enable;    	// read enable
    output [data_width - 1:0]   data_out;			//data output

	// write port
	input                       write_enable;       // Write enable
	input [address_width - 1:0] write_address;      // write address
	input [data_width-1 : 0]    data_in;            // data input


	reg [data_width-1:0] mem [(1<<address_width) -1:0] 
	reg data_width-1:0] read_address_register;             // register read address

	// read operation
	always @(posedge clk)
	  if (read_enable)
	    read_address_register <= read_address;

    assign data_out = mem[read_address_register];

	// write operation
	always @(posedge clk)
		if (write_enable)
			mem[write_address] <= data_in;

`else