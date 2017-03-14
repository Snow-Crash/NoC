//2017.2.20 posedge reset

module deserializer_controller(clk, reset, receive, deserializer_idle, deserializer_finish);

parameter address_bit_width = 16;
parameter input_size = 32;
parameter phit_size = 4;
parameter phit_number =input_size / phit_size;

localparam idle = 3'b000,
            start = 3'b001,
            deserializing = 3'b010,
            stop = 3'b100;

localparam counter_stop = phit_number;

input clk, reset, receive;
output reg deserializer_idle;
output reg deserializer_finish;

reg [2:0] counter;
reg [2:0] current_state;
reg [2:0] next_state;

always @(posedge clk) 
    begin
        if (current_state == stop)
            counter <= 0;
        else if(current_state == idle)
            counter <= 0;
        else
            counter <= counter + 1;
    end

always @(posedge clk or posedge reset) 
    begin
        if(reset)
            current_state <= idle;
        else
            current_state <= next_state;
    end

always @(current_state or counter or receive) 
    begin
        case (current_state)
            idle:
                begin
                    if(receive)
                        next_state <= start;
                    else
                        next_state <= idle;
                end
            start:
                next_state <= deserializing;
            deserializing:
                begin
                    if (counter != counter_stop - 1)
                        next_state <= deserializing;
                    else
                        next_state <= stop;
                end
            stop:
                begin
                    if(receive)
                        next_state <= start;
                    else
                        next_state <= idle;
                end
 
        endcase
    end

always @(posedge clk or current_state) 
    begin
        case (current_state)
            idle:
                begin
                    deserializer_idle <= 1;
                    deserializer_finish <= 0;
                end
            start:
                begin
                    deserializer_idle <= 0;
                    deserializer_finish <= 0;
                end
            deserializing:
                begin
                    deserializer_idle <= 0;
                    deserializer_finish <= 0;
                end
            stop:
                begin
                    deserializer_finish <= 1;
                    deserializer_idle <= 0;
                end
        endcase        
    end

endmodule