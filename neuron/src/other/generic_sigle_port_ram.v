//https://www.altera.com/support/support-resources/design-examples/design-software/verilog/ver-single-port-ram.html
`timescale 1ns/100ps


module generic_single_port_ram (clk, addr, data_in, data_out, write_enable);

    parameter DATA_WIDTH = 16;
    parameter ADDRESS_WIDTH = 8;
    parameter SIM_FILE_PATH = "D:/code/data";
	parameter INIT_FILE_PATH = "";

    input clk, write_enable;
    input [DATA_WIDTH-1:0] data_in;
	output [DATA_WIDTH-1:0] data_out;
    input [ADDRESS_WIDTH-1:0] addr;


	reg [ADDRESS_WIDTH-1:0] addr_reg;

    `ifdef SIM_MEM_INIT
        reg [DATA_WIDTH-1:0] mem [(1<<ADDRESS_WIDTH) -1:0];
	    reg [100*8:1] file_name;
	    initial 
            begin
		    file_name = SIM_FILE_PATH;				$readmemh (file_name, mem);
	        end
    `else
        `ifdef QUARTUS_SYN_INIT
	        (* ram_init_file = INIT_FILE_PATH *) reg [DATA_WIDTH-1:0] mem [(1<<ADDRESS_WIDTH) -1:0];
	    `else
		    reg [DATA_WIDTH-1:0] mem [(1<<ADDRESS_WIDTH) -1:0];
	        `endif
    `endif
 
    always @ (posedge clk)
        begin
            if (write_enable)
                mem[addr] <= data_in;
            addr_reg <= addr;
            
        end
	assign data_out = mem[addr_reg];

 
endmodule