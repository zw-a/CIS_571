/* Name: Zihao, Wang
   Pennkey: 51659706*/

`timescale 1ns / 1ps
`default_nettype none
 
module lc4_alu(input  wire [15:0] i_insn,
               input wire [15:0]  i_pc,
               input wire [15:0]  i_r1data,
               input wire [15:0]  i_r2data,
               output wire [15:0] o_result);
  reg  [15:0] pc;
  reg  [15:0] result;
  reg  [15:0] dmem [0:1023];
  wire [3:0] opcode;
  wire [2:0] type;
  wire [1:0] type2;
  wire [3:0] shift;
  wire [8:0] imm9;
  wire [7:0] uimm8;
  wire [5:0] imm6;
  wire [6:0] imm7;
  wire [1:0] type3;

  assign opcode = i_insn[15:12];
  assign type = i_insn[5:3];
  assign type2 = i_insn[5:4];
  assign shift = i_insn[3:0];
  assign imm9 = i_insn[8:0];
  assign uimm8 = i_insn[7:0];
  assign imm6 = i_insn[5:0];
  assign imm7 = i_insn[6:0];
  assign type3 = i_insn[8:7];
  parameter constant = 16'h00FF;
   
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
        result = 16'h0000;
      4'b0001: if (type == 3'b000)
        result = 16'h0000;
      4'b1010: if (type2 == 2'b00)
        result = i_r1data << shift;
      4'b1010: if (type2 == 2'b01)
        result = i_r1data >>> shift;
      4'b1010: if (type2 == 2'b10)
        result = i_r1data >> shift;
      4'b1001: 
        result = {imm9[8] ? 16'hFFFF : 16'h0000, imm9[7:0]};
      4'b1101:
        result = (i_r1data & constant)|(uimm8 << 8);
      4'b0010: 
        result = 16'h0001;
      4'b0000:
        result = i_pc+1;
      4'b1100:
        result = i_r1data;
      4'b0100:
        result = i_r1data;
      4'b1111:
        result = i_pc+1;
      4'b1000:
        result = i_r1data;         
        default: result = 16'h0000;
    endcase
  end           
  assign o_result = result;
  assign i_pc = pc;
endmodule
