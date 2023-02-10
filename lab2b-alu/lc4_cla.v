`timescale 1ns / 1ps
`default_nettype none

module gp1(input wire a, b,
          output wire g, p);
          assign g = a & b;
          assign p = a | b;
endmodule

module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);
  
  assign gout = gin[3]|(gin[2] & pin[3])|(gin[1] & pin[3] & pin[2])|(gin[0] & pin[3] & pin[2] & pin[1]);
  assign pout =(& pin);
 
  assign cout[0] = gin[0] | (cin & pin[0]);
  assign cout[1] = gin[1] | (pin[1] & gin[0]) | (pin[1] & pin[0] & cin);
  assign cout[2] = gin[2] | (pin[2] & gin[1]) | (pin[2] & pin[1] & gin[0]) | (pin[2] & pin[1] & pin[0] & cin);
endmodule

module cla16
  (input wire [15:0]  a, b,
   input wire         cin,
   output wire [15:0] sum);
 
  wire [15:0] g,p;
  
  wire gw30, gw74, gw118, gw1512, pw30, pw74, pw118, pw1512;

  wire [16:1] c;

  genvar i;
  for (i=0; i<16; i=i+1) begin
      gp1 pg(
     .a(a[i]),
     .b(b[i]),
     .g(g[i]),
     .p(p[i]));
    end

  gp4 towin(
  .gin({g[3:0]}),
  .pin({p[3:0]}),
  .cin(cin),
  .gout(gw30),
  .pout(pw30),
  .cout(c[3:1]));
  assign c[4] = gw30 | pw30 & cin;

  gp4 win74(
  .gin({g[7:4]}),
  .pin({p[7:4]}),
  .cin(c[4]),
  .gout(gw74),
  .pout(pw74),
  .cout(c[7:5]));
  assign c[8] = gw74 | pw74 & c[4];

  gp4 win118(
  .gin({g[11:8]}),
  .pin({p[11:8]}),
  .cin(c[8]),
  .gout(gw118),
  .pout(pw118),
  .cout(c[11:9]));
  assign c[12] = gw118 | pw118 & c[8];

  gp4 win151(
  .gin({g[15:12]}),
  .pin({p[15:12]}),
  .cin(c[12]),
  .gout(gw1512),
  .pout(pw1512),
  .cout(c[15:13]));
  assign c[16] = gw1512 | pw1512 & c[12];

  genvar h;
  for (h=1; h<16; h=h+1) begin
    assign sum[h] = a[h]^b[h]^c[h];
  end
  assign sum[0] = a[0]^b[0]^cin;
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

  // Generate values for gout and pout
  assign gout = gin[N-1] | (gin[N-2] & pin[N-1]);
  assign pout = pin[0];

  // Generate values for cout
  for (i = 0; i < N-2; i=i+1) begin
    assign cout[i] = gin[i] | (pin[i] & gin[i+1]) | (pin[i] & pin[i+1] & cin);
  end
endmodule
