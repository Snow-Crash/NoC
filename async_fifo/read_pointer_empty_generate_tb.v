`include "read_pointer_empty_generate.v"

module read_pointer_empty_generate_tb;

localparam address_size = 4;


reg [address_size:0] synchronized_write_pointer2;

reg read_clk, read_inc, read_reset;
wire [address_size:0] read_gray_pointer;
wire [address_size - 1:0] read_address;
wire read_empty;

read_pointer_empty_generate dut(.read_address(read_address), .read_gray_pointer(read_gray_pointer), .read_clk(read_clk),
    .read_inc(read_inc), .read_reset(read_reset), .read_empty(read_empty), .synchronized_write_pointer2(synchronized_write_pointer2));


always
    #10 read_clk = ~read_clk;


initial
    begin
        read_clk = 1'b0;
        read_reset = 0;
        read_inc = 0;
        synchronized_write_pointer2 = 0;
        #10 read_reset = 1;
        #20 read_reset = 0;
        read_inc = 0;
        synchronized_write_pointer2 = 5'b00000;
        #20 synchronized_write_pointer2 = 5'b00001;
        #20 synchronized_write_pointer2 =  5'b00011;
        #20 synchronized_write_pointer2 =  5'b00010;
        #20 synchronized_write_pointer2 =  5'b00110;
        #20 synchronized_write_pointer2 =  5'b00111;
        #20 synchronized_write_pointer2 =  5'b00101;
        read_inc = 1;
        #300 read_inc = 0;
        //#20 synchronized_write_pointer2 =  5'b01001;
        //#20 synchronized_write_pointer2 =  5'b11000;
        //#20 synchronized_write_pointer2 =  5'b11001;
        //#20 synchronized_write_pointer2 =  5'b11011;

    end


endmodule