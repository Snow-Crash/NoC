//2017.2.14 add request_vector
//2017.2.23 remove latches

module address_compute (address_in, destination_port, next_address, request_vector);

parameter address_length = 16;
parameter x_address_length = 8;
parameter y_address_length = 8;


localparam local = 3'd1;
localparam north = 3'd2;
localparam south = 3'd3;
localparam east = 3'd4;
localparam west = 3'd5;

localparam x_coordinate = 8'd10;
localparam y_coordinate = 8'd11;

output reg [2:0] destination_port;
output reg [address_length-1:0] next_address;
input [address_length - 1:0] address_in;
output reg [4:0] request_vector; //high to low: west east south north local

//reg [2:0] destination;

wire signed [x_address_length - 1:0] x_address;
wire signed [y_address_length - 1:0] y_address;
wire signed [x_address_length - 1:0] x_address_plus;
wire signed [x_address_length - 1:0] x_address_minus;
wire signed [y_address_length - 1:0] y_address_plus;
wire signed [y_address_length - 1:0] y_address_minus;

assign x_address = address_in[x_address_length - 1:0];
assign y_address = address_in[address_length - 1:address_length - y_address_length];

//assign x_address_plus = x_address + 1;
//assign x_address_minus = x_address - 1;
//assign y_address_plus = y_address + 1;
//assign y_address_minus = y_address - 1;
//
always @(*) 
begin
    if (x_address > x_coordinate)
        begin
            request_vector = 5'b01000;
            destination_port = east;
        end
    else if (x_address < x_coordinate)
        begin
            request_vector = 5'b10000;
            destination_port = west;
        end
    else
        begin
            if (y_address > y_coordinate)
                begin
                    request_vector = 5'b00010; //request north arbiter
                    destination_port = north;
                end
            else if (y_address < y_coordinate)
                begin
                    request_vector = 5'b00100; //request south arbiter
                    destination_port = south;
                end
            else
                begin
                    request_vector = 5'b00001; //request local arbiter
                    destination_port = local;
                end
        end
end

endmodule
//assign destination_port = destination;