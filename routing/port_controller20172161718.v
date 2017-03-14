
//2017.2.14 modify send_address state, when sending last address flit
//read_buffer = 1, read payload from fifo. 
//if read_buffer = 0 when read last address flit, there will be 1 clock delay
//between sending address and sending payload

//2017.2.15 add clear_request_reg, when sending payload, clear request register
//2017.2.15 modify read_address state, when at this state, and buffer is empty, stop read

module port_controller(clk, reset, 
stall, current_address_ready, 
//send_next_address, 
read_buffer, 
buffer_empty, mux_select,
shift_current_address,
load_destination_port,
shift_next_address,
load_next_address,
clear_request_reg);

parameter flit_size = 4;
parameter packet_size = 32;
parameter address_size = 16;

localparam address_flit_number = address_size / flit_size;
localparam flit_number = packet_size / flit_size;
localparam payload_flit_number = flit_number - address_flit_number;

localparam idle = 4'd0;
//localparam compute_address = 4'd1;
localparam read_address = 4'd2;
localparam current_addr_ready = 4'd3;
//localparam routing_result_ready
//localparam wait_arbiter
localparam send_address = 4'd4;
localparam send_payload = 4'd5;
localparam suspend = 4'd6;
localparam send_payload_read_address = 4'd7;
//localparam read_address_stall = 4'd8;

localparam select_address = 1'b0;
localparam select_payload = 1'b1;


input clk, reset, stall, buffer_empty;

output reg shift_current_address, shift_next_address,
            load_destination_port, load_next_address,
            mux_select, current_address_ready,
            read_buffer,clear_request_reg;

reg [2:0] counter;
reg [4:0] current_state, next_state;

always @(posedge clk)
    begin
        if (current_state == idle)
            counter <= 0;
        else if (current_state == suspend)
            counter <= 0;
        else if (current_state == current_addr_ready)
            counter <= 0;
        else if(current_state == read_address && buffer_empty)
            counter <= counter ;
        else
            counter <= counter + 1;

    end

always @(posedge clk or reset) 
    begin
        if (reset)
            current_state <= 0;
        else
            current_state <= next_state;
    end

always @(current_state or counter or stall or buffer_empty)
    begin
        case(current_state)
            idle:
                if (buffer_empty)
                    next_state <= idle;
                else
                    next_state <= read_address;
            read_address:
                if (counter < address_flit_number - 1)
                //2.16 change from counter < address_flit_number - 1 to counter < address_flit_number
                    next_state <= read_address;
                else
                    next_state <= current_addr_ready;
            current_addr_ready:  //make decision, send or stall
                if (stall == 1)
                    next_state <= suspend;
                else
                    next_state <= send_address;
            send_address:
                if (counter < address_flit_number - 1)
                    next_state <= send_address;
                else
                    next_state <= send_payload;
            send_payload:
                if (counter < flit_number - 1)
                    next_state <= send_payload;
                else if(buffer_empty == 0)
                    next_state <= read_address;
                else if (buffer_empty == 1)
                    next_state <= idle;
            suspend:
                if (stall == 1)
                    next_state <= suspend;
                else
                    next_state <= send_address;
            //send_payload_read_address:
            //    next_state <= read_address;
        endcase
    end

always @(posedge clk or current_state or counter)
    begin
        case(current_state)
            idle:
                begin
                    shift_current_address <= 0;
                    current_address_ready <= 0;
                    load_destination_port <= 0;
                    shift_next_address <= 0;
                    load_next_address <= 0;
                    read_buffer <= 0;
                    mux_select <= select_address;
                    clear_request_reg <= 1;
                end
            read_address:
                begin
                    if (buffer_empty == 0)
                        begin
                            shift_current_address <= 1;
                            current_address_ready <= 0;
                            load_destination_port <= 0;
                            shift_next_address <= 0;
                            load_next_address <= 0;
                            read_buffer <= 1;
                            mux_select <= select_address;
                            clear_request_reg <= 0;
                        end
                    else//2.16 avoid read wrong address if buffer is empty
                        begin
                            shift_current_address <= 0;
                            current_address_ready <= 0;
                            load_destination_port <= 0;
                            shift_next_address <= 0;
                            load_next_address <= 0;
                            read_buffer <= 0;
                            mux_select <= select_address;
                            clear_request_reg <= 0;
                        end
                end
            current_addr_ready:
                begin
                    shift_current_address <= 0;
                    current_address_ready <= 1;
                    load_destination_port <= 1;
                    shift_next_address <= 0;
                    load_next_address <= 1;
                    read_buffer <= 0;
                    mux_select <= select_address;
                    clear_request_reg <= 0;
                end
            suspend:
                begin
                    shift_current_address <= 0;
                    current_address_ready <= 1;
                    load_destination_port <= 0;
                    shift_next_address <= 0;
                    load_next_address <= 0;
                    read_buffer <= 0; 
                    mux_select <= select_address;
                    clear_request_reg = 0;
                end
            send_address:
                begin
                    shift_current_address <= 0;
                    current_address_ready <= 0;
                    load_destination_port <= 0;
                    shift_next_address <= 1;
                    load_next_address <= 0;        
                    mux_select <= select_address;
                    if (counter == address_flit_number )
                    //2.16 change from counter < address_flit_number - 1 to counter < address_flit_number
                        read_buffer <= 1; 
                    else 
                        read_buffer <= 0;
                    clear_request_reg <= 0;
                end
            send_payload:
                begin
                    shift_current_address <= 0;
                    current_address_ready <= 0;
                    load_destination_port <= 0;
                    shift_next_address <= 0;
                    load_next_address <= 0;
                    read_buffer <= 1; 
                    mux_select <= select_payload;
                    clear_request_reg <= 1;
                end
            /*
            send_payload_read_address:
                begin
                    shift_current_address <= 1;
                    current_address_ready <= 0;
                    load_destination_port <= 0;
                    shift_next_address <= 0;
                    load_next_address <= 0;
                    read_buffer <= 1; 
                    mux_select <= select_payload;

                end
            */
        endcase
    end

endmodule


