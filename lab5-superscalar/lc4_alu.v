/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps

`default_nettype none

module lc4_alu(input  wire [15:0] i_insn,
               input wire [15:0]  i_pc,
               input wire [15:0]  i_r1data,
               input wire [15:0]  i_r2data,
               output wire [15:0] o_result);


      wire [15:0] temp1, temp2, temp3, temp4, temp5, temp6, temp7, temp8, temp9, temp10, temp11, temp12, temp13;
      
      //BR NZP code
      wire [15:0] sext9, sext5, sext6, sext11, sext9_mux;
      wire [15:0] A, B, C, D, E, F, G, H;
      assign sext9 = {{7{i_insn[8]}}, i_insn[8:0]};
      assign sext5 = {{11{i_insn[4]}}, i_insn[4:0]};
      assign sext6 = {{10{i_insn[5]}}, i_insn[5:0]};
      assign sext11 = {{5{i_insn[10]}}, i_insn[10:0]};
      assign A = {{7{i_insn[8]}}, i_insn[8:0]};
      assign B = {{7{i_insn[8]}}, i_insn[8:0]};
      assign C = {{7{i_insn[8]}}, i_insn[8:0]};
      assign D = {{7{i_insn[8]}}, i_insn[8:0]};
      assign E = {{7{i_insn[8]}}, i_insn[8:0]};
      assign F = {{7{i_insn[8]}}, i_insn[8:0]};
      assign G = {{7{i_insn[8]}}, i_insn[8:0]};
      assign H = {{7{i_insn[8]}}, i_insn[8:0]};
      wire [2:0] sel1;
      assign sel1 = i_insn[11:9];
      assign sext9_mux = (sel1 == 3'd0) ? $signed(A) :
                        (sel1 == 3'd1) ? $signed(B) :
                        (sel1 == 3'd2) ? $signed(C) :
                        (sel1 == 3'd3) ? $signed(D) :
                        (sel1 == 3'd4) ? $signed(E) :
                        (sel1 == 3'd5) ? $signed(F) :
                        (sel1 == 3'd6) ? $signed(G) : $signed(H);
      wire [15:0] mux1, mux2, mux3;
      wire mux4, mux5;
      wire cin;
      wire [15:0] cla_out;
      wire [2:0] sel0;
      assign sel0 = i_insn[14:12];
      assign mux1 = (sel0 == 3'd0) ? i_pc :
                    (sel0 == 3'd4) ? i_pc : i_r1data;
      assign mux2 = (sel0 == 3'd0) ? $signed(sext9_mux) : 
                    (sel0 == 3'd1) ? mux3 :
                    (sel0 == 3'd4) ? $signed(sext11) : $signed(sext6);
      assign mux3 = (i_insn[5:3] == 3'd0) ? i_r2data :
                    (i_insn[5:3] == 3'd2) ? Rt_neg : $signed(sext5);

      assign mux4 = (i_insn[5:4] == 2'd1) ? 1'b1 : 1'b0;
      assign mux5 = (i_insn[13:12] == 2'd1) ? mux4 : 1'b1;
      assign cin = (i_insn[14:13] == 2'd3) ? 1'b0 : mux5;
      cla16 cla1(.a(mux1), .b(mux2), .cin(cin), .sum(cla_out));
      assign temp1 = cla_out;
      
      //math operations
      wire [2:0] sel2;
      wire [15:0] mul, sub, div, mod, Rt_neg;
      lc4_divider div1(.i_dividend(i_r1data), .i_divisor(i_r2data), .o_quotient(div), .o_remainder(mod));
      assign sel2 = i_insn[5:3];
      assign mul = i_r1data * i_r2data;
      assign Rt_neg = ~i_r2data; // for subtraction
      assign sub = cla_out;

      assign temp2 = (sel2 == 3'd0) ? cla_out :
                        (sel2 == 3'd1) ? mul :
                        (sel2 == 3'd2) ? sub :
                        (sel2 == 3'd3) ? div : cla_out;

      //comparisons
      wire [1:0] sel3;
      wire [15:0] cmp, cmpu, cmpi, cmpiu;
      assign cmp = ($signed(i_r1data) > $signed(i_r2data)) ? 16'h0001 :
                    ($signed(i_r1data) < $signed(i_r2data)) ? 16'hFFFF : 16'h0000;

      assign cmpu = (i_r1data > i_r2data) ? 16'h0001 :
                    (i_r1data < i_r2data) ? 16'hFFFF : 16'h0;

      assign cmpi = ($signed(i_r1data) > $signed(i_insn[6:0])) ? 16'h0001 :
                    ($signed(i_r1data) < $signed(i_insn[6:0])) ? 16'hFFFF : 16'h0;

      assign cmpiu = (i_r1data > i_insn[6:0]) ? 16'h0001 : 
                      (i_r1data < i_insn[6:0]) ? 16'hFFFF : 16'h0;

      assign sel3 = i_insn[8:7];
      assign temp3 = (sel3 == 2'd0) ? cmp :
                  (sel3 == 2'd1) ? cmpu : 
                  (sel3 == 2'd2) ? cmpi : cmpiu;

      //JSR code
      wire [15:0] temp4_0;
      assign temp4_0 = (i_pc & 16'h8000) | (($signed(i_insn[10:0])) << 4);
      assign temp4 = (i_insn[11] == 1) ? temp4_0 : i_r1data;

      //logic operations
      wire [15:0] and1, not1, or1, xor1, and2;
      wire [2:0] sel4;
      assign sel4 = i_insn[5:3];
      assign and1 = i_r1data & i_r2data;
      assign not1 = ~i_r1data;
      assign or1 = i_r1data | i_r2data;
      assign xor1 = i_r1data ^ i_r2data;
      assign and2 = i_r1data & ($signed(sext5));
      assign temp5 = (sel4 == 3'd0) ? and1 :
                        (sel4 == 3'd1) ? not1 :
                        (sel4 == 3'd2) ? or1 :
                        (sel4 == 3'd3) ? xor1 : and2;
      
      //LDR/STR code
      assign temp6 = cla_out;
      assign temp7 = cla_out;
      //RTI
      assign temp8 = i_r1data;
      //CONST
      assign temp9 = $signed(sext9);

      //shift
      wire [1:0] sel5;
      wire [15:0] shift1, shift2, shift3;
      assign sel5 = i_insn[5:4];
      assign shift1 = i_r1data << i_insn[3:0];
      assign shift2 = $signed(i_r1data) >>> $signed(i_insn[3:0]);
      assign shift3 = i_r1data >> i_insn[3:0];
      assign temp10 = (sel5 == 2'd0) ? shift1 :
                        (sel5 == 2'd1) ? shift2 :
                        (sel5 == 2'd2) ? shift3 : mod;
      
      //JMP
      assign temp11 = (i_insn[11] == 1) ? $signed(cla_out) : i_r1data;

      //hiconst
      assign temp12 = (i_r1data & 8'hFF) | (i_insn[7:0] << 8);

      //trap
      assign temp13 = 16'h8000 | i_insn[7:0];




      wire [3:0] select;
      assign select = i_insn[15:12];
      assign o_result = (select == 4'd0) ? temp1 :
                        (select == 4'd1) ? temp2 :
                        (select == 4'd2) ? temp3 :
                        (select == 4'd3) ? 16'h0 :
                        (select == 4'd4) ? temp4 :
                        (select == 4'd5) ? temp5 :
                        (select == 4'd6) ? temp6 :
                        (select == 4'd7) ? temp7 :
                        (select == 4'd8) ? temp8 :
                        (select == 4'd9) ? temp9 :
                        (select == 4'd10) ? temp10 :
                        (select == 4'd11) ? 16'h0 :
                        (select == 4'd12) ? temp11 :
                        (select == 4'd13) ? temp12 :
                        (select == 4'd14) ? 16'h0 : temp13;


endmodule
