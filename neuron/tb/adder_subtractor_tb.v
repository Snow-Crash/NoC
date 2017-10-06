// Code your testbench here
// or browse Examples

`timescale 1ns/100ps
module test();

  parameter dsize = 8;
  reg [dsize-1:0] A, B;
  reg two_complement;
  reg subtraction;
  
  wire uf, of, c;
  
  wire [dsize-1:0] sum, clip_sum;
  
  
  Adder_Subtractor #(.DSIZE(dsize)) dut (.A_din_i(A), .B_din_i(B), .twos_cmplmnt_i(two_complement), .clipped_sum_o(clip_sum), .sum_o(sum), .carry_o(c), .overflow_o(of), .underflow_o(uf), .subtraction_i(subtraction));
  
  initial
    begin
      // test 3 + 5
      A = 3;
      B = 5;
      subtraction = 0;
      two_complement = 0;

      #20 A = 255;
      B = 3;
      subtraction = 0;
      two_complement = 0;

      #20 A = 1;
      B = 2;
      subtraction = 0;

      #20 A = 5;
      B = 6;
      subtraction = 1;

      #20
      A = -125;
      B = -10;
      two_complement = 1'b1;

      #20 A = 125;
      B = 5;
      two_complement = 1'b1;

      #20 A = 5;
      B = 6;
      subtraction = 0;

      #20
      A = -125;
      B = -10;
      two_complement = 1'b1;

      #20 A = 125;
      B = 5;
      two_complement = 1'b1;


    

      
      // test 
      
      $dumpfile("dump.vcd"); $dumpvars;
    end
  
  
endmodule

