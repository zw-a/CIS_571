/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps
`default_nettype none

module lc4_divider(input  wire [15:0] i_dividend,
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

module lc4_divider_one_iter(input wire [15:0] i_dividend,
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
