`timescale 1ns/100ps

module async_fifoTB;

reg reset, read_clk, write_clk, read_inc, writr_inc;
reg [31:0] data_in;
wire [3:0] data_out;
wire full, empty;


interface	interface_inst (
	.aclr (reset ),
	.data ( data_in ),
	.rdclk (read_clk ),
	.rdreq ( read_inc ),
	.wrclk ( write_clk ),
	.wrreq ( writr_inc ),
	.q ( data_out ),
	.rdempty ( empty ),
	.wrfull ( full )
	);


always
    begin
        #10 read_clk = ~read_clk;
    end

always
    begin
      #20 write_clk = ~write_clk;
    end

initial
    begin
        write_clk = 1'b0;
        reset = 1;
        writr_inc = 1'b0;
        #40 reset = 0;
        writr_inc = 1'b1;
        data_in = 32'h12345678;
        #40 data_in = 32'habcd9876;
        #40 writr_inc = 1'b0;


    end

initial
    begin
        read_clk = 1'b0;
        read_inc = 1'b0;
        #60 read_inc = 1'b1;
        #640 read_inc = 1'b0;

    end

endmodule