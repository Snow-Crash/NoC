//-------------------------------------------------------------------------
//
//FILE NAME     : nm_ram.v
//AUTHOR        : Juncheng Shen
//FUNCTION      : RAM behavioral model for NM.
//INITIAL DATE  : 2017/05/19
//VERSION       : 1.0
//RELEASE NOTE  : 1.0: initial version.
//
//-------------------------------------------------------------------------

module  nm_ram(
    clk,
    ce,
    we,
    addr,
    din,
    dout
    );

parameter WIDTH = 8;
parameter DEPTH = 10;

input   clk;
input   ce;
input   we;
input   [DEPTH-1:0] addr;
input   [WIDTH-1:0] din;
output  [WIDTH-1:0] dout;

reg [WIDTH-1:0] ram[2**DEPTH-1:0];
reg [WIDTH-1:0] dout;

always  @(posedge clk)
begin
    if(ce)  begin
        if(we)  begin
            ram[addr]   <= din;
            dout        <= din;
            end
        else
            dout        <= ram[addr];
        end
end

endmodule
