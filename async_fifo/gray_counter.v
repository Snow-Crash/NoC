//`include "register.v"
//`include "binary_to_gray.v"

module gray_counter (inc, not_full_or_not_empty, clk, reset, binary_address, gray_pointer, gray_pointer_next);

localparam address_size = 4; //2
//localparam count_size = address_size + 1;
localparam fifo_depth = 2 ** address_size;
//gray pointer has 1 more bit than binary pointer
//binary counter is used to access memory, therefore fifo_depth = 2 ^ (counter_width - 1)

// inc is write_enable or read_enable signal  
//binary_address is address to access memory
input inc, not_full_or_not_empty, clk, reset;
output [address_size:0] gray_pointer;
output [address_size - 1:0] binary_address;
output [address_size:0] gray_pointer_next;

wire increment;
wire [address_size:0] binary_count_next;
wire [address_size:0] binary_count_current;
wire [address_size:0] gray_count_next;
wire [address_size:0] gray_count_current;

//if not_full_or_not_empty = 0, memory is full or empty, pointer stops increment
assign increment = inc & not_full_or_not_empty;
assign binary_count_next = increment + binary_count_current;

register #(.input_size(address_size + 1)) binary_pointer_register(.clk(clk), .data_in(binary_count_next), .data_out(binary_count_current), .reset(reset));

register #(.input_size(address_size + 1)) gray_pointer_register(.clk(clk), .data_in(gray_count_next), .data_out(gray_count_current), .reset(reset));

binary_to_gray binary_to_gray_converter(.binary_in(binary_count_next), .gray_out(gray_count_next));

assign binary_address = binary_count_current[address_size:0];
assign gray_pointer = gray_count_current;
assign gray_pointer_next = gray_count_next;

endmodule