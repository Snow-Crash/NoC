`include "write_pointer_full_generate.v"


module write_pointer_full_generate_tb;

localparam address_size = 4;


reg write_inc, write_clk, write_reset;
reg [address_size:0] synchronized_read_pointer2;

wire write_full;
wire [address_size:0] write_gray_pointer;
wire [address_size - 1:0] write_address;

write_pointer_full_generate dut(.write_clk(write_clk), .write_reset(write_reset), .write_inc(write_inc),
    .synchronized_read_pointer2(synchronized_read_pointer2), .write_full(write_full), .write_address(write_address),
    .write_gray_pointer(write_gray_pointer));

always
    #10 write_clk = ~write_clk;

initial
    begin
      write_clk = 1'b0;
      write_reset = 0;
      write_inc = 0;
      synchronized_read_pointer2 = 0;
      #10 write_reset = 1;
      #20 write_reset = 0;
      write_inc = 1;
      synchronized_read_pointer2 = 5'b00000;
      #100 synchronized_read_pointer2 = 5'b00001;
      #300 write_inc = 0;

    end
endmodule