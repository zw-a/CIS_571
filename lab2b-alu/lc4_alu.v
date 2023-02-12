/* INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ps
`default_nettype none

module lc4_div(input  wire [15:0] i_dividend,
                   input  wire [15:0] i_divisor,
                   output wire [15:0] o_remainder,
                   output wire [15:0] o_quotient);
          genvar i;

          wire [15:0]temp_dvd [16:0];assign temp_dvd[0] = i_dividend;
          wire [15:0]temp_rmd [16:0];assign temp_rmd[0] = 16'b0; 
          wire [15:0]temp_qot [16:0];assign temp_qot[0] = 16'b0;
          
          for(i=0;i<16;i=i+1)
          begin
              lc4_divider_one_iter one(.i_divisor(i_divisor), .i_dividend(temp_dvd[i]),.i_remainder(temp_rmd[i]),.i_quotient(temp_qot[i]),.o_dividend(temp_dvd[i+1]),.o_remainder(temp_rmd[i+1]),.o_quotient(temp_qot[i+1]));
          end
          assign o_remainder = (i_divisor == 0)?16'b0:temp_rmd[16];
          assign o_quotient = (i_divisor == 0)?16'b0:temp_qot[16];
endmodule

module lc4_div_one_iter(input wire [15:0] i_dividend,
                            input wire [15:0] i_divisor,
                            input wire [15:0] i_remainder,
                            input wire [15:0] i_quotient,
                            output wire [15:0] o_dividend,
                            output wire [15:0] o_remainder,
                            output wire [15:0] o_quotient);

              wire [15:0] temp_r;assign temp_r = (i_remainder<<1)|((i_dividend>>15)&16'b1);         
              wire [15:0] mid_v; assign mid_v = temp_r < i_divisor;
              
              assign o_quotient = mid_v[0]?(i_quotient<<1):((i_quotient<<1)|16'b1);
              assign o_remainder = mid_v[0]?temp_r:(temp_r - i_divisor);
              assign o_dividend = i_dividend <<1;
endmodule


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
      4'b0001: if (type == 3'b000)
      default: result = 16'h0000;
    endcase
  end           
  assign o_result = result;
endmodule



