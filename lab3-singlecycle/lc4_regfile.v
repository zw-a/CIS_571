/* TODO: name and PennKeys of all group members here
 *
 * lc4_regfile.v
 * Implements an 8-register register file parameterized on word size.
 *
 */

`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

module lc4_regfile #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,
    input  wire [  2:0] i_rs,      // rs selector
    output wire [n-1:0] o_rs_data, // rs contents
    input  wire [  2:0] i_rt,      // rt selector
    output wire [n-1:0] o_rt_data, // rt contents
    input  wire [  2:0] i_rd,      // rd selector
    input  wire [n-1:0] i_wdata,   // data to write
    input  wire         i_rd_we    // write enable
    );

 reg [n-1:0] reg_file [0:7];

 always @(posedge clk, posedge rst) begin
   if (rst) begin
     reg_file[0] <= 0;
     reg_file[1] <= 0;
     reg_file[2] <= 0;
     reg_file[3] <= 0;
     reg_file[4] <= 0;
     reg_file[5] <= 0;
     reg_file[6] <= 0;
     reg_file[7] <= 0;
 end
 else if (gwe && i_rd_we) begin
    reg_file[i_rd] <= i_wdata;
   end
 end

 assign o_rs_data = reg_file[i_rs];
 assign o_rt_data = reg_file[i_rt];
                  
endmodule
