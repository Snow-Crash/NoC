//remove next_addr_ready state

module routing_controller2(clk, reset, compute_address, stall, 
 shift_current_address,
 current_address_ready, 
 next_address_ready, send_finish, 
 load_destination_port, shift_next_address, load_next_address);

parameter input_size = 4;
parameter address_size = 16;


localparam address_flit_number = address_size / input_size;

input clk, reset, compute_address, stall;
output reg shift_current_address, current_address_ready, 
next_address_ready, send_finish,
load_destination_port,
shift_next_address,
load_next_address;

localparam idle = 3'd0;
localparam load = 3'd1;
localparam current_addr_ready = 3'd2;
localparam next_addr_ready = 3'd3;
localparam send_address = 3'd4;
localparam suspend = 3'd5;
localparam finish = 3'd6;

reg [2:0] counter;
reg [2:0] current_state;
reg [2:0] next_state;

//counter 
always @(posedge clk)
    begin
        if (current_state == next_addr_ready)
            counter = 0;
        else if (current_state == idle)
            counter = 0;
        else if (current_state == suspend)
            counter = 0;
        else if (current_state == send_finish)
            counter = 0;
        else
            counter = counter + 1;
    end

//state transit
always @(posedge clk or reset)
    begin
        if (reset)
            current_state <= idle;
        else
            current_state <= next_state;
    end


always @(current_state or counter or compute_address or stall)
    begin
        case (current_state)
            idle:
                begin
                    if(compute_address)
                        next_state <= load;
                    else
                        next_state <= idle;
                end

            load:   //load address flit, when counter = 3, next clock current address is ready
                    //if counter = 3, next state is current address ready
                    //if counter < 3, current address is not ready, need to shift register and load address flit
                begin
                    if (counter < address_flit_number - 1)
                        next_state <= load;
                    else
                        next_state <= current_addr_ready;
                end

            current_addr_ready://next address is computed by address compute unit
                                // next clock, new address will be written into next_address_reg
                begin
                    if (stall == 1)
                        next_state <= suspend;
                    else
                        next_state <= send_address;
                end
            /*
            next_addr_ready://next address is stored in registe
                            //if stall = 1, transit to suspend 
                            //else next address can be sent
                begin
                    if (stall == 1)
                        next_state <= suspend;
                    else
                        next_state <= send_address;
                end
            */
            suspend:
                begin
                    if (stall == 1)
                        next_state <= suspend;
                    else
                        next_state <= send_address;
                end
            
            send_address:   //
                begin
                    if (counter < address_flit_number - 1)
                        next_state <= send_address;
                    else
                        next_state <= finish;
                end
            finish:
                begin
                    if (compute_address == 1)
                        next_state <= load;
                    else
                        next_state <= idle;
                end
        endcase
    end

always @(posedge clk or current_state)
    begin
        case (current_state)
            idle:   //all controll signals are 
                begin
                    shift_current_address <= 0;
                    current_address_ready <= 0;
                    next_address_ready <= 0;
                    send_finish <= 0;
                    load_destination_port <= 0;
                    shift_next_address <= 0;
                    load_next_address <= 0;
                end

            load:   //current register start to load and shift address flit
                begin
                    shift_current_address <= 1;
                    current_address_ready <= 0;
                    next_address_ready <= 0;
                    send_finish <= 0;
                    load_destination_port <= 0;
                    shift_next_address <= 0;
                    load_next_address <= 0;
                end
            
            current_addr_ready:
                begin   //load_next_address is high, new address will be written into next_address_reg next clock
                        //current_address_reg stops shifting
                    shift_current_address <= 0;
                    current_address_ready <= 1;
                    next_address_ready <= 0;
                    send_finish <= 0;
                    load_destination_port <= 1;
                    shift_next_address <= 0;
                    load_next_address <= 1 ;
                end
            /*
            next_addr_ready:
                begin   //both current and next address are ready
                    shift_current_address <= 0;
                    current_address_ready = 1;
                    next_address_ready <= 1;
                    send_finish <= 0;
                    load_destination_port <= 0;
                    shift_next_address <= 0;
                    load_next_address <= 0;
                end
                */
            suspend:
                begin   //stop
                    shift_current_address <= 0;
                    current_address_ready <= 1;
                    next_address_ready <=1;
                    send_finish <= 0;
                    load_destination_port <= 0;
                    shift_next_address <= 0;
                    load_next_address <= 0;
                end
            send_address:
                begin   //next_address_reg starts to shift, every clock 4 bits
                    shift_current_address <= 0;
                    current_address_ready <= 0;
                    next_address_ready <= 0;
                    send_finish <= 0;
                    load_destination_port <= 0;
                    shift_next_address <= 1;
                    load_next_address <= 0;
                end
            send_finish:
                begin
                    shift_current_address <= 0;
                    current_address_ready <= 0;
                    next_address_ready <= 0;
                    send_finish <= 1;
                    load_destination_port <= 0;  
                    shift_next_address <= 0;
                    load_next_address <= 0;                 
                end
        endcase
    end
endmodule
