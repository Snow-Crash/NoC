`include "async_fifo.v"

module async_fifo_tb();

localparam input_size = 32;

reg [input_size - 1:0] data_in;
reg write_clk, read_clk, write_reset, read_reset, write_inc, read_inc;

wire [input_size - 1:0] data_out;
wire write_full, read_empty;

async_fifo dut(.data_in(data_in), .data_out(data_out), .write_clk(write_clk), .read_clk(read_clk), 
    .write_reset(write_reset), .read_reset(read_reset), .write_inc(write_inc), .read_inc(read_inc),
    .write_full(write_full), .read_empty(read_empty));

always 
    begin
        #10 write_clk = ~write_clk;
        #5 read_clk = ~read_clk;
    end

initial
    begin
        write_clk = 0;
        write_reset = 0;
        write_inc = 0;
        #10 write_reset = 1;
        #20 write_reset = 0;
        #40 write_inc = 1;
        #20 data_in = 32'h12345678;
        #20 data_in = 32'h87654321;
        #20 data_in = 32'habcdabcd;
        #20 data_in = 32'haaaaaaaa;
        #20 write_inc = 0;

    end

initial
    begin
        read_clk = 0;
        read_reset = 0;
        read_inc = 0;
        #5 read_reset = 1;
        #40 read_reset = 0;
        #10 read_inc = 1;
        #200 read_inc = 0;
    end



endmodule // async_fifo_tb
