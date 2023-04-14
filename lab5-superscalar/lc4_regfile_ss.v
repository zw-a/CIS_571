`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

/* 8-register, n-bit register file with
 * four read ports and two write ports
 * to support two pipes.
 * 
 * If both pipes try to write to the
 * same register, pipe B wins.
 * 
 * Inputs should be bypassed to the outputs
 * as needed so the register file returns
 * data that is written immediately
 * rather than only on the next cycle.
 */
module lc4_regfile_ss #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,

    input  wire [  2:0] i_rs_A,      // pipe A: rs selector
    output wire [n-1:0] o_rs_data_A, // pipe A: rs contents
    input  wire [  2:0] i_rt_A,      // pipe A: rt selector
    output wire [n-1:0] o_rt_data_A, // pipe A: rt contents

    input  wire [  2:0] i_rs_B,      // pipe B: rs selector
    output wire [n-1:0] o_rs_data_B, // pipe B: rs contents
    input  wire [  2:0] i_rt_B,      // pipe B: rt selector
    output wire [n-1:0] o_rt_data_B, // pipe B: rt contents

    input  wire [  2:0]  i_rd_A,     // pipe A: rd selector
    input  wire [n-1:0]  i_wdata_A,  // pipe A: data to write
    input  wire          i_rd_we_A,  // pipe A: write enable

    input  wire [  2:0]  i_rd_B,     // pipe B: rd selector
    input  wire [n-1:0]  i_wdata_B,  // pipe B: data to write
    input  wire          i_rd_we_B   // pipe B: write enable
    );

    wire [n-1:0] reg_data [7:0];
    wire [7:0] reg_we_bus;

    genvar i;
    generate
        for (i = 0; i < 8; i = i+1) begin : reg_gen
            assign reg_we_bus[i] = (i == i_rd_A && i_rd_we_A == 1) ||
                (i == i_rd_B && i_rd_we_B == 1) ? 1'b1 : 1'b0;

            wire [15:0] writeVal;
            assign writeVal = (i == i_rd_B && (i_rd_we_B)) ? i_wdata_B : i_wdata_A;
            Nbit_reg #(.n(n)) reg_instance (
                .in    (writeVal),
                .out   (reg_data[i]),
                .clk   (clk),
                .we    (reg_we_bus[i]),
                .gwe   (gwe),
                .rst   (rst)
            );
        end
    endgenerate

    wire [n-1:0] reg_bypass_result [7:0];
    generate
        for (i = 0; i < 8; i = i + 1) begin
            assign reg_bypass_result[i] = (i == i_rd_B && i_rd_we_B == 1) ? i_wdata_B :
                                          (i == i_rd_A && i_rd_we_A == 1) ? i_wdata_A :
                                          reg_data[i];
        end
    endgenerate

    assign o_rs_data_A = reg_bypass_result[i_rs_A];
    assign o_rt_data_A = reg_bypass_result[i_rt_A];
    assign o_rs_data_B = reg_bypass_result[i_rs_B];
    assign o_rt_data_B = reg_bypass_result[i_rt_B];


endmodule
