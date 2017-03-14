//2017.2.14 add request_vector
//2017.2.23 remove latches
//2017.3.14 simplify 

module address_compute (address_in, destination_port, next_address, request_vector);

parameter address_length = 16;
parameter x_address_length = 8;
parameter y_address_length = 8;


localparam local = 3'd1;
localparam north = 3'd2;
localparam south = 3'd3;
localparam east = 3'd4;
localparam west = 3'd5;

output reg [2:0] destination_port;
output reg signed [address_length-1:0] next_address;
input [address_length - 1:0] address_in;
output reg [4:0] request_vector; //high to low: west east south north local

wire signed [x_address_length - 1:0] x_address;
wire signed [y_address_length - 1:0] y_address;
reg signed [x_address_length - 1:0] new_address;


assign x_address = address_in[x_address_length - 1:0];
assign y_address = address_in[address_length - 1:address_length - y_address_length];


always @(*)
    begin
        if (x_address > 0)
            begin
                request_vector = 5'b01000; //request east arbiter
                destination_port = east;
                new_address = x_address - 1;
                next_address = {y_address ,new_address};
            end
        else if (x_address < 0)
            begin
                request_vector = 5'b10000; //request west arbiter
                destination_port = west;
                new_address = x_address + 1;
                next_address = {y_address, new_address};
            end
        else
            begin
                if (y_address > 0)
                    begin
                        request_vector = 5'b00010; //request north arbiter
                        destination_port = north;
                        new_address = y_address - 1;
                        next_address = {new_address, x_address};
                    end
                else if ( y_address < 0)
                    begin
                        request_vector = 5'b00100; //request south arbiter
                        destination_port = south;
                        new_address = y_address + 1;
                        next_address = {new_address, x_address};
                    end
                else
                    begin
                        request_vector = 5'b00001; //request local arbiter
                        destination_port = local;
                        next_address = {y_address, x_address};
                    end
            end
    end

endmodule
//assign destination_port = destination;