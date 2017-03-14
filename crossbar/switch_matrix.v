//`include "mux5to1.v"

module switch_matrix (input0, input1, input2, input3, input4, output0, output1, output2, output3, output4,
sel0, sel1, sel2, sel3, sel4);

parameter flit_size = 4;


input [flit_size - 1:0] input0, input1, input2, input3, input4;
input [2:0] sel0, sel1, sel2, sel3, sel4;
output [flit_size - 1:0] output0, output1, output2, output3, output4;

//input0 local
//input1 north
//input2 south
//input3 east
//input4 west

//mux0
mux5to1 local(.input0(input0), .input1(input1), .input2(input2),
 .input3(input3), .input4(input4), .data_out(output0), .sel(sel0));

//mux1
mux5to1 north(.input0(input0), .input1(input1), .input2(input2),
 .input3(input3), .input4(input4), .data_out(output1), .sel(sel1));

//mux2
mux5to1 south(.input0(input0), .input1(input1), .input2(input2),
 .input3(input3), .input4(input4), .data_out(output2), .sel(sel2));

//mux3
mux5to1 east(.input0(input0), .input1(input1), .input2(input2),
 .input3(input3), .input4(input4), .data_out(output3), .sel(sel3));

//mux4
mux5to1 west(.input0(input0), .input1(input1), .input2(input2),
 .input3(input3), .input4(input4), .data_out(output4), .sel(sel4));

 endmodule