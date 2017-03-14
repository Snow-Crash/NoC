//`include "serializer.v"
//`include "shift_register"
//2017.2.20  posedge reset

//asynchronous reset
//
module serializer_controller (clk, reset, fifo_empty, read_fifo, shift_register_load, serializer_idle);
localparam input_size = 32;
localparam output_size = 4;
localparam phit_number = input_size / output_size;
localparam counter_stop = phit_number;

localparam [2:0] idle = 3'b000,
                load = 3'b001,
                serializing = 3'b010,
                serializing_stop = 3'b100;

input clk, fifo_empty, reset;
output reg read_fifo, serializer_idle, shift_register_load;

reg [2:0] counter;
reg [2:0] current_state;
reg [2:0] next_state;

always @(posedge clk)
    begin
        if (current_state == serializing_stop)
            counter = 0;
        else if (current_state == idle)
            counter = 0;
        else
            counter = counter + 1;
    end
//state transition
//asynchronous reset 
always @(posedge clk or posedge reset) 
    begin
        if (reset)  //if reset = high, state transits to idle
            begin
                current_state <= idle;
            end
        else
            begin
                current_state <= next_state;
            end
    end

//
always @(current_state or fifo_empty or counter) 
    begin
        case (current_state)
            idle: 
                begin
                    if(!fifo_empty)     //if fifo not empty, read data from fifo 
                        next_state <= load;
                    else                //if empty, stay idle
                        next_state <= idle;
                end
            load:
                begin   //start to serialize data
                    next_state <= serializing;
                end
            serializing:
                begin   //counter counts how many phits are already transmitted, every clock cycle counter increases by 1
                    if (counter != counter_stop - 1 )
                        next_state <= serializing;
                    else    //
                        next_state <= serializing_stop;
                    end
            serializing_stop://last phit is sent, if fifo is empty, transit to idle otherwise transit to load
                begin
                    if (!fifo_empty)
                        next_state <= load;
                    else
                        next_state <= idle;
                end
        endcase
    end

always @(current_state) 
    begin
        case (current_state)
            idle:
                begin
                    serializer_idle = 1;
                    shift_register_load = 0;
                    read_fifo = 0;
                    //counter = 0;
                end
            load:
                begin
                    read_fifo = 1;
                    serializer_idle = 0;
                    shift_register_load = 1;
                    //counter = counter + 1;
                end
            serializing:
                begin
                    read_fifo = 0;
                    serializer_idle = 0;
                    shift_register_load = 0;
                    //counter = counter + 1;
                end
            serializing_stop:
                begin
                    read_fifo = 0;
                    serializer_idle = 0;
                    shift_register_load = 0;
                    //counter = 0;
                end
        endcase
    end

endmodule // 