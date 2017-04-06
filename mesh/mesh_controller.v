//2017.4.5  mesh_controller
//          sync with neuron clock. Contains two rom. One rom stores all
//          packet, another stores how many spike are input into network.
//          connect with a router's local port.


module mesh_controller(neu_clk, rst_n, rt_clk, rt_reset, start, spike_packet, write_req, packet_in, write_enable, receive_full);


input neu_clk, rst_n, rt_clk, rt_reset, write_enable;
input [3:0] packet_in;
output reg start;
output [31:0] spike_packet;
output reg write_req;
output receive_full;

parameter packet_size = 32;
parameter spike_number = 32;
parameter ADDR_WIDTH = 8;
parameter step_number = 32;
parameter step_cycle = 32;

localparam idle = 3'd0;
localparam init = 3'd1;
localparam send = 3'd2;
localparam wait4clk = 3'd3;

reg [ADDR_WIDTH - 1:0] spike_rom_address;
reg inc_spike_rom_address;
//packet rom, stores all packet
reg [31:0] spike_rom[2**ADDR_WIDTH - 1:0];//
reg [31:0] spike_rom_out;
// store how many packets are read in one step
reg [5:0] packet_number_rom[2**ADDR_WIDTH - 1:0];
reg [5:0] packet_number_rom_out;
reg [9:0] packet_counter;
reg clear_packet_counter, inc_packet_counter, inc_step;
reg [9:0] step_counter;
reg [9:0] neu_cycle_counter;

reg clear_neu_cycle_counter, inc_neu_cycle_counter;

wire [31:0] result_packet, result_output;
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


assign read_receive_fifo = ~ receive_fifo_empty;

reg [31:0] result [2**ADDR_WIDTH-1:0];
reg [ADDR_WIDTH - 1:0] result_address_reg;
reg [ADDR_WIDTH - 1:0] result_address;

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
			result[result_address] <= result_packet;
		result_address_reg <= result_address;
	end

assign result_output = result[result_address];



//initialize spike_rom; spike_rom contains all the spike packets
initial
    begin
		$readmemh("spikerom.txt", spike_rom);
	end
//spike_rom
always @ (posedge neu_clk or negedge rst_n)
    begin
        if(rst_n == 1'b0)
            spike_rom_out <= 0;
        else
		    spike_rom_out <= spike_rom[spike_rom_address];
	end
assign spike_packet = spike_rom_out;

//initialize packet_number_rom. packet_number_rom store each step how many packets are read
initial
    begin
		$readmemb("steprom.txt", packet_number_rom);
	end
//packet_number_rom
always @ (posedge neu_clk or negedge rst_n)
    begin
        if (rst_n == 1'b0)
            packet_number_rom_out <= 0;
        else
		    packet_number_rom_out <= packet_number_rom[step_counter];
	end
//--------------------------------------------------------------


//--------------------------step_counter---------------------
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

//packet_counter

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

//fourclk_counter
reg [3:0] fourclk_counter;
reg clear_fourclk_counter, inc_fourclk_counter;
always @(posedge neu_clk or negedge rst_n)
    begin
        if (rst_n == 1'b0)
            fourclk_counter <= 0;
        if(clear_fourclk_counter == 1'b1)
            fourclk_counter <= 0;
        else if(inc_fourclk_counter)
            fourclk_counter <= fourclk_counter + 1;
        else if (fourclk_counter == 8)
            fourclk_counter <= fourclk_counter;
    end

//spike rom address
always @(posedge neu_clk or negedge rst_n)
    begin
        if(rst_n == 1'b0)
            spike_rom_address = 0;
        else if (inc_spike_rom_address)
            spike_rom_address <= spike_rom_address + 1;
        else
            spike_rom_address <= spike_rom_address;
    end

//fsm
reg [2:0] current_state;
reg [2:0] next_state;

//state transition
always @(posedge neu_clk or negedge rst_n)
    begin
        if (rst_n == 1'b0)
            current_state <= idle;
        else
            current_state <= next_state;
    end

always @(*)
    begin
        case (current_state)
            init:
                begin
                    if (step_counter < step_number)
                        next_state = send;
                    else
                        next_state = init;
                end
            send:
                begin
                        next_state = wait4clk;
                end
            wait4clk:
                begin
                    if (fourclk_counter < 4)
                        next_state = wait4clk;
                    else if (packet_counter < packet_number_rom_out)
                        next_state = send;
                    else
                        next_state = idle;
                end
            idle:
                begin
                    if (neu_cycle_counter < step_cycle)
                            next_state = idle;
                    else
                        next_state = send;
                end
        default:
                next_state <= init;
        endcase
end

always @(*)
    begin
        case(current_state)
            init:
                begin
                    clear_fourclk_counter = 1'b1;
                    inc_fourclk_counter = 1'b0;
                    inc_neu_cycle_counter = 1'b0;
                    clear_neu_cycle_counter = 1'b1;
                    inc_packet_counter = 1'b0;
                    clear_packet_counter = 1'b1;
                    inc_spike_rom_address = 1'b0;
                    inc_step = 1'b0;
                    write_req = 1'b0;
                end
            send:
                begin
                    write_req = 1'b1;
                    clear_fourclk_counter = 1'b0;
                    inc_fourclk_counter = 1'b0;
                    inc_neu_cycle_counter = 1'b1;
                    clear_neu_cycle_counter = 1'b0;
                    inc_packet_counter = 1'b1;
                    clear_packet_counter = 1'b0;
                    inc_spike_rom_address = 1'b1;
                    inc_step = 1'b0;
                end
            wait4clk:
                begin
                    write_req = 1'b0;
                    inc_neu_cycle_counter = 1'b1;
                    clear_neu_cycle_counter = 1'b0;
                    clear_packet_counter = 1'b0;
                    inc_packet_counter = 1'b0;
                    inc_spike_rom_address = 1'b0;
                    inc_step = 1'b0;
                    if (fourclk_counter == 4) begin
                        clear_fourclk_counter = 1'b1;
                        inc_fourclk_counter = 1'b0;    end
                    else  begin
                        clear_fourclk_counter = 1'b0;
                        inc_fourclk_counter = 1'b1;    end
                end
            idle:
                begin
                    write_req = 1'b0;
                    clear_fourclk_counter = 1'b0;
                    inc_fourclk_counter = 1'b0;
                    
                    inc_packet_counter = 1'b0;
                    inc_spike_rom_address = 1'b0;
                    clear_neu_cycle_counter = 1'b0;
                    if (neu_cycle_counter == step_cycle) begin
                        inc_neu_cycle_counter = 1'b0;
                        clear_neu_cycle_counter = 1'b1;
                        inc_step = 1'b1;  
                        clear_packet_counter = 1'b1;    end
                    else begin
                        clear_packet_counter = 1'b0;
                        inc_neu_cycle_counter = 1'b1;
                        clear_neu_cycle_counter = 1'b0;
                        inc_step = 1'b0; end
                end
            default:
                begin
                    write_req = 1'b0;
                    clear_fourclk_counter = 1'b0;
                    inc_fourclk_counter = 1'b0;
                    clear_packet_counter = 1'b0;
                    inc_packet_counter = 1'b0;
                    inc_spike_rom_address = 1'b0;
                    inc_neu_cycle_counter = 1'b0;
                    clear_neu_cycle_counter = 1'b0;
                    inc_step = 1'b0;
                end
        endcase
end


//generate start signal
always @(posedge neu_clk or negedge rst_n)
    begin
        if(rst_n == 1'b0)
            neu_cycle_counter <= 0;
        else if(clear_neu_cycle_counter)
            neu_cycle_counter <= 0;
        else if (inc_neu_cycle_counter)
            neu_cycle_counter <= neu_cycle_counter + 1;
        else
            neu_cycle_counter <= neu_cycle_counter;
    end

always @(*)
    if (neu_cycle_counter == step_cycle)
        start = 1'b1;
    else
        start = 1'b0;


        
endmodule