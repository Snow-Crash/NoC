module routing_logic (address_in, destination_port, next_address, request_vector);

parameter address_length = 16;
parameter x_address_length = 8;
parameter y_address_length = 8;
parameter X_COORDINATE = 0;
parameter Y_COORDINATE = 0;


localparam local = 3'd1;
localparam north = 3'd2;
localparam south = 3'd3;
localparam east = 3'd4;
localparam west = 3'd5;

output reg [2:0] destination_port;
input [address_length - 1:0] address_in;
output reg [4:0] request_vector; //high to low: west east south north local
output next_address;


wire [x_address_length - 1:0] x_address;
wire [y_address_length - 1:0] y_address;
assign x_address = address_in[x_address_length - 1:0];
assign y_address = address_in[address_length - 1:address_length - y_address_length];
assign next_address = address_in;


always (*)
    begin
        request_vector = 5'b00000;//2.22 avoid latch
        destination_port = 3'd0;//4.2 avoid latch
        if (x_address == X_COORDINATE)
            begin
                if (y_address == Y_COORDINATE)
                    begin
                        request_vector = 5'b00001; //request local arbiter
                        destination_port = local;
                    end
                else if (y_address > Y_COORDINATE)
                    begin
                        request_vector = 5'b00010; //request north arbiter
                        destination_port = north;
                    end
                else if (y_address < Y_COORDINATE)
                    begin
                        request_vector = 5'b00100; //request south arbiter
                        destination_port = south;
                    end
            end
        else if (x_address > X_COORDINATE)
            begin
                request_vector = 5'b01000; //request east arbiter
                destination_port = east;
            end
        else if (x_address < X_COORDINATE)
            begin
                request_vector = 5'b10000; //request west arbiter
                destination_port = west;
            end
    end

endmodule