module fp_arbiter(clk, reset, request, 
grant_vec, crossbar_control);

input clk, reset;
input [4:0] request;
output [4:0] grant_vec;
output reg [2:0]  crossbar_control;

parameter packet_size = 32;
parameter flit_size = 4;

localparam idle = 4'd0;
localparam sending = 4'd1;
localparam arbitrating = 4'd2;

localparam select_local = 3'd0;
localparam select_north = 3'd1;
localparam select_south = 3'd2;
localparam select_east = 3'd3;
localparam select_west = 3'd4;



//reg [4:0] priority_reg;
reg [2:0] counter;
reg [4:0] grant;

reg [3:0] current_state;
reg [3:0] next_state;
 
wire [4:0] request;
assign grant_vec = grant;
//assign request = {local_request, north_request, south_request, east_request, west_request};

//assign local_grant = grant[4];
//assign north_grant = grant[3];
//assign south_grant = grant[2];
//assign east_grant = grant[1];
//assign west_grant = grant[0];


always @(posedge clk ,reset) 
    begin
        if(reset)
            begin
                grant <= 0;
                current_state <= idle;
            end
        else 
            current_state <= next_state;
    end

always @(current_state or request or counter)
    begin
        case (current_state)
            idle:
                begin
                    if(request == 0)
                        next_state <= idle;
                    else
                        next_state <= arbitrating;
                end
            arbitrating:
                    next_state <= sending;
            sending:
                begin
                    if(counter != 7)
                        next_state <=sending;
                    else if (request == 0)
                        next_state <= idle;
                    else
                        next_state <= arbitrating;

                end
        endcase
    end

always @(posedge clk or current_state)
    begin
        case (current_state)
            idle: 
                begin
                    grant <= 0;
                    counter <= 0;
                end
            arbitrating:
                begin
                    counter <= 0;
                    grant[0] <= request[0];
                    grant[1] <= ~request[0] & request[1];
                    grant[2] <= ~request[0] & ~request[1] & request[2];
                    grant[3] <= ~request[0] & ~request[1] & ~request[2] & request[3];
                    grant[4] <= ~request[0] & ~request[1] & ~request[2] & ~request[3] & request[4];
                end
            sending:
                counter <= counter + 1;
        endcase
    end



//crossbar control signal
always @(*)
    begin
        case (grant)
            00000: crossbar_control <= 3'd5;
            00001: crossbar_control <= select_west;
            00010: crossbar_control <= select_east;
            00100: crossbar_control <= select_south;
            01000: crossbar_control <= select_north;
            10000: crossbar_control <= select_local;
            endcase
    end
endmodule

