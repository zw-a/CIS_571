/* INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ps
`default_nettype none
 
module lc4_alu(input  wire [15:0] i_insn,
               input wire [15:0]  i_pc,
               input wire [15:0]  i_r1data,
               input wire [15:0]  i_r2data,
               output wire [15:0] o_result);
  
  reg  [15:0] result;
  wire [3:0] opcode;
  wire [2:0] type;
  assign opcode = i_insn[15:12];
  assign type = i_insn[5:3];
  reg [15:0] remainder;
  reg [15:0] quotient;
  reg [15:0] rst;
  reg [15:0] temp_divisor;
  reg [15:0] bit;

  integer i;
  reg [15:0] sum;
  reg [15:0] carry;
  reg [15:0] diff;
   
  always @* begin
    case (opcode)
      4'b0101: if (type == 3'b000)
        result = i_r1data & i_r2data;
      4'b0101: if (type == 3'b001)
        result = ~i_r1data;
      4'b0101: if (type == 3'b010)
        result = i_r1data | i_r2data;
      4'b0101: if (type == 3'b011)
        result = i_r1data ^ i_r2data;
      4'b0001: if (type == 3'b001)
        result = i_r1data * i_r2data;
      4'b0001: if (type == 3'b011)
        result = 0;
      4'b0001: if (type == 3'b000)
        result = 0;
      default: result = 16'h0000;
    endcase
  end           
  assign o_result = result;
endmodule
