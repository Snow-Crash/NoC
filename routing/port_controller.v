
//2017.2.14 modify send_address state, when sending last address flit
//          read_fifo = 1, read payload from fifo. 
//          if read_fifo = 0 when read last address flit, there will be 1 clock delay
//          between sending address and sending payload

//2017.2.15 add clear_request_reg, when sending payload, clear request register
//2017.2.15 modify read_address state, when at this state, and buffer is empty, stop read
//2017.2.16 change state transition condition of send_address
//2017.2.16 change read_fifo signal at send_address state. 
//          when (counter == address_flit_number), last address flit is sent, read_fifo is high
//          in order to increment fifo read pointer
//2017.2.19 add send_flit signal
//2017.2.20 posedge reset
//2017.3.6  add read_request state, because altera fifo ip can cause 1 clock delay
//2017.3.9  rewrite two counters, add three control signals
//          add read_address_complete state
//          modidy state machine, because the delay of fifo     
//2017.3.13 change port name. buffer_empty to fifo_empty
//           read_buffer to read_fifo
//2017.3.20 fixed a critical bug, when sending address and payload, controller will
//          always check if estination reouter's fifo is full


//--------------to do-----------------
//          reduce the number of states, combine read_address and read_address_complete
//2017.3.21 find a 1 clock delay when stall signal transits from 1 to 0, need to detect stall 
//          stall signal at suspend stage
//2017.4.2  add inc_counter = 0 in current_addr_ready state, avoid latch 
//          next_state causes a latch, change state transition condition in send_payload at line 145, avoid latch, works fine. need more testcases to test.
//2017.4.6  minor problem fix, line 154 non-blocking to blocking 

module port_controller(clk, reset, 
stall, current_address_ready, 
//send_next_address, 
read_fifo, 
fifo_empty, mux_select,
shift_current_address,
load_destination_port,
shift_next_address,
load_next_address,
clear_request_reg,
destination_full);

parameter flit_size = 4;
parameter packet_size = 32;
parameter address_size = 16;

localparam address_flit_number = address_size / flit_size;
localparam flit_number = packet_size / flit_size;
localparam payload_flit_number = flit_number - address_flit_number;

localparam idle = 4'd0;
localparam read_address_request = 4'd1;
localparam read_address = 4'd2;
localparam read_address_complete = 4'd3;
localparam current_addr_ready = 4'd4;
localparam send_address = 4'd5;
localparam send_payload = 4'd6;
localparam suspend = 4'd7;
localparam send_payload_read_address = 4'd8;

localparam select_address = 1'b0;
localparam select_payload = 1'b1;


input clk, reset, stall, fifo_empty, destination_full;

output reg shift_current_address, shift_next_address,
            load_destination_port, load_next_address,
            mux_select, current_address_ready,
            read_fifo, clear_request_reg;

reg [2:0] counter;
reg [3:0] current_state, next_state/* synthesis noprune */;
reg [2:0] shift_counter;
reg clear_counter, clear_shift_counter;
reg inc_counter; 

always @(posedge clk)
    begin
        if(clear_counter)
            counter <= 0;
        else if (inc_counter)
            counter <= counter + 1;
        else
            counter <= counter;
    end

always @(posedge clk)
    begin
        if (clear_shift_counter)
            shift_counter <= 0;
        else if (shift_current_address)
            shift_counter <= shift_counter + 1;
        else
            shift_counter <= shift_counter;
    end


always @(posedge clk or posedge reset) 
    begin
        if (reset)
            current_state <= idle;
        else
            current_state <= next_state;
    end

always @(*)
    begin
        case(current_state)
            idle:
                if (fifo_empty)
                    next_state = idle;
                else
                    next_state = read_address_request;
            read_address_request:
                next_state = read_address;
            read_address:
                if (shift_counter < address_flit_number - 2)
                //shift_counter < address_flit_number - 1 is correct
                    next_state = read_address;
                //2017.3.9 address_flit_number - 2,because read_request state is added
                else if ((shift_counter == address_flit_number - 2) && (fifo_empty == 1))
                    next_state = read_address;
                else
                    next_state = read_address_complete;
            read_address_complete:
                next_state = current_addr_ready;
            current_addr_ready:  //make decision, send or stall
                if (stall == 1)
                    next_state = suspend;
                else
                    next_state = send_address;
            send_address:
                if (counter < address_flit_number - 1)
                    next_state = send_address;
                else
                    next_state = send_payload;
            send_payload:
                if (counter < flit_number - 1)
                    next_state = send_payload;
                else if(fifo_empty == 0)
                    next_state <= read_address;
                else// if (fifo_empty == 1)
                    next_state = idle;
                //2017.4.2 cause latch, need to exmaine transition conditions to eliminate
            suspend:
                if (stall == 1)
                    next_state = suspend;
                else
                    next_state = send_address;
            default:
                next_state = idle;
        endcase
    end

always @(*)
    begin
        case(current_state)
            idle:
                begin
                    shift_current_address = 0;
                    current_address_ready = 0;
                    load_destination_port = 0;
                    shift_next_address = 0;
                    load_next_address = 0;
                    read_fifo = 0;
                    mux_select = select_address;
                    clear_request_reg = 1;
                    clear_counter = 1;
                    clear_shift_counter = 1;
                    inc_counter = 0;
                end
            read_address_request:
                begin
                    current_address_ready = 0;
                    load_destination_port = 0;
                    shift_next_address = 0;
                    load_next_address = 0;
                    mux_select = select_address;
                    clear_request_reg = 0;
                    shift_current_address = 0; 
                    read_fifo = 1;
                    clear_counter = 0;
                    clear_shift_counter = 0;
                    inc_counter = 0;
                end
            read_address:
                begin
                    current_address_ready = 0;
                    load_destination_port = 0;
                    shift_next_address = 0;
                    load_next_address = 0;
                    mux_select = select_address;
                    clear_request_reg = 0;
                    clear_counter = 0;
                    clear_shift_counter = 0;
                    inc_counter = 0;
                    if (fifo_empty == 0)
                        begin
                            shift_current_address = 1; 
                            read_fifo = 1;
                        end
                    else//2.16 avoid reading wrong address if buffer is empty
                        begin
                            shift_current_address = 0;
                            read_fifo = 0;
                        end
                end
            read_address_complete:
                begin
                    current_address_ready = 0;
                    load_destination_port = 0;
                    shift_next_address = 0;
                    load_next_address = 0;
                    mux_select = select_address;
                    clear_request_reg = 0;
                    shift_current_address = 1;
                    read_fifo = 0;
                    clear_counter = 0;
                    clear_shift_counter = 0;
                    inc_counter = 0;
                    
                end
            current_addr_ready:
                begin
                    shift_current_address = 0;
                    current_address_ready = 1;
                    load_destination_port = 1;
                    shift_next_address = 0;
                    load_next_address = 1;
                    read_fifo = 0;
                    mux_select = select_address;
                    clear_request_reg = 0;
                    clear_counter = 1;
                    clear_shift_counter = 1;
                    inc_counter = 0;//may cause latch, should add this statement, no time to test
                end
            suspend:
                begin
                    shift_current_address = 0;
                    current_address_ready = 1;
                    load_destination_port = 0;
                    shift_next_address = 0;
                    load_next_address = 0;
                    read_fifo = 0; 
                    mux_select = select_address;
                    clear_request_reg = 0;
                    clear_counter = 1;
                    clear_shift_counter = 1;
                    inc_counter = 0;
                end
            send_address:
                begin
                    shift_current_address = 0;
                    current_address_ready = 0;
                    load_destination_port = 0;
                    
                    load_next_address = 0;        
                    mux_select = select_address;
                    clear_shift_counter = 1;
                    if (counter == address_flit_number - 1 )
                    //2.16 change from counter < address_flit_number - 1 to counter < address_flit_number
                        read_fifo = 1; 
                    else 
                        read_fifo = 0;
                    clear_request_reg = 0;
                    clear_counter = 0;
                    if (destination_full == 0)
                        begin
                            inc_counter = 1;
                            shift_next_address = 1;
                        end
                    else
                        begin
                            inc_counter = 0;
                            shift_next_address = 0;
                        end
                end
            send_payload:
                begin
                    shift_current_address = 0;
                    current_address_ready = 0;
                    load_destination_port = 0;
                    shift_next_address = 0;
                    load_next_address = 0;
                    if ((counter <= flit_number - 1) && (fifo_empty == 0) && (destination_full == 0))
                        begin
                            inc_counter = 1;
                            read_fifo = 1;
                        end
                    else //if (counter == flit_number - 1)
                        begin
                            inc_counter = 0;
                            read_fifo = 0;
                        end
                    mux_select = select_payload;
                    if (counter == flit_number - 1)
                        clear_request_reg = 1;
                    else
                        clear_request_reg = 0;
                    clear_counter = 0;
                    clear_shift_counter = 0;
                end
            default:
                begin
                    shift_current_address = 0;
                    current_address_ready = 0;
                    load_destination_port = 0;
                    shift_next_address = 0;
                    load_next_address = 0;
                    read_fifo = 0; 
                    mux_select = 0;
                    clear_request_reg = 0;
                    clear_counter = 0;
                    inc_counter = 0;
                end
        endcase
    end

endmodule


