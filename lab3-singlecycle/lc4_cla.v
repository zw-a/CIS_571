/* Askhat Bigeldiyev
 * PennID: 66203578 */

`timescale 1ns / 1ps
`default_nettype none

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
   assign g = a & b;
   assign p = a | b;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals 
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits collectively generate a carry (ignoring cin)
 * @param pout whether these 4 bits collectively would propagate an incoming carry (ignoring cin)
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);
   wire p_30;
   wire p_10;
   wire g_10;
   wire p_32;
   wire g_32;

  assign cout[0] = (cin & pin[0]) | gin[0]; //c1 = cin & p0 | g0
  assign p_10 = pin[0] & pin[1]; //p1-0 = p0 & p1
  assign g_10 = (gin[0] & pin[1]) | gin[1]; //g1-0 = g0 & p1 | g1
  assign p_32 = pin[2] & pin[3]; // p3-2 = p2 & p3
  assign g_32 = (gin[2] & pin[3]) | gin[3]; // g3-2 = g2 & p3 | g3
  assign cout[1] = (p_10 & cin) | g_10; //c2 = p1-0 & cin | g1-0
  assign pout = p_10 & p_32;
  assign gout = (g_10 & p_32) | g_32; // g3-0 = g1-0 & p3-2 | g3-2
  assign cout[2] = (pin[2] & cout[1]) | gin[2]; //c3 = p2 & c2 | g2
endmodule

/**
 * 16-bit Carry-Lookahead Adder
 * @param a first input
 * @param b second input
 * @param cin carry in
 * @param sum sum of a + b + carry-in
 */
module cla16
  (input wire [15:0]  a, b,
   input wire         cin,
   output wire [15:0] sum);

  wire [3:0] g1, p1;
  wire [2:0] cout_123, cout_567, cout_91011, cout_131415;
  wire [2:0] c_4812;
  wire g_150, p_150;
  wire [15:0] g0;
  wire [15:0] p0;
  wire c16;
  wire s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15;
  gp1 gp0(.a(a[0]), .b(b[0]), .g(g0[0]), .p(p0[0]));
  gp1 gp1(.a(a[1]), .b(b[1]), .g(g0[1]), .p(p0[1]));
  gp1 gp2(.a(a[2]), .b(b[2]), .g(g0[2]), .p(p0[2]));
  gp1 gp3(.a(a[3]), .b(b[3]), .g(g0[3]), .p(p0[3]));
  gp1 gp4(.a(a[4]), .b(b[4]), .g(g0[4]), .p(p0[4]));
  gp1 gp5(.a(a[5]), .b(b[5]), .g(g0[5]), .p(p0[5]));
  gp1 gp6(.a(a[6]), .b(b[6]), .g(g0[6]), .p(p0[6]));
  gp1 gp7(.a(a[7]), .b(b[7]), .g(g0[7]), .p(p0[7]));
  gp1 gp8(.a(a[8]), .b(b[8]), .g(g0[8]), .p(p0[8]));
  gp1 gp9(.a(a[9]), .b(b[9]), .g(g0[9]), .p(p0[9]));
  gp1 gp10(.a(a[10]), .b(b[10]), .g(g0[10]), .p(p0[10]));
  gp1 gp11(.a(a[11]), .b(b[11]), .g(g0[11]), .p(p0[11]));
  gp1 gp12(.a(a[12]), .b(b[12]), .g(g0[12]), .p(p0[12]));
  gp1 gp13(.a(a[13]), .b(b[13]), .g(g0[13]), .p(p0[13]));
  gp1 gp14(.a(a[14]), .b(b[14]), .g(g0[14]), .p(p0[14]));
  gp1 gp15(.a(a[15]), .b(b[15]), .g(g0[15]), .p(p0[15]));
  

  gp4 gp40(.gin(g0[3:0]), .pin(p0[3:0]), .cin(cin), .gout(g1[0]), .pout(p1[0]), .cout(cout_123));
  gp4 gp41(.gin(g0[7:4]), .pin(p0[7:4]), .cin(c_4812[0]), .gout(g1[1]), .pout(p1[1]), .cout(cout_567));
  gp4 gp42(.gin(g0[11:8]), .pin(p0[11:8]), .cin(c_4812[1]), .gout(g1[2]), .pout(p1[2]), .cout(cout_91011));
  gp4 gp43(.gin(g0[15:12]), .pin(p0[15:12]), .cin(c_4812[2]), .gout(g1[3]), .pout(p1[3]), .cout(cout_131415));
  gp4 gp44(.gin(g1), .pin(p1), .cin(cin), .gout(g_150), .pout(p_150), .cout(c_4812));

  assign s0 = a[0]^b[0]^cin;
  assign s1 = a[1]^b[1]^cout_123[0];
  assign s2 = a[2]^b[2]^cout_123[1];
  assign s3 = a[3]^b[3]^cout_123[2];
  assign s4 = a[4]^b[4]^c_4812[0];
  assign s5 = a[5]^b[5]^cout_567[0];
  assign s6 = a[6]^b[6]^cout_567[1];
  assign s7 = a[7]^b[7]^cout_567[2];
  assign s8 = a[8]^b[8]^c_4812[1];
  assign s9 = a[9]^b[9]^cout_91011[0];
  assign s10 = a[10]^b[10]^cout_91011[1];
  assign s11 = a[11]^b[11]^cout_91011[2];
  assign s12 = a[12]^b[12]^c_4812[2];
  assign s13 = a[13]^b[13]^cout_131415[0];
  assign s14 = a[14]^b[14]^cout_131415[1];
  assign s15 = a[15]^b[15]^cout_131415[2];
  assign sum = {s15, s14, s13, s12, s11, s10, s9, s8, s7, s6, s5, s4, s3, s2, s1, s0};
  
endmodule

/** Lab 2 Extra Credit, see details at
  https://github.com/upenn-acg/cis501/blob/master/lab2-alu/lab2-cla.md#extra-credit
 If you are not doing the extra credit, you should leave this module empty.
 */
module gpn
  #(parameter N = 4)
  (input wire [N-1:0] gin, pin,
   input wire  cin,
   output wire gout, pout,
   output wire [N-2:0] cout);
 
endmodule
