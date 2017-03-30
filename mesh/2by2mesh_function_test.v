`timescale 1ns/100ps
`define tpd_clk 10

//`define tb1
`define tb2

module functionTB();

reg clk, rt_clk, rst_n, rt_reset, start;
reg [3:0] in_packet;
reg inRT_write_en;

wire [3:0] north_out_1_2, south_out_2_1, south_out_2_2, east_out_1_2, east_out_2_2, west_out_1_1,
west_out_2_1;
wire south_full_2_1, south_full_2_2, north_full_1_1,north_full_1_2,
east_full_1_2, east_full_2_2, west_full_1_1, west_full_2_1;
wire north_w_1_1, north_w_1_2, south_w_2_1, south_w_2_2, east_w_1_2, east_w_2_2, west_w_1_1, west_w_2_1; //request

wire [3:0] e_in_1_2;

wire inRT_w_req, outRT_full;
wire [3:0] out_packet;

mesh_ap uut (.clk(clk), .rt_clk(rt_clk), .rst_n(rst_n), .rt_reset(rt_reset), .north_out_1_1(north_out_1_1),
.north_out_1_2(north_full_1_2), .south_out_2_1(south_full_2_1), .south_out_2_2(south_full_2_2), .east_out_1_2(east_out_1_2), .east_out_2_2(east_out_2_2), .west_out_1_1(west_out_1_1),
.west_out_2_1(west_out_2_1), .south_full_2_1(south_full_2_1), .south_full_2_2(south_full_2_2), .north_full_1_1(north_full_1_1), .north_full_1_2(north_full_1_2),
.east_full_1_2(east_full_1_2), .east_full_2_2(east_full_2_2), .west_full_1_1(west_full_1_1), .west_full_2_1(west_full_2_1),
.north_w_1_1(north_w_1_1), .north_w_1_2(north_w_1_2), .south_w_2_1(south_w_2_1), .south_w_2_2(south_w_2_2),
.east_w_1_2(east_w_1_2), .east_w_2_2(east_w_2_2), .west_w_1_1(west_w_1_1), .west_w_2_1(west_w_2_1), .start(start),
.e_in_1_2(e_in_1_2), .e_in_2_2(1'b0), .w_in_1_1(1'b0), .w_in_2_1(1'b0), .s_in_2_1(0), .s_in_2_2(0), .n_in_1_1(0), .n_in_1_2(0),//input data
.n_en_1_1(1'b0), .n_en_1_2(1'b0), .e_en_1_2(inRT_w_req), .e_en_2_2(1'b0), .w_en_1_1(1'b0), .w_en_2_1(1'b0), .s_en_2_1(1'b0), .s_en_2_2(1'b0),//write enable
.w_n_full_1_1(outRT_full), .w_n_full_2_1(1'b0), .e_n_full_2_2(1'b0), .e_n_full_1_2(1'b0), .s_n_full_2_1(1'b0), .s_n_full_2_2(1'b0), .n_n_full_1_1(1'b0), .n_n_full_1_2(1'b0));

router inRT(.clk(rt_clk), .clk_local(1'b0), .clk_north(rt_clk), .clk_south(rt_clk), .clk_east(rt_clk), .clk_west(rt_clk),
.reset(rt_reset), .local_in(32'b0), .north_in(4'b0), .south_in(4'b0), .east_in(in_packet), .west_in(4'b0),
.local_out(), .north_out(), .south_out(), .east_out(), .west_out(e_in_1_2),
.local_full(), .north_full(), .south_full(), .east_full(), .west_full(),
.local_neuron_full(1'b0), .north_neighbor_full(1'b0), .south_neighbor_full(1'b0), .east_neighbor_full(east_full_1_2), .west_neighbor_full(1'b0),
.write_en_local(1'b0), .write_en_north(1'b0), .write_en_south(1'b0), .write_en_east(inRT_write_en), .write_en_west(1'b0),
.write_req_local(), .write_req_north(), .write_req_south(), .write_req_east(), .write_req_west(inRT_w_req));

router outRT(.clk(rt_clk), .clk_local(1'b0), .clk_north(rt_clk), .clk_south(rt_clk), .clk_east(rt_clk), .clk_west(rt_clk),
.reset(rt_reset), .local_in(32'b0), .north_in(4'b0), .south_in(4'b0), .east_in(west_out_1_1), .west_in(4'b0),
.local_out(), .north_out(), .south_out(), .east_out(), .west_out(out_packet),
.local_full(), .north_full(), .south_full(), .east_full(outRT_full), .west_full(),
.local_neuron_full(1'b0), .north_neighbor_full(1'b0), .south_neighbor_full(1'b0), .east_neighbor_full(east_full_1_2), .west_neighbor_full(1'b0),
.write_en_local(1'b0), .write_en_north(1'b0), .write_en_south(1'b0), .write_en_east(west_w_1_1), .write_en_west(1'b0),
.write_req_local(), .write_req_north(), .write_req_south(), .write_req_east(), .write_req_west());

//router clock
	always
		begin
			#5 rt_clk <= ~rt_clk  ;
		end
`ifdef tb1
    initial
		begin
			rt_clk = 1'b0;
			rt_reset = 1'b1;
			in_packet = 4'h0;
            #6 rt_reset = 0;
            
            //packet 1 0000ffff
            #10 inRT_write_en = 1;  
				in_packet = 4'hf; #10 in_packet = 4'hf; #10 in_packet = 4'hf; #10 in_packet = 4'hf;
            #10 in_packet = 4'h0; #10 in_packet = 4'h0; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
            //packet 2 0001ffff
            #10 in_packet = 4'hf; #10 in_packet = 4'hf; #10 in_packet = 4'hf; #10 in_packet = 4'hf;
            #10 in_packet = 4'h1; #10 in_packet = 4'h0; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
			#10	inRT_write_en = 0;
            //packet 3 000000fe
            #80 inRT_write_en = 1;
				in_packet = 4'he; #10 in_packet = 4'hf; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
            #10 in_packet = 4'h0; #10 in_packet = 4'h0; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
            //packet 4 000100fe
            #10 in_packet = 4'he; #10 in_packet = 4'hf; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
            #10 in_packet = 4'h1; #10 in_packet = 4'h0; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
			#10	inRT_write_en = 0;
            //packet 5 0000fffe
            #80 inRT_write_en = 1;
				in_packet = 4'he; #10 in_packet = 4'hf; #10 in_packet = 4'hf; #10 in_packet = 4'hf;
            #10 in_packet = 4'h0; #10 in_packet = 4'h0; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
            //packet 6 0001fffe
            #10 in_packet = 4'he; #10 in_packet = 4'hf; #10 in_packet = 4'hf; #10 in_packet = 4'hf;
            #10 in_packet = 4'h1; #10 in_packet = 4'h0; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
            #10 inRT_write_en = 0;
	end
`endif

`ifdef tb2
	initial
		begin
			rt_clk = 1'b0;
			rt_reset = 1'b1;
			in_packet = 4'h0;
            #6 rt_reset = 0;
            
            //packet 1 0002fe00
            #10 inRT_write_en = 1;  
				in_packet = 4'he; #10 in_packet = 4'hf; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
            #10 in_packet = 4'h2; #10 in_packet = 4'h0; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
            //packet 2 0003fe00
            #10 in_packet = 4'he; #10 in_packet = 4'hf; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
            #10 in_packet = 4'h3; #10 in_packet = 4'h0; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
			#10	inRT_write_en = 0;
            //packet 3 0004fe00
            #80 inRT_write_en = 1;
				in_packet = 4'he; #10 in_packet = 4'hf; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
            #10 in_packet = 4'h4; #10 in_packet = 4'h0; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
            //packet 4 0005fe00
            #10 in_packet = 4'he; #10 in_packet = 4'hf; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
            #10 in_packet = 4'h5; #10 in_packet = 4'h0; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
			#10	inRT_write_en = 0;
			
			//000000fe
			#1500 inRT_write_en = 1;
				in_packet = 4'he; #10 in_packet = 4'hf; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
            #10 in_packet = 4'h0; #10 in_packet = 4'h0; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
			//000100fe
			#10 in_packet = 4'he; #10 in_packet = 4'hf; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
            #10 in_packet = 4'h1; #10 in_packet = 4'h0; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
			#10	inRT_write_en = 0;

			//000300fe
            #80 inRT_write_en = 1;
				in_packet = 4'he; #10 in_packet = 4'hf; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
            #10 in_packet = 4'h3; #10 in_packet = 4'h0; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
            //packet 4 000e00fe
            #10 in_packet = 4'he; #10 in_packet = 4'hf; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
            #10 in_packet = 4'h4; #10 in_packet = 4'h0; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
			#10	inRT_write_en = 0;

			//000600fe
			#80 inRT_write_en = 1;
				in_packet = 4'he; #10 in_packet = 4'hf; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
            #10 in_packet = 4'h6; #10 in_packet = 4'h0; #10 in_packet = 4'h0; #10 in_packet = 4'h0;
			#10	inRT_write_en = 0;

		end
`endif

//

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

		#2000 rst_n = 1'b1;
		#((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;
		
		#((`tpd_clk*2)*30);

		#3000 rst_n = 1'b1;
		#((`tpd_clk*2)*2);
		@(posedge clk); start = 1'b1; @(posedge clk); start = 1'b0;

		#((`tpd_clk*2)*30);

		$stop;
	end

endmodule