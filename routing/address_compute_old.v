module address_compute (address_in, destination_port, next_address);

parameter address_length = 16;
parameter x_address_length = 8;
parameter y_address_length = 8;

localparam local = 3'd1;
localparam north = 3'd2;
localparam south = 3'd3;
localparam east = 3'd4;
localparam west = 3'd5;

output reg [2:0] destination_port;
output reg [address_length-1:0] next_address;
input [address_length - 1:0] address_in;

//reg [2:0] destination;

wire signed [x_address_length - 1:0] x_address;
wire signed [y_address_length - 1:0] y_address;
wire [x_address_length - 1:0] next_x_address;
wire [y_address_length - 1:0] next_y_address;

assign x_address = address_in[x_address_length - 1:0];
assign y_address = address_in[address_length - 1:address_length - y_address_length];

//
always @(*) 
begin
    if (x_address == 0) 
        begin
            if (y_address == 0)
                begin
                    destination_port = local;
                    next_address = {y_address, x_address};
                end
            else if ( y_address > 0)
                begin
                    destination_port = north;
                    next_address = {y_address - 1, x_address};
                end
            else if (y_address < 1)
                begin
                    destination_port = south;
                    next_address = {y_address + 1, x_address};
                end
        end
    else if(x_address > 0)
        begin
            destination_port = east;
            next_address = {y_address, x_address - 1};
        end
    else if (x_address <0 )
        begin
            destination_port = west;
            next_address = {y_address, x_address + 1};
        end
end

endmodule
//assign destination_port = destination;











