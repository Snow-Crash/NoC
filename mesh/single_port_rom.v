// Quartus Prime Verilog Template
// Single Port ROM

module single_port_rom
#(parameter DATA_WIDTH = 32, parameter ADDR_WIDTH = 8, parameter INIT_FILE_PATH = "../data1_1/spike_mif.txt")
(
	input [(ADDR_WIDTH-1):0] addr,
	input clk, 
	output reg [(DATA_WIDTH-1):0] q
);

	reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];

	initial
	begin
		$readmemb(INIT_FILE_PATH, rom);
	end

	always @ (posedge clk)
	begin
		q <= rom[addr];
	end

endmodule
