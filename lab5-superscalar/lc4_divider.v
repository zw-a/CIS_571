/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps
`default_nettype none

module lc4_divider(input  wire [15:0] i_dividend,
                   input  wire [15:0] i_divisor,
                   output wire [15:0] o_remainder,
                   output wire [15:0] o_quotient);

      wire [15:0] rem_0;
      wire [15:0] quo_0;
      wire [15:0] next_d1, next_d2, next_d3, next_d4, next_d5, next_d6, next_d7, next_d8, 
      next_d9, next_d10, next_d11, next_d12, next_d13, next_d14, next_d15, next_d16;
      wire [15:0] next_r1, next_r2, next_r3, next_r4, next_r5, next_r6, next_r7, next_r8, 
      next_r9, next_r10, next_r11, next_r12, next_r13, next_r14, next_r15, next_r16;
      wire [15:0] next_q1, next_q2, next_q3, next_q4, next_q5, next_q6, next_q7, next_q8, 
      next_q9, next_q10, next_q11, next_q12, next_q13, next_q14, next_q15, next_q16;
      wire [15:0] out_dividend, dividend_0, divisor_0;
      wire zero_divisor;
      assign dividend_0 = i_dividend;
      assign divisor_0 = i_divisor;
      assign rem_0 = 16'h000;
      assign quo_0 = 16'h000;
      assign zero_divisor = (i_divisor == 16'h0000);

      lc4_divider_one_iter d0(.i_dividend(dividend_0),
                                   .i_divisor(divisor_0),
                                   .i_remainder(rem_0),
                                   .i_quotient(quo_0),
                                   .o_dividend(next_d1),
                                   .o_remainder(next_r1),
                                   .o_quotient(next_q1));
      lc4_divider_one_iter d1(.i_dividend(next_d1),
                                   .i_divisor(i_divisor),
                                   .i_remainder(next_r1),
                                   .i_quotient(next_q1),
                                   .o_dividend(next_d2),
                                   .o_remainder(next_r2),
                                   .o_quotient(next_q2));
      lc4_divider_one_iter d2(.i_dividend(next_d2),
                                   .i_divisor(i_divisor),
                                   .i_remainder(next_r2),
                                   .i_quotient(next_q2),
                                   .o_dividend(next_d3),
                                   .o_remainder(next_r3),
                                   .o_quotient(next_q3));
      lc4_divider_one_iter d3(.i_dividend(next_d3),
                                   .i_divisor(i_divisor),
                                   .i_remainder(next_r3),
                                   .i_quotient(next_q3),
                                   .o_dividend(next_d4),
                                   .o_remainder(next_r4),
                                   .o_quotient(next_q4));
      lc4_divider_one_iter d4(.i_dividend(next_d4),
                                   .i_divisor(i_divisor),
                                   .i_remainder(next_r4),
                                   .i_quotient(next_q4),
                                   .o_dividend(next_d5),
                                   .o_remainder(next_r5),
                                   .o_quotient(next_q5));
      lc4_divider_one_iter d5(.i_dividend(next_d5),
                                   .i_divisor(i_divisor),
                                   .i_remainder(next_r5),
                                   .i_quotient(next_q5),
                                   .o_dividend(next_d6),
                                   .o_remainder(next_r6),
                                   .o_quotient(next_q6));
      lc4_divider_one_iter d6(.i_dividend(next_d6),
                                   .i_divisor(i_divisor),
                                   .i_remainder(next_r6),
                                   .i_quotient(next_q6),
                                   .o_dividend(next_d7),
                                   .o_remainder(next_r7),
                                   .o_quotient(next_q7));
      lc4_divider_one_iter d7(.i_dividend(next_d7),
                                   .i_divisor(i_divisor),
                                   .i_remainder(next_r7),
                                   .i_quotient(next_q7),
                                   .o_dividend(next_d8),
                                   .o_remainder(next_r8),
                                   .o_quotient(next_q8));
      lc4_divider_one_iter d8(.i_dividend(next_d8),
                                   .i_divisor(i_divisor),
                                   .i_remainder(next_r8),
                                   .i_quotient(next_q8),
                                   .o_dividend(next_d9),
                                   .o_remainder(next_r9),
                                   .o_quotient(next_q9));
      lc4_divider_one_iter d9(.i_dividend(next_d9),
                                   .i_divisor(i_divisor),
                                   .i_remainder(next_r9),
                                   .i_quotient(next_q9),
                                   .o_dividend(next_d10),
                                   .o_remainder(next_r10),
                                   .o_quotient(next_q10));
      lc4_divider_one_iter d10(.i_dividend(next_d10),
                                   .i_divisor(i_divisor),
                                   .i_remainder(next_r10),
                                   .i_quotient(next_q10),
                                   .o_dividend(next_d11),
                                   .o_remainder(next_r11),
                                   .o_quotient(next_q11));
      lc4_divider_one_iter d11(.i_dividend(next_d11),
                                   .i_divisor(i_divisor),
                                   .i_remainder(next_r11),
                                   .i_quotient(next_q11),
                                   .o_dividend(next_d12),
                                   .o_remainder(next_r12),
                                   .o_quotient(next_q12));
      lc4_divider_one_iter d12(.i_dividend(next_d12),
                                   .i_divisor(i_divisor),
                                   .i_remainder(next_r12),
                                   .i_quotient(next_q12),
                                   .o_dividend(next_d13),
                                   .o_remainder(next_r13),
                                   .o_quotient(next_q13));
      lc4_divider_one_iter d13(.i_dividend(next_d13),
                                   .i_divisor(i_divisor),
                                   .i_remainder(next_r13),
                                   .i_quotient(next_q13),
                                   .o_dividend(next_d14),
                                   .o_remainder(next_r14),
                                   .o_quotient(next_q14));
      lc4_divider_one_iter d14(.i_dividend(next_d14),
                                   .i_divisor(i_divisor),
                                   .i_remainder(next_r14),
                                   .i_quotient(next_q14),
                                   .o_dividend(next_d15),
                                   .o_remainder(next_r15),
                                   .o_quotient(next_q15));
      lc4_divider_one_iter d15(.i_dividend(next_d15),
                                   .i_divisor(i_divisor),
                                   .i_remainder(next_r15),
                                   .i_quotient(next_q15),
                                   .o_dividend(next_d16),
                                   .o_remainder(next_r16),
                                   .o_quotient(next_q16));
      assign o_remainder = zero_divisor ? 16'h0 : next_r16;
      assign o_quotient = zero_divisor ? 16'h0 : next_q16;


endmodule // lc4_divider

module lc4_divider_one_iter(input  wire [15:0] i_dividend,
                            input  wire [15:0] i_divisor,
                            input  wire [15:0] i_remainder,
                            input  wire [15:0] i_quotient,
                            output wire [15:0] o_dividend,
                            output wire [15:0] o_remainder,
                            output wire [15:0] o_quotient);

      wire [15:0] c;
      wire [15:0] or_out;
      wire comp_out;
      wire [15:0] mux_out;
      wire [15:0] mux_out2;
      wire [15:0] rem_shift;
      wire [15:0] div_shift;
      wire [15:0] quo_shift;

      assign rem_shift = i_remainder << 1;
      assign div_shift = i_dividend >> 15;
      assign quo_shift = i_quotient << 1;
      assign c = div_shift & 16'h0001;
      assign or_out = rem_shift | c;
      assign comp_out = or_out >= i_divisor;
      assign mux_out = comp_out ? i_divisor : 16'h0;
      assign o_remainder = or_out - mux_out;
      assign mux_out2 = comp_out ? 16'h0001 : 16'h0;
      assign o_quotient = quo_shift | mux_out2;
      assign o_dividend = i_dividend << 1;
endmodule
