module mesh_controller(neu_clk, rt_reset,rst_n, rt_clk, start, spike_packet, write_req);


input neu_clk, rt_clk, rt_reset, rst_n;
output reg start;
output [31:0] spike_packet;
output reg write_req;

parameter packet_size = 32;
parameter spike_number = 32;
parameter ADDR_WIDTH = 8;
parameter step_number = 32;
parameter rt_counter_limit = 64;
parameter neu_counter_limit = 32;

localparam idle = 3'd0;
localparam init = 3'd1;
localparam send = 3'd2;
localparam wait8clk = 3'd3;

reg [ADDR_WIDTH - 1:0] spike_rom_address;
reg inc_address;
//packet rom, stores all packet
reg [packet_size - 1:0] spike_rom[9:0];//
reg [31:0] spike_rom_out;
// store how many packets are read in one step
reg [5:0] step_rom[9:0];
reg [5:0] step_rom_out;
reg [9:0] packet_counter;
reg clear_packet_counter, inc_packet_counter, inc_step;
reg [6:0] step_counter;
reg [9:0] neu_counter;

//initialize spike_rom; spike_rom contains all the spike packets
initial
    begin
		$readmemh("spikerom.txt", spike_rom);
	end
//spike_rom
always @ (posedge rt_clk)
    begin
		spike_rom_out <= spike_rom[spike_rom_address];
	end
assign spike_packet = spike_rom_out;

//initialize step_rom. step_rom store each step how many packets are read
initial
    begin
		$readmemb("steprom.txt", step_rom);
	end
//step_rom
always @ (posedge rt_clk)
    begin
		step_rom_out <= step_rom[step_counter];
	end
//--------------------------------------------------------------


//--------------------------step_counter---------------------
always @(posedge rt_clk or posedge rt_reset)
    begin
        if (rt_reset == 1'b1)
            step_counter <= 0;
        else if (inc_step)
            step_counter <= step_counter + 1;
        else
            step_counter <= step_counter;
    end
//---------------------------------------------------------

//packet_counter

always @(posedge rt_clk or posedge rt_reset)
    begin
        if (rt_reset == 1'b1)
            packet_counter <= 0;
        else if(clear_packet_counter == 1'b1)
            packet_counter <= 0;
        else if(inc_packet_counter)
            packet_counter <= packet_counter + 1;
        else
            packet_counter <= packet_counter;
    end

//eightclk_counter
reg [3:0] eightclk_counter;
reg clear_eightclk_counter, inc_eightclk_counter;
always @(posedge rt_clk or posedge rt_reset)
    begin
        if (rt_reset == 1'b1)
            eightclk_counter <= 0;
        if(clear_eightclk_counter == 1'b1)
            eightclk_counter <= 0;
        else if(inc_eightclk_counter)
            eightclk_counter <= eightclk_counter + 1;
        else if (eightclk_counter == 8)
            eightclk_counter <= eightclk_counter;
    end

// rt_counter
reg [9:0] rt_counter;
reg inc_rt_counter, clear_rt_counter;
always @(posedge rt_clk or posedge rt_reset)
    begin
        if (rt_reset == 1'b1)
            rt_counter <= 0;
        else if(clear_rt_counter == 1'b1)
            rt_counter <= 0;
        else if(inc_rt_counter)
            rt_counter <= rt_counter + 1;
        else
            rt_counter <= rt_counter;
    end

//spike rom address
always @(posedge rt_clk or rt_reset)
    begin
        if(rt_reset)
            spike_rom_address = 0;
        else if (inc_address)
            spike_rom_address <= spike_rom_address + 1;
        else
            spike_rom_address <= spike_rom_address;
    end

//fsm
reg [2:0] current_state;
reg [2:0] next_state;

//state transition
always @(posedge rt_clk or posedge rt_reset)
    begin
        if (rt_reset == 1'b1)
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
                        next_state = wait8clk;
                end
            wait8clk:
                begin
                    if (eightclk_counter < 8)
                        next_state = wait8clk;
                    else if (packet_counter < step_rom_out)
                        next_state = send;
                    else
                        next_state = idle;
                end
            idle:
                begin
                    if (rt_counter < rt_counter_limit)
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
                    clear_eightclk_counter = 1'b1;
                    inc_eightclk_counter = 1'b0;
                    inc_rt_counter = 1'b0;
                    clear_rt_counter = 1'b1;
                    inc_packet_counter = 1'b0;
                    clear_packet_counter = 1'b1;
                    inc_address = 1'b0;
                    inc_step = 1'b0;
                    write_req = 1'b0;
                end
            send:
                begin
                    write_req = 1'b1;
                    clear_eightclk_counter = 1'b0;
                    inc_eightclk_counter = 1'b0;
                    inc_rt_counter = 1'b1;
                    clear_rt_counter = 1'b0;
                    inc_packet_counter = 1'b1;
                    clear_packet_counter = 1'b0;
                    inc_address = 1'b1;
                    inc_step = 1'b0;
                end
            wait8clk:
                begin
                    write_req = 1'b0;
                    inc_rt_counter = 1'b1;
                    clear_rt_counter = 1'b0;
                    clear_packet_counter = 1'b0;
                    inc_packet_counter = 1'b0;
                    inc_address = 1'b0;
                    inc_step = 1'b0;
                    if (eightclk_counter == 8) begin
                        clear_eightclk_counter = 1'b1;
                        inc_eightclk_counter = 1'b0;    end
                    else    begin
                        clear_eightclk_counter = 1'b0;
                        inc_eightclk_counter = 1'b1;    end
                end
            idle:
                begin
                    write_req = 1'b0;
                    clear_eightclk_counter = 1'b0;
                    inc_eightclk_counter = 1'b0;
                    
                    inc_packet_counter = 1'b0;
                    inc_address = 1'b0;
                    clear_rt_counter = 1'b0;
                    if (rt_counter == rt_counter_limit) begin
                        inc_rt_counter = 1'b0;
                        clear_rt_counter = 1'b1;
                        inc_step = 1'b1;  
                        clear_packet_counter = 1'b1;    end
                    else begin
                        clear_packet_counter = 1'b0;
                        inc_rt_counter = 1'b1;
                        clear_rt_counter = 1'b0;
                        inc_step = 1'b0; end
                end
            default:
                begin
                    write_req = 1'b0;
                    clear_eightclk_counter = 1'b0;
                    inc_eightclk_counter = 1'b0;
                    clear_packet_counter = 1'b0;
                    inc_packet_counter = 1'b0;
                    inc_address = 1'b0;
                    inc_rt_counter = 1'b0;
                    clear_rt_counter = 1'b0;
                    inc_step = 1'b0;
                end
        endcase
end


//generate start signal
always @(posedge neu_clk or negedge rst_n)
    begin
        if(rst_n == 1'b0)
            neu_counter <= 0;
        else if(neu_counter == neu_counter_limit)
            neu_counter <= 0;
        else
            neu_counter <= neu_counter + 1;
    end

always @(*)
    if (neu_counter == neu_counter_limit)
        start = 1'b1;
    else
        start = 1'b0;


        
endmodule