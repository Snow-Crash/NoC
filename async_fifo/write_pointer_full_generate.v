// 2017.2.20  posedge reset
//`include "register.v"
//`include "binary_to_gray.v"

module write_pointer_full_generate (write_clk, write_reset, write_inc, 
    synchronized_read_pointer2, write_full, write_address, write_gray_pointer);

localparam address_size = 4;

input write_inc, write_clk, write_reset;
input [address_size:0] synchronized_read_pointer2;

output [address_size - 1:0] write_address;
output reg write_full;
output reg [address_size:0] write_gray_pointer;

reg [address_size:0] write_binary_count;

wire [address_size:0] write_gray_pointer_next, write_binary_count_next;
wire if_full;

//if write_full = 1, memory is full, write_binary_count will not increase
//stop writing
assign write_binary_count_next = write_binary_count + (write_inc & ~write_full);

//convert binay code to gray code
assign write_gray_pointer_next = (write_binary_count_next >> 1) ^ write_binary_count_next;

always @(posedge write_clk or posedge write_reset) 
    begin
        if (write_reset)
            begin
                write_binary_count <= 0;
                write_gray_pointer <= 0;
            end
        else
            begin
                write_binary_count <= write_binary_count_next;
                write_gray_pointer <= write_gray_pointer_next;
            end
    end

assign write_address = write_binary_count[address_size - 1:0];

//compare read pointer and write pointer to determine if memory is full
assign if_full = (write_gray_pointer_next == {~synchronized_read_pointer2[address_size:address_size - 1], synchronized_read_pointer2[address_size-2:0]});

always @(posedge write_clk or posedge write_reset) 
    begin
        if (write_reset)
            write_full <= 1'b0;
        else
            write_full <= if_full;
    end

endmodule