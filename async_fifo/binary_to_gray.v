
module binary_to_gray(binary_in, gray_out);

localparam address_size = 4; //3

input [address_size:0] binary_in;
output [address_size:0] gray_out;

genvar i;    
generate for(i = 0; i < address_size; i = i + 1) 
    begin: for_loop
        assign gray_out[i] = binary_in[i] ^ binary_in[i + 1];
    end
endgenerate

assign gray_out[address_size]=binary_in[address_size];
endmodule