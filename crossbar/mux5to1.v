module mux5to1(input0, input1, input2, input3, input4, data_out, sel);

parameter flit_size = 4;

localparam select_local = 3'd0;
localparam select_north = 3'd1;
localparam select_south = 3'd2;
localparam select_east = 3'd3;
localparam select_west = 3'd4;

input [flit_size - 1:0] input0, input1, input2, input3, input4;
input [2:0] sel;
output reg [flit_size - 1:0] data_out;

always @(*) 
    begin
        case (sel)
            3'd0: data_out = input0;
            3'd1: data_out = input1;
            3'd2: data_out = input2;
            3'd3: data_out = input3;
            3'd4: data_out = input4;
            default: data_out = 4'bzzzz;
        endcase
  
    end
endmodule