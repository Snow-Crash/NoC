module Adder_Subtractor (A_din_i, B_din_i, twos_cmplmnt_i, clipped_sum_o, sum_o,carry_o, overflow_o, underflow_o, subtraction_i);

parameter DSIZE = 16;
input [DSIZE-1:0] A_din_i;
input [DSIZE-1:0] B_din_i;
input twos_cmplmnt_i;
input subtraction_i;
	
output reg [DSIZE-1:0] clipped_sum_o;
output carry_o;
output overflow_o;
output underflow_o;
output [DSIZE-1:0] sum_o;

reg extended_bit;
reg [DSIZE-1:0] sum;
reg overflow, underflow;
wire [DSIZE-2:0] overflow_mag, underflow_mag;

assign overflow_mag = -1;//this will result in ...1111
assign underflow_mag = 0;//this will result in ...0000

always@(*)
    begin
        if (subtraction_i == 1'b1)
            {extended_bit, sum} = A_din_i + ~B_din_i + 1'b1;
        else
            {extended_bit, sum} = A_din_i + B_din_i;
    end

assign carry_o = extended_bit;

always@(*)
    begin
        if (twos_cmplmnt_i == 1'b1)
            begin
                overflow = ({extended_bit,sum[DSIZE-1]} == 2'b01);
                underflow = ({extended_bit,sum[DSIZE-1]} == 2'b10);
            end
        else
            begin
                overflow = extended_bit;
                underflow = 1'b0;
            end
    end

always @(*)
    begin
        clipped_sum_o = sum;
        if(twos_cmplmnt_i == 1'b1)
            begin
                if (overflow == 1'b1)
                    clipped_sum_o = {1'b0, overflow_mag};

                if (underflow == 1'b1)
                    clipped_sum_o = {1'b1, underflow_mag};
            end
        else
            begin
                if (overflow == 1'b1)
                    clipped_sum_o = {1'b1, overflow_mag};
                
                if (underflow == 1'b1)
                    clipped_sum_o = {1'b0, underflow};
            end
    end

assign sum_o = sum;
assign overflow_o = overflow;
assign underflow_o = underflow;

endmodule