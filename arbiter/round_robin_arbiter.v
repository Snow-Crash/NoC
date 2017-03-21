//2017.2.14 c
//2017.2.15 add state arbitrating_noload
//          this state doesn't assign unrotated_grant to grant_reg
//          when arbiter is idle and receives request, transit to arbitrating_noload
//          when port is sending last flit and there is request, transit to arbitrating state
//2017.2.16 fix bugs, grant_reg not always holds correct grant signal
//          if only based on grant_reg, cannot always get corret crossbar signal
//          add a mux, select between unrotated_grant and grant_reg 
//          to get correct crossbar control signal
//2017.2.20 posedge reset
//2017.2.22 rewrite state machine, add signals to control counter, avoid latch of unrotated_grant, round_robin_pointer
//2017.2.23 modify always blocks of round_robin_pointer and state machine, eliminate latches


module round_robin_arbiter(clk, reset, request, grant_vec, crossbar_control, write_request, destination_full);

input clk, reset, destination_full;
input [4:0] request;
output reg [4:0] grant_vec;
output reg [2:0] crossbar_control;
output reg write_request;


parameter packet_size = 32;
parameter flit_size = 4;

localparam flit_number = packet_size / flit_size;

localparam arbitrating = 3'd1;
localparam sending_packet = 3'd2;
localparam idle = 3'd0;
localparam arbitrating_noload = 3'd3;

localparam select_local = 3'd0;
localparam select_north = 3'd1;
localparam select_south = 3'd2;
localparam select_east = 3'd3;
localparam select_west = 3'd4;

wire ifrequest = request[0] || request[1] || request[2] || request[3] || request[4];
reg [4:0] grant_mux;
reg load_grant_reg;

reg [2:0] current_state;
reg [2:0] next_state;
reg [3:0] counter;

reg update_pointer, clear_counter, inc_counter;
reg [3:0] round_robin_pointer;
reg [4:0] shifted_request, shifted_grant, unrotated_grant;

reg [4:0] grant_reg;

//shift request vector
always @(*)
    begin
        case (round_robin_pointer)
            4'd0: shifted_request = request;
            4'd1: shifted_request = {request[0], request[4:1]};
            4'd2: shifted_request = {request[1:0], request[4:2]};
            4'd3: shifted_request = {request[2:0], request[4:3]};
            4'd4: shifted_request = {request[3:0], request[4]};
        default:
            shifted_request = request;
        endcase
    end

//priority round_robin_arbiter
always @(*)
    begin
        if (shifted_request[0])
            shifted_grant = 5'b00001;
        else if (shifted_request[1])
            shifted_grant = 5'b00010;
        else if (shifted_request[2])
            shifted_grant = 5'b00100;
        else if (shifted_request[3])
            shifted_grant = 5'b01000;
        else if (shifted_request[4])
            shifted_grant = 5'b10000;
        else
            shifted_grant = 0;
    end

//grant signal
always @(*)
    case (round_robin_pointer)
        4'd0:   unrotated_grant = shifted_grant;
        4'd1:   unrotated_grant = {shifted_grant[3:0], shifted_grant[4]};
        4'd2:   unrotated_grant = {shifted_grant[2:0], shifted_grant[4:3]};
        4'd3:   unrotated_grant = {shifted_grant[1:0], shifted_grant[4:2]};
        4'd4:   unrotated_grant = {shifted_grant[0], shifted_grant[4:1]};
        default:
            unrotated_grant = shifted_grant;
    endcase


always @(posedge clk or posedge reset)
    begin
        if (reset)
            round_robin_pointer <= 3'd0;
        else if(update_pointer)
            begin
                    if(grant_reg[0])
                        round_robin_pointer <= 3'd1;
                    else if (grant_reg[1])
                        round_robin_pointer <= 3'd2;
                    else if (grant_reg[2])
                        round_robin_pointer <= 3'd3;
                    else if (grant_reg[3])
                        round_robin_pointer <= 3'd4;
                    else if (grant_vec[4])
                        round_robin_pointer <= 3'd0;
                    else
                        round_robin_pointer <= 3'd0;
            end
    end

always @(posedge clk or posedge reset)
    begin
        if (reset)
            grant_reg <= 0;
        else if(load_grant_reg)
            grant_reg <= unrotated_grant;
    end

//counter 
always @(posedge clk)
    begin
        if (clear_counter == 1)
            counter <= 0;
        else if (inc_counter == 1)
            counter <= counter + 1;
        else
            counter <= counter;
    end



always @(posedge clk or posedge reset)
    begin
        if(reset)
            current_state <= idle;
        else
            current_state <= next_state;
    end

always @(*)
    begin
        case (current_state)
            idle:
                if (ifrequest == 1)
                    next_state <= arbitrating_noload;
                else
                    next_state <= idle;
            arbitrating_noload:
                next_state <= sending_packet;
            arbitrating:
                next_state <= sending_packet;
            sending_packet:
                if (counter < flit_number - 1)
                    next_state <= sending_packet;
                else if (ifrequest == 0)
                    next_state <= idle;
                else //(ifrequest == 1)     //else if => else
                    next_state <= arbitrating;
            default:
                    next_state <= idle;
        endcase
    end

always @(current_state or ifrequest or counter)
    begin
        case (current_state)
            idle:
                begin
                    update_pointer = 0;
                    //round_robin_pointer = 0;
                    //grant_vec <= unrotated_grant & ~grant_vec;
                    //grant_reg <= 0;
                    //counter = 0;
                    write_request = 0;
                    clear_counter = 1;
                    //priority computing is pure combinational logic
                    //although arbiter is idle, grant can be obtained immediately
                    //when idle, detect if there is request,
                    //grant can be stored in register next clock
                    if (ifrequest)
                        load_grant_reg = 1;
                    else
                        load_grant_reg = 0;
                    //grant_vec <= 0;
                    //grant_vec <= unrotated_grant; 
                    clear_counter = 1;
                end
            arbitrating_noload:
                begin
                    //counter <= 0;              
                    //grant_vec <= unrotated_grant & ~grant_vec;
                    //grant_vec <= grant_vec;
                    update_pointer = 1;
                    
                    load_grant_reg = 0;
                    clear_counter = 0;
                    if (destination_full == 0)
                        begin
                            inc_counter = 1;
                            write_request = 1;
                        end
                    else
                        begin
                            inc_counter = 0;
                            write_request = 0;
                        end
                end
            arbitrating:
                begin
                    //counter <= 0;              
                    //grant_vec <= unrotated_grant & ~grant_vec;
                    //grant_vec <= grant_vec;
                    //rotate pointer
                    clear_counter = 0;
                    update_pointer = 1;
                    if (counter == 0)
                        load_grant_reg = 1;
                    else
                        load_grant_reg = 0;
                    //write_request = 1;
                    if (destination_full == 0)
                        begin
                            inc_counter = 1;
                            write_request = 1;
                        end
                    else
                        begin
                            inc_counter = 0;
                            write_request = 0;
                        end
                end
            sending_packet:
                begin
                    load_grant_reg = 0;
                    update_pointer = 0;
                    //counter <= counter + 1;
                    //write_request = 1;
                    //load_grant_reg = 0;
                    clear_counter = 0;
                    if (counter == flit_number - 1)
                        begin
                            load_grant_reg = 1;
                            clear_counter = 1;
                        end
                    //grant_vec <= grant_vec;
                    if (destination_full == 0)
                        begin
                            inc_counter = 1;
                            write_request = 1;
                        end
                    else
                        begin
                            inc_counter = 0;
                            write_request = 0;
                        end
                end
            default:
                begin
                    update_pointer = 0;
                    write_request = 0;
                    load_grant_reg = 0;
                    clear_counter = 0;
                end
        endcase
    end

//assign grant_vec = grant_reg;

//mux
always @(*)
    begin
        if (current_state == arbitrating)
            grant_mux = unrotated_grant;
        else
            grant_mux = grant_reg;   
    end
//crossbar control signal decode
always @(*)
    begin
        case (grant_mux)
            5'b00000: crossbar_control <= 3'd5;
            5'b00001: crossbar_control <= select_local;
            5'b00010: crossbar_control <= select_north;
            5'b00100: crossbar_control <= select_south;
            5'b01000: crossbar_control <= select_east;
            5'b10000: crossbar_control <= select_west;
            default:
                crossbar_control <= 3'd5;//2.22 avoid latch
            endcase
    end

//mux
//unrotated_grant is result, when arbiter is idle, 
//result can be obtained immediately
//mux can select result instead of waiting one clock 
//to wait for output of grant register
always @(*)
    begin
        //if (counter == 0)
        if (current_state == idle)
            grant_vec = unrotated_grant;
        else if(current_state == arbitrating)
            grant_vec = unrotated_grant;
        else if(current_state == sending_packet && counter == flit_number - 1)
            grant_vec = unrotated_grant;
        else 
            grant_vec = grant_reg;
    end

endmodule

