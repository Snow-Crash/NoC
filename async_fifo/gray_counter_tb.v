`include "gray_counter.V"

module gray_counter_tb;

reg inc, not_full_not_empty, clk, reset;

localparam address_size = 4;

wire [address_size - 1:0]binary_address;
wire [address_size:0] gray_pointer;
wire [address_size:0] gray_pointer_next;

gray_counter DUT (.inc(inc), .not_full_or_not_empty(not_full_not_empty),
    .clk(clk), .reset(reset), .binary_address(binary_address),
    .gray_pointer(gray_pointer), .gray_pointer_next(gray_pointer_next));

always
    #10 clk = ~clk;

initial
    begin
        clk = 1'b0;
        reset = 0;
        not_full_not_empty = 0;
        #10 reset = 1;
        #20 reset = 0;
        inc = 1;
        #100 not_full_not_empty = 1;        
        #80 inc = 0;
        #80 not_full_not_empty = 0;
    end
endmodule