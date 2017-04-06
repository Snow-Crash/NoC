//1017.4.6  fix connection error
//          add parameter step_number, step_cycle, nuron_num, axon_num..

`timescale 1ns/100ps
`define tpd_clk 10

module mesh_with_controller(neu_clk, neu_reset, rt_clk, rt_reset, result_output);

parameter NUM_NURNS = 2;
parameter NUM_AXONS = 2;
parameter NURN_CNT_BIT_WIDTH = 1;
parameter AXON_CNT_BIT_WIDTH = 1;
parameter step_number = 32; //how many steps in current simulation
parameter step_cycle = 64;  //how many neuron clocks in one time step

input neu_clk, neu_reset, rt_clk, rt_reset;
output result_output;

wire start;
wire [31:0] spike_packet_c2b;
wire [3:0] data_b2m, data_m2b, spike_packet_b2c;
wire write_req_b2m, write_req_m2b, write_req_c2b, write_req_b2c;
wire full_m2b, fullb2m, full_c2b;


mesh_controller #(.step_number(step_number), .step_cycle(step_cycle)) 
mesh_control (.neu_clk(neu_clk),
                                .rst_n(neu_reset),
                                .rt_clk(rt_clk),
                                .rt_reset(rt_reset),
                                .start(start), 
                                .spike_packet(spike_packet_c2b), 
                                .write_req(write_req_c2b),
                                .packet_in(spike_packet_b2c),
                                .write_enable(write_req_b2c),
                                .receive_full(full_c2b),
                                .result_output(result_output));

router boundary (.clk(rt_clk), .clk_local(neu_clk), .clk_north(), .clk_south(rt_clk), .clk_east(rt_clk), .clk_west(rt_clk),
.reset(rt_reset), .local_in(spike_packet_c2b), .north_in(4'b0), .south_in(4'b0), .east_in(4'b0), .west_in(data_m2b),
.local_out(spike_packet_b2c), .north_out(), .south_out(), .east_out(), .west_out(data_b2m),
.local_full(), .north_full(), .south_full(), .east_full(), .west_full(fullb2m),
.local_neuron_full(full_c2b), .north_neighbor_full(1'b0), .south_neighbor_full(1'b0), .east_neighbor_full(1'b0), .west_neighbor_full(full_m2b),
.write_en_local(write_req_c2b), .write_en_north(1'b0), .write_en_south(1'b0), .write_en_east(1'b0), .write_en_west(write_req_m2b),
.write_req_local(write_req_b2c), .write_req_north(), .write_req_south(), .write_req_east(), .write_req_west(write_req_b2m));


mesh_ap #(.NUM_NURNS(NUM_NURNS),
            .NUM_AXONS(NUM_AXONS),
            .NURN_CNT_BIT_WIDTH(NURN_CNT_BIT_WIDTH),
            .AXON_CNT_BIT_WIDTH(AXON_CNT_BIT_WIDTH))
mesh (.clk(neu_clk), .rt_clk(rt_clk), .rst_n(neu_reset), .rt_reset(rt_reset), .start(start),
.north_out_1_1(), .north_out_1_2(), .south_out_2_1(), .south_out_2_2(), 
.east_out_1_2(data_m2b), .east_out_2_2(), .west_out_1_1(), .west_out_2_1(), 
.south_full_2_1(), .south_full_2_2(), .north_full_1_1(), .north_full_1_2(),
.east_full_1_2(full_m2b), .east_full_2_2(), .west_full_1_1(), .west_full_2_1(),
.north_w_1_1(), .north_w_1_2(), .south_w_2_1(), .south_w_2_2(),//write request
.east_w_1_2(write_req_m2b), .east_w_2_2(), .west_w_1_1(), .west_w_2_1(),
.e_in_1_2(data_b2m), .e_in_2_2(4'b0), .w_in_1_1(4'b0), .w_in_2_1(4'b0), 
.s_in_2_1(4'b0), .s_in_2_2(4'b0), .n_in_1_1(4'b0), .n_in_1_2(4'b0),//input data
.n_en_1_1(1'b0), .n_en_1_2(1'b0), .e_en_1_2(write_req_b2m), .e_en_2_2(1'b0), 
.w_en_1_1(1'b0), .w_en_2_1(1'b0), .s_en_2_1(1'b0), .s_en_2_2(1'b0),//write enable
.w_n_full_1_1(1'b0), .w_n_full_2_1(1'b0), .e_n_full_2_2(1'b0), .e_n_full_1_2(fullb2m), 
.s_n_full_2_1(1'b0), .s_n_full_2_2(1'b0), .n_n_full_1_1(1'b0), .n_n_full_1_2(1'b0));

endmodule