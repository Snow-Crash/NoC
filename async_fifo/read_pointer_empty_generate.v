//2017.2.20 posedge reset

//`include "gray_counter.v"

module read_pointer_empty_generate(read_address, read_gray_pointer, read_clk, read_inc,
     read_reset, read_empty, synchronized_write_pointer2);

localparam address_size = 4;

input [address_size :0] synchronized_write_pointer2;
input read_inc, read_clk, read_reset;

output [address_size - 1:0] read_address;
output [address_size:0] read_gray_pointer;
output reg read_empty;

wire [address_size : 0]read_gray_pointer_next;
wire if_empty;

gray_counter read_gray_counter(.inc(read_inc), .not_full_or_not_empty(~read_empty), .clk(read_clk), 
    .reset(read_reset), .binary_address(read_address), .gray_pointer(read_gray_pointer),
     .gray_pointer_next(read_gray_pointer_next));



//empty generate, when next pointer is the same as write pointer
//write pointer points to the address which will be written
//if writr pointer = read pointer, memory is empty
assign if_empty = (read_gray_pointer_next == synchronized_write_pointer2);

always @(posedge read_clk or posedge read_reset) 
    begin
        if (read_reset) 
            begin
                read_empty <= 1'b1;
            end
        else
            begin
                read_empty <= if_empty;
            end
    end


endmodule // read_pointer_empty_generate