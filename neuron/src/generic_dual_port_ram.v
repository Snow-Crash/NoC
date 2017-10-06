// One read port and one write port. One port for read address and one port for write address.
// Read address is registered. data_in, write_address are not registered.
// https://opencores.org/ocsvn/common/common/trunk/generic_memories/rtl/verilog/
// http://quartushelp.altera.com/15.0/mergedProjects/hdl/vlog/vlog_file_dir_ram_init.htm

`timescale 1ns/100ps
`define SIM_MEM_INIT
`define QUARTUS_SYN_INIT

module generic_dual_port_ram(
	clk, read_address, write_address,
	read_enable, write_enable, data_in, data_out
);

	parameter ADDRESS_WIDTH = 8;  						// number of bits in address-bus
	parameter DATA_WIDTH = 16; 							// number of bits in data-bus
	parameter SIM_FILE_PATH = "D:/code/data";
	parameter INIT_FILE_PATH = "";

	input           clk;  								// read clock, rising edge trigger

	// read port
	input	[ADDRESS_WIDTH - 1:0]	read_address; 			// read address
    input							read_enable;    		// read enable
    output	[DATA_WIDTH - 1:0]		data_out;				//data output

	// write port
	input                       write_enable;       	// Write enable
	input [ADDRESS_WIDTH - 1:0] write_address;      	// write address
	input [DATA_WIDTH-1 : 0]	data_in;            	// data input

	reg [ADDRESS_WIDTH-1:0] read_address_register;      // register read address

//Initialize memory
`ifdef SIM_MEM_INIT
	reg [DATA_WIDTH-1:0] mem [(1<<ADDRESS_WIDTH) -1:0];
	
	reg [100*8:1] file_name;
	initial begin
		file_name = SIM_FILE_PATH;					$readmemh (file_name, mem);
	end

`else
	`ifdef QUARTUS_SYN_INIT
		(* ram_init_file = INIT_FILE_PATH *) reg [DATA_WIDTH-1:0] mem [(1<<ADDRESS_WIDTH) -1:0];
	`else
		reg [DATA_WIDTH-1:0] mem [(1<<ADDRESS_WIDTH) -1:0];
	`endif
`endif

	// read operation
	always @(posedge clk)
	  if (read_enable)
	    read_address_register <= read_address;

    assign data_out = mem[read_address_register];

	// write operation
	always @(posedge clk)
		if (write_enable)
			mem[write_address] <= data_in;


endmodule