//fully parameterized single port rom
//data_width, address_width and initialization file and simulation file are parameterized
//2017.4.8 tested by quartus and modelsim
//quartus successfully synthesized. 
//Modelsim allows quartus synthesis attributes and successfully compiled.

//SYNTH: 			for synthesis. To simulate with modelsim, comment out SYHTH
//INIT_FILE_PATH: 	the path of mif file for synthesis
//SIM_FILE_PATH: 	path of txt file for simulation

//*** IMPORTANT ***: addr should be buffered, otherwise cannot be inferred as rom

//*** TODO ***
//2017.4.8  test in modelsim to verify whether this module can be initialized



`define SIM_MEM_INIT

module single_port_rom
#(parameter DATA_WIDTH = 32, parameter ADDR_WIDTH = 8, parameter INIT_FILE_PATH = "../data1_1/spike_mif.txt", 
			parameter SIM_FILE_PATH = "D:/code/SimulationFile/packet.mif")
(
	input [(ADDR_WIDTH-1):0] addr,
	input clk, 
	output reg [(DATA_WIDTH-1):0] q
);

	`ifdef SIM_MEM_INIT
		reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];
		initial
			begin
				$readmemh (SIM_FILE_PATH, rom);
			end
	`else
		(* ram_init_file = INIT_FILE_PATH *) reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];
	`endif

	always @ (posedge clk)
	begin
		q <= rom[addr];
	end

endmodule
