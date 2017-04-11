//2017.4.5  mesh_controller
//          sync with neuron clock. Contains two rom. One rom stores all
//          packet, another stores how many spike are input into network.
//          connect with a router's local port.
//2017.4.6  add a new ram to collect result
//          change packet_number_rom size from 6 to 8
//2017.4.10 change result ram size to 40 bit. High 8 bits record the step when receive spike.
//          lower 32 bits are spike packet.
//2017.4.11 add wait_packet_number state.Because output of rom is buffered, output has one clock
//          delay. 

module mesh_controller(neu_clk, rst_n, rt_clk, rt_reset, start, spike_packet, write_req, packet_in, write_enable, receive_full, result_output);


input neu_clk, rst_n, rt_clk, rt_reset, write_enable;
input [3:0] packet_in;
output reg start;
output [31:0] spike_packet;
output reg write_req;
output receive_full, result_output;

parameter packet_size = 32;
parameter ADDR_WIDTH = 8;
parameter step_number = 32;//how many steps in current simulation
parameter clk_per_step = 32;//how many neuron clocks in one time step
parameter start_delayed_steps = 0;
parameter packet_delayed_steps = 2;

localparam init = 4'd0;
localparam delay = 4'd1;
localparam read_packet_number = 4'd2;
localparam wait_packet_number = 4'd3;
localparam decision = 4'd4;
localparam send = 4'd5;
localparam wait4clk = 4'd6;
localparam idle = 4'd7;
localparam finish = 4'd8;



wire [7:0] packet_number; //number of packets in each step

//--------------------------step_counter---------------------
//recode time step
reg [7:0] step_counter/* synthesis noprune */;
reg inc_step;
always @(posedge neu_clk or negedge rst_n)
    begin
        if (rst_n == 1'b0)
            step_counter <= 0;
        else if (inc_step)
            step_counter <= step_counter + 1;
        else
            step_counter <= step_counter;
    end
//---------------------------------------------------------

//------------------------packet rom, stores all packet---------------
reg [ADDR_WIDTH - 1:0] packet_address;
reg inc_packet_address;
single_port_rom  #(.DATA_WIDTH(32), .ADDR_WIDTH(8), .INIT_FILE_PATH("‪D:/code/SimulationFile/packet.mif"), .SIM_FILE_PATH("D:/code/controller/packet.txt"))
packet_rom (	.addr(packet_address),
	.clk(neu_clk), 
	.q(spike_packet));

//packet rom address
always @(posedge neu_clk or negedge rst_n)
    begin
        if(rst_n == 1'b0)
            packet_address <= 0;
        else if (inc_packet_address)
            packet_address <= packet_address + 1;
        else
            packet_address <= packet_address;
    end
//------------------------------------------------------------------

//-----------------------------packet number rom--------------------
reg [7:0] packet_number_address;
reg inc_packet_number_address;
single_port_rom  #(.DATA_WIDTH(8), .ADDR_WIDTH(8), .INIT_FILE_PATH("‪D:/code/SimulationFile/packet.mif"), .SIM_FILE_PATH("D:/code/controller/packet_number.txt"))
packet_number_rom (	.addr(packet_number_address),
	.clk(neu_clk), 
	.q(packet_number));

//packet_number address
always @(posedge neu_clk or negedge rst_n)
    begin
        if (rst_n == 1'b0)
            packet_number_address <= 0;
        else if (inc_packet_number_address)
            packet_number_address <= packet_number_address + 1;
        else
            packet_number_address <= packet_number_address;
    end
//--------------------------------------------------------------

//----------------------packet_counter-----------------
// count how many packets are read in one step
reg [ADDR_WIDTH - 1:0] packet_counter;
reg clear_packet_counter, inc_packet_counter;

always @(posedge neu_clk or negedge rst_n)
    begin
        if ( rst_n == 1'b0)
            packet_counter <= 0;
        else if(clear_packet_counter == 1'b1)
            packet_counter <= 0;
        else if(inc_packet_counter)
            packet_counter <= packet_counter + 1;
        else
            packet_counter <= packet_counter;
    end
//-----------------------------------------------------------------------

//-----------------------------fourclk_counter------------------------------
reg [3:0] fourclk_counter;
reg clear_fourclk_counter, inc_fourclk_counter;
always @(posedge neu_clk or negedge rst_n)
    begin
        if (rst_n == 1'b0)
            fourclk_counter <= 0;
        else if(clear_fourclk_counter == 1'b1)
            fourclk_counter <= 0;
        else if(inc_fourclk_counter)
            fourclk_counter <= fourclk_counter + 1;
        else
            fourclk_counter <= fourclk_counter;
    end
//----------------------------------------------------------------------------

//-------------------------neuron clock counter---------------------------------
//record how many clock passes in one step
reg [7:0] neu_clk_counter;
reg clear_neu_clk_counter, inc_neu_clk_counter;


//generate start signal
always @(posedge neu_clk or negedge rst_n)
    begin
        if(rst_n == 1'b0)
            neu_clk_counter <= 0;
        else if(clear_neu_clk_counter)
            neu_clk_counter <= 0;
        else if (inc_neu_clk_counter)
            neu_clk_counter <= neu_clk_counter + 1;
        else
            neu_clk_counter <= neu_clk_counter;
    end

always @(*)
    begin
        if (step_counter >= start_delayed_steps)
            begin
                if (neu_clk_counter == clk_per_step)
                    start = 1'b1;
                else
                    start = 1'b0;
            end
        else
            start = 1'b0;
    end
//---------------------------------------------------------

//----------------------------------result------------------------------
wire [31:0] result_packet;
wire receive_fifo_empty;
wire read_receive_fifo;
reg write_result;


spikebuf receive_fifo (
	.aclr ( rt_reset ),
	.data ( packet_in ),
	.rdclk ( neu_clk ),
	.rdreq ( read_receive_fifo ),
	.wrclk ( rt_clk ),
	.wrreq ( write_enable ),
	.q ( result_packet ),
	.rdempty ( receive_fifo_empty ),
	.wrfull ( receive_full )
	);


reg [39:0] result [2**ADDR_WIDTH-1:0];  //8 msb record step number
reg [ADDR_WIDTH - 1:0] result_address_reg;
reg [ADDR_WIDTH - 1:0] result_address;
assign read_receive_fifo = ~ receive_fifo_empty;

always @(posedge neu_clk or negedge rst_n)
    if(rst_n == 1'b0)
        write_result <= 1'b0;
    else
        write_result <= read_receive_fifo;


always @(posedge neu_clk or negedge rst_n)
    begin
        if(rst_n == 1'b0)
            result_address <= 0;
        else if (write_result)
            result_address <= result_address + 1;
        else
            result_address <= result_address;
    end


always @ (posedge neu_clk)
    begin
		if (write_result)
			result[result_address] <= {step_counter, result_packet};
		result_address_reg <= result_address;
	end

assign result_output = ^result[result_address];

//---------------------------------------------------------------

//fsm
reg [3:0] current_state;
reg [3:0] next_state;

//state transition
always @(posedge neu_clk or negedge rst_n)
    begin
        if (rst_n == 1'b0)
            current_state <= init;
        else
            current_state <= next_state;
    end

always @(*)
    begin
        case (current_state)
            init:
                begin
                    if (neu_clk_counter < clk_per_step)
                        next_state <= init;
                    else if (packet_delayed_steps == 0)
                        next_state <= read_packet_number;
                    else
                        next_state <= delay;
                end
            delay:
                begin
                    if (step_counter > packet_delayed_steps)
                        next_state <= decision;
                    else
                        next_state <= delay;
                end
            read_packet_number:
                begin
                    next_state <= wait_packet_number;
                end
            wait_packet_number:
                next_state <= decision;
            decision:
                begin
                    if (packet_number != 0)
                        next_state <= send;
                    else
                        next_state <= idle;
                end
            send:
                begin
                        next_state = wait4clk;
                end
            wait4clk://wait four clock, avoid boundary router's fifo is full. because no mechanism to detect and solve this problem
                begin
                    if (fourclk_counter < 4)
                        next_state = wait4clk;
                    else if (packet_counter < packet_number)
                        next_state = send;
                    else
                        next_state = idle;
                end
            idle:
                begin
                    if (step_counter > step_number)
                        next_state = finish;
                    else if (neu_clk_counter != clk_per_step)
                        next_state <= idle;
                    else
                        next_state = read_packet_number;
                end
            finish:
                begin
                    next_state <= finish;

                end
        default:
                next_state = finish;
        endcase
end

always @(*)
    begin
        case(current_state)
            init:
                begin
                    clear_fourclk_counter = 1'b0;
                    inc_fourclk_counter = 1'b0;
                    inc_packet_counter = 1'b0;
                    clear_packet_counter = 1'b0;
                    inc_packet_address = 1'b0;
                    inc_packet_number_address = 1'b0;
                    write_req = 1'b0;
                    if (neu_clk_counter == clk_per_step)
                        begin
                            clear_neu_clk_counter = 1'b1;
                            inc_neu_clk_counter = 1'b0;
                            inc_step = 1'b1;
                        end
                    else
                        begin
                            clear_neu_clk_counter = 1'b0;
                            inc_neu_clk_counter = 1'b1;
                            inc_step = 1'b0;
                        end
                end
            delay:
                begin
                    clear_fourclk_counter = 1'b0;
                    inc_fourclk_counter = 1'b0;
                    inc_packet_counter = 1'b0;
                    clear_packet_counter = 1'b0;
                    inc_packet_address = 1'b0;
                    inc_packet_number_address = 1'b0;
                    write_req = 1'b0;
                    if (neu_clk_counter == clk_per_step)
                        begin
                            inc_step = 1'b1;
                            clear_neu_clk_counter = 1'b1;
                            inc_neu_clk_counter = 1'b0;
                        end
                    else
                        begin
                            inc_step = 1'b0;
                            clear_neu_clk_counter = 1'b0;
                            inc_neu_clk_counter = 1'b1;
                        end
                end
            read_packet_number:
                begin
                    clear_fourclk_counter = 1'b0;
                    inc_fourclk_counter = 1'b0;
                    inc_packet_counter = 1'b0;
                    clear_packet_counter = 1'b0;
                    inc_packet_address = 1'b0;
                    inc_packet_number_address = 1'b1;
                    write_req = 1'b0;
                    inc_step = 1'b0;
                    clear_neu_clk_counter = 1'b0;
                    inc_neu_clk_counter = 1'b1;
                end
            wait_packet_number:
                begin
                    clear_fourclk_counter = 1'b0;
                    inc_fourclk_counter = 1'b0;
                    inc_packet_counter = 1'b0;
                    clear_packet_counter = 1'b0;
                    inc_packet_address = 1'b0;
                    inc_packet_number_address = 1'b0;
                    write_req = 1'b0;
                    inc_step = 1'b0;
                    clear_neu_clk_counter = 1'b0;
                    inc_neu_clk_counter = 1'b1;
                end
            decision:
                begin
                    clear_fourclk_counter = 1'b0;
                    inc_fourclk_counter = 1'b0;
                    inc_packet_counter = 1'b0;
                    clear_packet_counter = 1'b0;
                    inc_packet_address = 1'b0;
                    inc_packet_number_address = 1'b0;
                    write_req = 1'b0;
                    inc_step = 1'b0;
                    clear_neu_clk_counter = 1'b0;
                    inc_neu_clk_counter = 1'b1;
                end
            send:
                begin
                    clear_fourclk_counter = 1'b0;
                    inc_fourclk_counter = 1'b0;
                    inc_neu_clk_counter = 1'b1;
                    clear_neu_clk_counter = 1'b0;
                    inc_packet_counter = 1'b1;
                    clear_packet_counter = 1'b0;
                    inc_packet_address = 1'b1;
                    inc_packet_number_address = 1'b0;
                    inc_step = 1'b0;
                    write_req = 1'b1;
                end
            wait4clk:
                begin
                    if (fourclk_counter == 4) 
                        begin
                            clear_fourclk_counter = 1'b1;
                            inc_fourclk_counter = 1'b0;    
                        end
                    else  
                        begin
                            clear_fourclk_counter = 1'b0;
                            inc_fourclk_counter = 1'b1;    
                        end
                    inc_neu_clk_counter = 1'b1;
                    clear_neu_clk_counter = 1'b0;
                    inc_packet_counter = 1'b0;
                    clear_packet_counter = 1'b0;
                    inc_packet_address = 1'b0;
                    inc_packet_number_address = 1'b0;
                    inc_step = 1'b0;
                    write_req = 1'b0;
                end
            idle:
                begin
                    if (neu_clk_counter == clk_per_step) 
                        begin
                            inc_neu_clk_counter = 1'b0;
                            clear_neu_clk_counter = 1'b1;
                            inc_step = 1'b1;  
                            clear_packet_counter = 1'b1;    
                            inc_packet_address = 1'b0;
                            inc_packet_number_address = 1'b0;
                        end
                    else 
                        begin
                            clear_packet_counter = 1'b0;
                            inc_neu_clk_counter = 1'b1;
                            clear_neu_clk_counter = 1'b0;
                            inc_step = 1'b0; 
                            inc_packet_address = 1'b0;
                            inc_packet_number_address = 1'b0;
                        end

                    clear_fourclk_counter = 1'b0;
                    inc_fourclk_counter = 1'b0;
                    inc_packet_counter = 1'b0;
                    write_req = 1'b0;
                end
            finish:
                begin
                    clear_fourclk_counter = 1'b0;
                    inc_fourclk_counter = 1'b0;
                    inc_neu_clk_counter = 1'b0;
                    clear_neu_clk_counter = 1'b0;
                    inc_packet_counter = 1'b0;
                    clear_packet_counter = 1'b0;
                    inc_packet_address = 1'b0;
                    inc_packet_number_address = 1'b0;
                    inc_step = 1'b0;
                    write_req = 1'b0;
                end
            default:
                begin
                    clear_fourclk_counter = 1'b0;
                    inc_fourclk_counter = 1'b0;
                    inc_neu_clk_counter = 1'b0;
                    clear_neu_clk_counter = 1'b0;
                    inc_packet_counter = 1'b0;
                    clear_packet_counter = 1'b0;
                    inc_packet_address = 1'b0;
                    inc_packet_number_address = 1'b0;
                    inc_step = 1'b0;
                    write_req = 1'b0;
                end
        endcase
end
     
endmodule