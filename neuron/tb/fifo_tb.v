`timescale 1ns/100ps
//`define dctest
`define sctest

module fifotb();

reg [7:0] di;
wire [7:0] dout;
reg rd_clk, wr_clk, we, re, clr, rst, clk;
wire full, empty;
wire [1:0] wr_level, rd_level;

`ifdef dctest
generic_fifo_dc_gray
#(
    .dw(16),
    .aw(8)
)
uut
(
    .rd_clk(rd_clk), 
    .wr_clk(wr_clk), 
    .rst(rst), 
    .clr(clr), 
    .din(di), 
    .we(we),
    .dout(dout), 
    .re(re), 
    .full(full), 
    .empty(empty), 
    .wr_level(), 
    .rd_level()
);


initial
    begin
        rd_clk <= 1'b1;
        wr_clk <= 1'b0;
        rst <= 1'b0;
        #10 rst <= 1'b1;
        re <= 1'b0;
        we <= 1'b0;
        #10 di <= 16'hAAAA;
        we <= 1'b1;
        #10 di <= 16'hBBBB;
        #10 di <= 15'h1111;
        #10 di <= 15'h2222;

    end

always
	begin
		#10 rd_clk <= ~rd_clk  ;
        #5 wr_clk <= ~wr_clk;
	end

`endif

`ifdef sctest

generic_fifo_sc_b
#
(
    .dw(8),
    .aw(4)
)
uutfifo
(
    .clk(clk), 
    .rst(rst), 
    .clr(clr), 
    .din(di),
    .we(we), 
    .dout(dout), 
    .re(re),
	.full(), 
    .empty(), 
    .full_r(full), 
    .empty_r(empty),
	.full_n(), 
    .empty_n(), 
    .full_n_r(), 
    .empty_n_r(),
	.level()
            );

always
    #5 clk <= ~clk;

initial
    begin
        clk <= 1'b0;
        rst <= 1'b0;
        re <= 1'b0;
        we <= 1'b0;
    #10 rst <= 1'b1;
    #10 clr <= 1'b1;
    #10 clr <= 1'b0;
    #10 we <= 1'b1;
        di <= 8'hAA;
    #10 di <= 8'hBB;
    #10 di <= 8'hcc;
    #10 di <= 8'hdd;
    #10 re <= 1'b0;
        re <= 1'b1;
    #50 re <= 1'b0;

    end

`endif

endmodule