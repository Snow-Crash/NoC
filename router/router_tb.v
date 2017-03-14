`timescale 1ns/100ps

`include "router.v"


module router_tb();

reg clk, clk_local, clk_north, clk_south, clk_east, clk_west;
reg reset, reset_north, reset_south, reset_east, reset_west, reset_local;
reg write_local, write_north, write_south, write_east, write_west;
reg [3:0] local_in, north_in, south_in, east_in, west_in;
wire [3:0] local_out, north_out, south_out, east_out, west_out;
wire local_full, north_full, south_full, east_full, west_full;
wire write_req_local,write_req_north, write_req_south, write_req_east, write_req_west;

routerv2 uut (.clk(clk), .clk_local(clk_local), .clk_north(clk_north), .clk_south(clk_south), .clk_east(clk_east), .clk_west(clk_west),
.reset(reset), .local_in(local_in), .north_in(north_in), .south_in(south_in), .east_in(east_in), .west_in(west_in), 
.local_out(local_out), .north_out(north_out), .south_out(south_out), .east_out(east_out), .west_out(west_out),
.local_full(local_full), .north_full(north_full), .south_full(south_full), .east_full(east_full), .west_full(west_full),
.reset_local(reset_local), .reset_north(reset_north), .reset_south(reset_south), .reset_east(reset_east), .reset_west(reset_west), .write_local(write_local), .write_north(write_north),
.write_south(write_south), .write_east(write_east), .write_west(write_west),
.write_req_local(write_req_local), .write_req_north(write_req_north), .write_req_south(write_req_south), 
.write_req_east(write_req_east), .write_req_west(write_req_west));

always
    begin
        #10 clk = ~clk;
    end

always
        #20 clk_local = ~clk_local;

always
    #10 clk_west = ~clk_west;

initial
    begin
    clk = 0;
    clk_local = 0; clk_north = 0; clk_south = 0; clk_east = 0; clk_west = 0;
    reset = 1; reset_local = 1; reset_east = 1; reset_north = 1; reset_south = 1; reset_west = 1;
    write_east = 0; write_west = 0; write_local = 0; write_south = 0; write_north = 0;
    local_in = 0; north_in = 0; south_in = 0; east_in = 0; west_in = 0; 
    #11 reset_local = 0;
    #20
    write_local = 1;
    local_in = 4'h5;
    #40 local_in = 4'h6;
    #40 local_in = 4'hb;
    #40 local_in = 4'hc;
    #40 local_in = 4'he;
    #40 local_in = 4'hf;
    #40 local_in = 4'he;
    #40 local_in = 4'hf;
    end

initial
    begin
        #10 reset = 0;
            reset_west = 0;
        #1  write_west = 1;
            west_in = 4'h3;
        #20 west_in = 4'h4;
        #20 west_in = 4'h7;
        #20 west_in = 4'h8;
        #20 west_in = 4'hc;
        #20 west_in = 4'hd;
        #20 west_in = 4'he;
        #20 west_in = 4'hf;
        #20 write_west = 0;
        #200 write_west = 1;
    end


endmodule