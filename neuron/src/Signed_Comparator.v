module Signed_Comparator (A_din_i, B_din_i, equal, lower, greater);

parameter DSIZE = 16;
input [DSIZE-1:0] A_din_i;
input [DSIZE-1:0] B_din_i;

output reg equal, lower, greater;

reg extended_bit;
reg [DSIZE-1:0] result;
reg underflow, overflow;

wire [DSIZE-1:0] negative_B;

assign  negative_B = ~B_din_i + 1;

always @(*)
    begin
        {extended_bit, result} = {A_din_i[DSIZE-1],A_din_i} + {negative_B[DSIZE-1],negative_B};
        underflow = ({extended_bit, result[DSIZE-1]} == 2'b10);
        overflow = ({extended_bit, result[DSIZE-1]} == 2'b10);
    end

always @(*)
    begin
        equal = 1'b0;
        greater = 1'b0;
        lower = 1'b0;
        if (result == 0)
            equal = 1'b1;
        else if (overflow == 1'b1)
            lower = 1'b1;
        else if (underflow == 1'b1)
            greater = 1'b1;
        else if (result[DSIZE-1] == 1'b1)
            lower = 1'b1;
        else if (result[DSIZE-1] == 1'b0)
            greater = 1'b1;
    end





endmodule