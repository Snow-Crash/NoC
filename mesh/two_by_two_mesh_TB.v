`timescale 1ns/100ps
`define tpd_clk 5

module two_by_two_mesh_TB();

reg clk, rt_clk, rst_n, rt_reset, start;

wire [3:0] north_out_1_2, south_out_2_1, south_out_2_2, east_out_1_2, east_out_2_2, west_out_1_1,
west_out_2_1;
wire south_full_2_1, south_full_2_2, north_full_1_1,north_full_1_2,
east_full_1_2, east_full_2_2, west_full_1_1, west_full_2_1,
north_w_1_1, north_w_1_2, south_w_2_1, sou_w_2_2,
east_w_1_2, east_w_2_2, west_w_1_1, west_w_2_1;

two_by_two_mesh uut (.clk(clk), .rt_clk(rt_clk), .rst_n(rst_n), .rt_reset(rt_reset), .north_out_1_1(north_out_1_1),
.north_out_1_2(north_full_1_2), .south_out_2_1(south_full_2_1), .south_out_2_2(south_full_2_2), .east_out_1_2(east_out_1_2), .east_out_2_2(east_out_2_2), .west_out_1_1(west_out_1_1),
.west_out_2_1(west_out_2_1), .south_full_2_1(south_full_2_1), .south_full_2_2(south_full_2_2), .north_full_1_1(north_full_1_1), .north_full_1_2(north_full_1_2),
.east_full_1_2(east_full_1_2), .east_full_2_2(east_full_2_2), .west_full_1_1(west_full_1_1), .west_full_2_1(west_full_2_1),
.north_w_1_1(north_w_1_1), .north_w_1_2(north_w_1_2), .south_w_2_1(south_w_2_1), .south_w_2_2(south_w_2_2),
.east_w_1_2(east_w_1_2), .east_w_2_2(east_w_2_2), .west_w_1_1(west_w_1_1), .west_w_2_1(west_w_2_1), .start(start));

//router clock
	always
		begin
			#5 rt_clk <= ~rt_clk  ;
		end

    initial
		begin
			rt_clk = 1'b0;
			rt_reset = 1'b1;
	        //clk_north = 0; clk_south = 0; clk_east = 0; clk_west = 0;
            //write_east = 0; write_west = 0; write_south = 0; write_north = 0;
            //north_in = 0; south_in = 0; east_in = 0; west_in = 0; 
	        #10 rt_reset = 1'b0;

	end

	always
	begin
		#(`tpd_clk) clk <= ~clk  ;
	end

	initial
	begin
		clk  = 1'b0;
		rst_n = 1'b0;
		start = 1'b0;	


		
		#(`tpd_clk*2);
		rst_n = 1'b1;


		#((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
		
		#((`tpd_clk*2)*30);


		#((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;

		#((`tpd_clk*2)*30);

		$stop;
	end

endmodule