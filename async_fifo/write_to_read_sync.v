//2017.2.20  posedge reset

module write_to_read_sync (write_pointer, read_clk, read_reset, synchronized_write_pointer2);

localparam address_size = 4;

input [address_size:0] write_pointer;
input read_clk, read_reset;
output reg [address_size:0] synchronized_write_pointer2;

reg [address_size:0] synchronized_write_pointer1;

always @(posedge read_clk or posedge read_reset) 
    begin
        if (read_reset) 
            begin
                synchronized_write_pointer1 <= 0;
                synchronized_write_pointer2 <= 0;
            end
        else
            begin
                synchronized_write_pointer1 <= write_pointer;
                synchronized_write_pointer2 <= synchronized_write_pointer1;
            end
end

endmodule 