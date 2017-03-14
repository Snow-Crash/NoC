//two flip-flop double sampling
//2017.2.20 posedge reset

module read_to_write_sync(read_pointer, write_clk, write_reset, synchronized_read_pointer2);

localparam address_size = 4;

input [address_size:0] read_pointer;
input write_clk, write_reset;
output reg [address_size:0] synchronized_read_pointer2;

reg [address_size:0] synchronized_read_pointer1;


always @(posedge write_clk or posedge write_reset) 
    begin
        if (write_reset) 
            begin
                synchronized_read_pointer1 <= 0;
                synchronized_read_pointer2 <= 0;
            end
        else
            begin
                synchronized_read_pointer1 <= read_pointer;
                synchronized_read_pointer2 <= synchronized_read_pointer1;
            end
    end
    
endmodule