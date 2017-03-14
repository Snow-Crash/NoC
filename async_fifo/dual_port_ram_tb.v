`include "dual_port_ram.v"

module dual_port_ram_tb;


localparam input_size = 32;
localparam address_size = 4;

reg write_clk, write_enable;
reg [input_size - 1:0] data_in;
reg [address_size - 1:0] write_address, read_address;

wire [input_size - 1:0] data_out;

dual_port_ram dut (.write_clk(write_clk), .data_in(data_in), .data_out(data_out), 
    .write_address(write_address), .read_address(read_address), .write_enable(write_enable));

always
    #10 write_clk = ~write_clk;


initial
    begin
    write_clk = 1'b0;
    #10 write_enable = 1;
    write_address = 4'b0000;
    data_in = 32'h12345678;
    #10 read_address = 4'b0000;
    #10 write_address = 4'b0001;
    data_in = 32'h87654321;
    #20 write_address = 4'b0010;
    data_in = 32'habcdabcd;
    read_address = 4'b0001;
    #20 write_address = 4'b0011;
    data_in = 32'habcd1234;
    #10 read_address = 4'b0010;
    write_enable = 0;
    #100 read_address = 4'b0011;
    end

endmodule


