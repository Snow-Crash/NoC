`timescale 1ns/100ps
`define tpd_clk 5

module mesh_ap(clk, rt_clk,, rst_n, rt_reset, north_out_1_1,
north_out_1_2, south_out_2_1, south_out_2_2, east_out_1_2, east_out_2_2, west_out_1_1,
west_out_2_1, south_full_2_1, south_full_2_2, north_full_1_1,north_full_1_2,
east_full_1_2, east_full_2_2, west_full_1_1, west_full_2_1,
north_w_1_1, north_w_1_2, south_w_2_1, south_w_2_2,//write request
east_w_1_2, east_w_2_2, west_w_1_1, west_w_2_1, start,
e_in_1_2, e_in_2_2, w_in_1_1, w_in_2_1, s_in_2_1, s_in_2_2, n_in_1_1, n_in_1_2,//input data
n_en_1_1, n_en_1_2, e_en_1_2, e_en_2_2, w_en_1_1, w_en_2_1, s_en_2_1, s_en_2_2,//write enable
w_n_full_1_1, w_n_full_2_1, e_n_full_2_2, e_n_full_1_2, s_n_full_2_1, s_n_full_2_2, n_n_full_1_1, n_n_full_1_2);

input n_en_1_1, n_en_1_2, e_en_1_2, e_en_2_2, w_en_1_1, w_en_2_1, s_en_2_1, s_en_2_2;
input clk, rt_clk, rt_reset, rst_n, start;
input[3:0] e_in_1_2, e_in_2_2, w_in_1_1, w_in_2_1, s_in_2_1, s_in_2_2, n_in_1_1, n_in_1_2;
output [3:0] north_out_1_1, north_out_1_2, south_out_2_1, south_out_2_2, east_out_1_2, east_out_2_2, west_out_1_1, west_out_2_1;
output south_full_2_1, south_full_2_2, north_full_1_1,north_full_1_2, east_full_1_2, east_full_2_2, west_full_1_1, west_full_2_1;
output north_w_1_1, north_w_1_2, south_w_2_1, south_w_2_2, east_w_1_2, east_w_2_2, west_w_1_1, west_w_2_1;
input w_n_full_1_1, w_n_full_2_1, e_n_full_2_2, e_n_full_1_2, s_n_full_2_1, s_n_full_2_2, n_n_full_1_1, n_n_full_1_2;

wire [7:0] data_wire_row1, data_wire_row2;
wire [7:0] data_wire_column1, data_wire_column2;
wire [1:0] full_row1, full_row2, full_column1, full_column2;
wire [1:0] write_row1, write_row2, write_column1, write_column2;


neuron_cell #(.X_ID("1"), .Y_ID("1"), .NUM_NURNS(8), .NUM_AXONS(8), .NURN_CNT_BIT_WIDTH(3), .AXON_CNT_BIT_WIDTH(3))
cell_1_1(.clk(clk), .rt_clk(rt_clk), .rst_n(rst_n), .rt_reset(rt_reset),
.clk_north(rt_clk), .clk_south(rt_clk), .clk_east(rt_clk), .clk_west(rt_clk),
.north_in(n_in_1_1), .south_in(data_wire_column1[3:0]), .east_in(data_wire_row1[3:0]), .west_in(w_in_1_1),
.north_neighbor_full(n_n_full_1_1), .south_neighbor_full(full_column1[0]), .east_neighbor_full(full_row1[1]), .west_neighbor_full(w_n_full_1_1),
.north_out(north_out_1_1), .south_out(data_wire_column1[7:4]), .east_out(data_wire_row1[7:4]), .west_out(west_out_1_1),
.north_full(north_full_1_1), .south_full(full_column1[1]), .east_full(full_row1[1]), .west_full(west_full_1_1),
.write_req_north(north_w_1_1), .write_req_south(write_column1[1]), .write_req_east(write_row1[1]), .write_req_west(west_w_1_1),
.write_en_north(n_en_1_1), .write_en_south(write_column1[0]), .write_en_east(write_row1[0]), .write_en_west(w_en_1_1), .start(start));

neuron_cell #(.X_ID("1"), .Y_ID("2"), .NUM_NURNS(2), .NUM_AXONS(2), .NURN_CNT_BIT_WIDTH(1), .AXON_CNT_BIT_WIDTH(1)) 
cell_1_2(.clk(clk), .rt_clk(rt_clk), .rst_n(rst_n), .rt_reset(rt_reset),
.clk_north(rt_clk), .clk_south(rt_clk), .clk_east(rt_clk), .clk_west(rt_clk),
.north_in(n_in_1_2), .south_in(data_wire_column2[3:0]), .east_in(e_in_1_2), .west_in(data_wire_row1[7:4]),
.north_neighbor_full(n_n_full_1_2), .south_neighbor_full(full_column2[0]), .east_neighbor_full(e_n_full_1_2), .west_neighbor_full(full_row1[1]),
.north_out(north_out_1_2), .south_out(data_wire_column2[7:4]), .east_out(east_out_1_2), .west_out(data_wire_row1[3:0]),
.north_full(north_full_1_2), .south_full(full_column2[1]), .east_full(east_full_1_2), .west_full(full_row1[1]),
.write_req_north(north_w_1_2), .write_req_south(write_column2[1]), .write_req_east(east_w_1_2), .write_req_west(write_row1[0]),
.write_en_north(n_en_1_2), .write_en_south(write_column2[0]), .write_en_east(e_en_1_2), .write_en_west(write_row1[1]), .start(start));

neuron_cell #(.X_ID("2"), .Y_ID("1"), .NUM_NURNS(2), .NUM_AXONS(2), .NURN_CNT_BIT_WIDTH(1), .AXON_CNT_BIT_WIDTH(1)) 
cell_2_1(.clk(clk), .rt_clk(rt_clk), .rst_n(rst_n), .rt_reset(rt_reset),
.clk_north(rt_clk), .clk_south(rt_clk), .clk_east(rt_clk), .clk_west(rt_clk),
.north_in(data_wire_column1[7:4]), .south_in(s_in_2_1), .east_in(data_wire_row2[3:0]), .west_in(w_in_2_1),
.north_neighbor_full(full_column1[1]), .south_neighbor_full(s_n_full_2_1), .east_neighbor_full(full_row2[1]), .west_neighbor_full(w_n_full_2_1),
.north_out(data_wire_column1[3:0]), .south_out(south_out_2_1), .east_out(data_wire_row2[7:4]), .west_out(west_out_2_1),
.north_full(full_column1[0]), .south_full(south_full_2_1), .east_full(full_row2[0]), .west_full(west_full_2_1),
.write_req_north(write_column1[0]), .write_req_south(south_w_2_1), .write_req_east(write_row2[1]), .write_req_west(west_w_2_1),
.write_en_north(write_column1[1]), .write_en_south(s_en_2_1), .write_en_east(write_row2[0]), .write_en_west(w_en_2_1), .start(start));

neuron_cell #(.X_ID("2"), .Y_ID("2"), .NUM_NURNS(2), .NUM_AXONS(2), .NURN_CNT_BIT_WIDTH(1), .AXON_CNT_BIT_WIDTH(1)) 
cell_2_2(.clk(clk), .rt_clk(rt_clk), .rst_n(rst_n), .rt_reset(rt_reset),
.clk_north(rt_clk), .clk_south(rt_clk), .clk_east(rt_clk), .clk_west(rt_clk),
.north_in(data_wire_column2[7:4]), .south_in(s_in_2_2), .east_in(e_in_2_2), .west_in(data_wire_row2[7:4]),
.north_neighbor_full(full_column2[1]), .south_neighbor_full(s_n_full_2_2), .east_neighbor_full(e_n_full_2_2), .west_neighbor_full(full_row2[0]),
.north_out(data_wire_column2[3:0]), .south_out(south_out_2_2), .east_out(east_out_2_2), .west_out(data_wire_row2[3:0]),
.north_full(full_column2[0]), .south_full(south_full_2_2), .east_full(east_full_2_2), .west_full(full_row2[1]),
.write_req_north(write_column2[0]), .write_req_south(sou_w_2_2), .write_req_east(east_w_2_2), .write_req_west(write_row2[0]),
.write_en_north(write_column2[1]), .write_en_south(s_en_2_2), .write_en_east(e_en_2_2), .write_en_west(write_row2[1]), .start(start));

endmodule