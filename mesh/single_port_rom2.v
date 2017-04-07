// Quartus Prime Verilog Template
// Single Port ROM

module single_port_rom2
#(parameter DATA_WIDTH = 32, parameter ADDR_WIDTH = 8)
(
	input [(ADDR_WIDTH-1):0] addr,
	input clk, 
	output reg [(DATA_WIDTH-1):0] q
);
	reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0]/* synthesis ram_init_file = "packet.mif" */;
	//reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];
/*
	initial
	begin
		$readmemb("../data1_1/spike_mif.txt", rom);
	end
*/
	always @ (posedge clk)
	begin
		q <= rom[addr];
	end

endmodule
