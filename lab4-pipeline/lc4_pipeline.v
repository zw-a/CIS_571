/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input wire         clk, // main clock
    input wire         rst, // global reset
    input wire         gwe, // global we for single-step clock
                                    
    output wire [15:0] o_cur_pc, // Address to read from instruction memory
    input  wire [15:0] i_cur_insn, // Output of instruction memory
    output wire [15:0] o_dmem_addr, // Address to read/write from/to data memory
    input  wire [15:0] i_cur_dmem_data, // Output of data memory
    output wire        o_dmem_we, // Data memory write enable
    output wire [15:0] o_dmem_towrite, // Value to write to data memory
   
    output wire [1:0]  test_stall, // Testbench: is this is stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc, // Testbench: program counter
    output wire [15:0] test_cur_insn, // Testbench: instruction bits
    output wire        test_regfile_we, // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel, // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data, // Testbench: value to write into the register file
    output wire        test_nzp_we, // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits, // Testbench: value to write to NZP bits
    output wire        test_dmem_we, // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr, // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data, // Testbench: value read/writen from/to memory

    input  wire [7:0]  switch_data, // Current settings of the Zedboard switches
    output wire [7:0]  led_data // Which Zedboard LEDs should be turned on?
    );
   
   /*** YOUR CODE HERE ***/
  
   wire loadToUse;
   wire [1:0]  D_stall_in, D_stall_out, DX_stall, XM_stall, MW_stall;
   wire [15:0] AluBP_A, AluBP_B, WM_BP,D_IR_in, D_IR_out, X_in_A, X_in_B, X_out_A, X_out_B, M_in, M_out_A, M_out_B, W_Dmem_in, W_out_A, W_out_B;
   wire [15:0] W_result, next_pc, F_pc_out, DX_pc, X_pc_out, MW_pc, W_pc_out, rs_data, rt_data, select_result, alu_out,F_pc_plus_one;
   wire [33:0] X_IR_in, DX_dcd, XM_dcd, MW_dcd, W_dcd;
   wire [2:0]  MW_nzp_bits, W_NZP_in;
   assign      DX_dcd [15:0] = D_IR_out;

   lc4_decoder dcd (.r1sel(DX_dcd [33:31]), 
                    .r2sel(DX_dcd [30:28]),
                    .wsel(DX_dcd [27:25]),
                    .r1re(DX_dcd [24]),
                    .r2re(DX_dcd [23]),
                    .regfile_we(DX_dcd [22]),
                    .nzp_we(DX_dcd [21]), 
                    .select_pc_plus_one(DX_dcd [20]),
                    .is_load(DX_dcd [19]), 
                    .is_store(DX_dcd [18]),
                    .is_branch(DX_dcd [17]), 
                    .is_control_insn(DX_dcd [16]),
                    .insn(DX_dcd [15:0]));

   lc4_regfile rgf (.clk(clk),
                    .gwe(gwe),
                    .rst(rst),
                    .i_rs(DX_dcd [33:31]), 
                    .o_rs_data(rs_data),
                    .i_rt(DX_dcd [30:28]), 
                    .o_rt_data(rt_data),
                    .i_rd(W_dcd[27:25]), 
                    .i_wdata(W_result), 
                    .i_rd_we(W_dcd[22]));
                        
    lc4_alu alu (.i_insn(XM_dcd[15:0]),
                .i_pc(X_pc_out),
                .i_r1data(AluBP_A),
                .i_r2data(AluBP_B),
                .o_result(alu_out));
   

   cla16 cla (.a(F_pc_out), .b(16'b0), .cin(1'b1), .sum(F_pc_plus_one));

   Nbit_reg #(16, 16'h8200) F_PC (.in(next_pc), .out(F_pc_out), .clk(clk), .we(~loadToUse), .gwe(gwe), .rst(rst));
   wire isLoad;
   wire isDecodeSourceRd;
   wire isDecodeSourceRt;
   wire isDecodeStore;
   wire [3:0] decodeOpcode;
   wire isDecodeRdEqualLoadRd;
   wire isDecodeRtEqualLoadRd;

   assign isLoad = XM_dcd[19];
   assign isDecodeSourceRd = DX_dcd[24];
   assign isDecodeSourceRt = DX_dcd[23];
   assign isDecodeStore = DX_dcd[18];
   assign decodeOpcode = DX_dcd[15:12];
   assign isDecodeRdEqualLoadRd = (DX_dcd[33:31] == XM_dcd[27:25]);
   assign isDecodeRtEqualLoadRd = (DX_dcd[30:28] == XM_dcd[27:25]);
   assign loadToUse = isLoad && (
                    (isDecodeSourceRd && isDecodeRdEqualLoadRd) ||
                    (isDecodeSourceRt && isDecodeRtEqualLoadRd && ~isDecodeStore) ||
                    (decodeOpcode == 4'b0));
   
   wire isBranchTakenOrControl = (X_branch_taken_or_control == 1);
   wire isLoadToUseOrBranchTakenOrControl = ((loadToUse | X_branch_taken_or_control) == 1);

   assign D_stall_in = isBranchTakenOrControl ? 2'd2 : 2'd0;
   assign DX_stall = loadToUse ? 2'd3 : isBranchTakenOrControl ? 2'd2 :  D_stall_out;
   assign D_IR_in = isBranchTakenOrControl ? {16{1'b0}} : i_cur_insn;
   assign X_IR_in = isLoadToUseOrBranchTakenOrControl ? {34{1'b0}} : DX_dcd;

   Nbit_reg #(16, 16'b0) D_PC (.in(F_pc_out), .out(DX_pc), .clk(clk), .we(~loadToUse), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) D_IR (.in(D_IR_in), .out(D_IR_out), .clk(clk), .we(~loadToUse), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10)  D_Stall (.in(D_stall_in), .out(D_stall_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
  
   wire isWoutDecodeRsrc1Match;
   wire isWoutDecodeRsrc1Load;

   assign isWoutDecodeRsrc1Match = (W_dcd[27:25] == DX_dcd[33:31]);
   assign isWoutDecodeRsrc1Load = isWoutDecodeRsrc1Match && W_dcd[22];
   assign X_in_A = isWoutDecodeRsrc1Load ? W_result : rs_data;

   wire isWoutDecodeRsrc2Match;
   wire isWoutDecodeRsrc2Load;

   assign isWoutDecodeRsrc2Match = (W_dcd[27:25] == DX_dcd[30:28]);
   assign isWoutDecodeRsrc2Load = isWoutDecodeRsrc2Match && W_dcd[22];
   assign X_in_B = isWoutDecodeRsrc2Load ? W_result : rt_data;

   Nbit_reg #(16, 16'b0) X_PC (.in(DX_pc), .out(X_pc_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) X_A (.in(X_in_A), .out(X_out_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) X_B (.in(X_in_B), .out(X_out_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(34, 34'b0) X_IR (.in(X_IR_in), .out(XM_dcd), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10)  X_Stall (.in(DX_stall), .out(XM_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire isXmMwMatch;
   wire isXmMwLoad;
   wire isXmWoutMatch;
   wire isXmWoutLoad;

   assign isXmMwMatch = (XM_dcd[33:31] == MW_dcd[27:25]);
   assign isXmMwLoad = isXmMwMatch && (MW_dcd[22] == 1);
   assign isXmWoutMatch = (XM_dcd[33:31] == W_dcd[27:25]);
   assign isXmWoutLoad = isXmWoutMatch && (W_dcd[22] == 1);
   assign AluBP_A = isXmMwLoad ? M_out_A : (isXmWoutLoad ? W_result : X_out_A);

   wire isXmMwMatchB; 
   wire isXmMwLoadB;
   wire isXmWoutMatchB;
   wire isXmWoutLoadB;

   assign isXmMwMatchB = (XM_dcd[30:28] == MW_dcd[27:25]);
   assign isXmMwLoadB = isXmMwMatchB && (MW_dcd[22] == 1);
   assign isXmWoutMatchB = (XM_dcd[30:28] == W_dcd[27:25]);
   assign isXmWoutLoadB = isXmWoutMatchB && (W_dcd[22] == 1);
   assign AluBP_B = isXmMwLoadB ? M_out_A : (isXmWoutLoadB ? W_result : X_out_B);

   wire isMwWoutMatch;
   wire isMwWoutLoad;
   wire isMwStore;

   assign isMwWoutMatch = (MW_dcd[30:28] == W_dcd[27:25]);
   assign isMwWoutLoad = isMwWoutMatch && (W_dcd[22]);
   assign isMwStore = (MW_dcd[18]);
   assign WM_BP = (isMwStore && isMwWoutLoad) ? W_result : M_out_B;
   assign M_in = (XM_dcd[16] == 1) ? DX_pc : alu_out;
   assign W_NZP_in = (MW_dcd[19] == 1) ? nzp_new_bits_ld : MW_nzp_bits;
   assign W_result = (W_dcd[19] == 1) ? W_out_B : W_out_A;

   wire bu_nzp_reduced, X_branch_taken_or_control;
   wire [2:0] nzp_new_bits_alu, nzp_new_bits_ld, nzp_new_bits_trap, nzp_new_bits, bu_nzp_bus, bu_nzp_and;
   
   Nbit_reg #(16, 16'b0) M_PC (.in(X_pc_out), .out(MW_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) M_reg (.in(M_in), .out(M_out_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) M_B (.in(AluBP_B), .out(M_out_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(34, 34'b0) M_IR (.in(XM_dcd), .out(MW_dcd), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0)   M_NZP (.in(nzp_new_bits), .out(MW_nzp_bits), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10)  M_Stall (.in(XM_stall), .out(MW_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   function [2:0] get_nzp_bits;
   input signed [15:0] value;
   begin
     if (value > 0) get_nzp_bits = 3'b001;
       else if (value == 0) get_nzp_bits = 3'b010;
       else get_nzp_bits = 3'b100;
   end
   endfunction

   assign nzp_new_bits_alu = get_nzp_bits($signed(alu_out));
   assign nzp_new_bits_ld = get_nzp_bits($signed(i_cur_dmem_data));
   assign nzp_new_bits_trap = get_nzp_bits($signed(X_pc_out));
   
   assign nzp_new_bits = (XM_dcd[15:12] == 4'b1111) ? nzp_new_bits_trap :
                        ((MW_dcd[19]==1) && (XM_stall==2'd3) ) ? nzp_new_bits_ld :
                        nzp_new_bits_alu;

   Nbit_reg #(.n(3))nzp_reg (.in(nzp_new_bits), .out(bu_nzp_bus),.clk(clk),.we(XM_dcd[21]), .gwe(gwe),.rst(rst) );   
   Nbit_reg #(16, 16'b0) W_PC (.in(MW_pc), .out(W_pc_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) W_reg (.in(M_out_A), .out(W_out_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) W_D (.in(i_cur_dmem_data), .out(W_out_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(34, 34'b0) W_IR (.in(MW_dcd), .out(W_dcd), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0)   W_NZP (.in(W_NZP_in), .out(test_nzp_new_bits), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10)  W_Stall (.in(MW_stall), .out(test_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0)   W_Dmem (.in(o_dmem_we), .out(test_dmem_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) W_DmemAdd (.in(o_dmem_addr), .out(test_dmem_addr), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) W_Data (.in(W_Dmem_in), .out(test_dmem_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   assign bu_nzp_and = bu_nzp_bus & XM_dcd[11:9]; 
   assign bu_nzp_reduced = |bu_nzp_and;
   assign X_branch_taken_or_control = (bu_nzp_reduced & XM_dcd[17]) || XM_dcd[16];
   assign next_pc = (X_branch_taken_or_control == 1) ? alu_out : F_pc_plus_one;
   assign o_cur_pc = F_pc_out;
   assign o_dmem_addr = ((MW_dcd[19] == 1) || (MW_dcd[18] == 1)) ? M_out_A : 16'b0;                   
   assign o_dmem_we = MW_dcd[18];
   assign o_dmem_towrite = WM_BP;       
   assign test_cur_pc = W_pc_out;              
   assign test_cur_insn = W_dcd[15:0];
   assign test_regfile_we = W_dcd[22];
   assign test_regfile_wsel = W_dcd[27:25];
   assign test_regfile_data = W_result;
   assign test_nzp_we = W_dcd[21];
   
   reg [15:0] tmp_stageW_regDmemData_input;
   always @(*) begin
     if (MW_dcd[19] == 1) begin
        tmp_stageW_regDmemData_input = i_cur_dmem_data;
     end else if (MW_dcd[18] == 1) begin
        tmp_stageW_regDmemData_input = WM_BP;
     end else begin
        tmp_stageW_regDmemData_input = 16'b0;
     end
   end
   assign W_Dmem_in = tmp_stageW_regDmemData_input;

   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    * 
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    */

`ifndef NDEBUG
   always @(posedge gwe) begin
      // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then you can easily look up the
      // instructions in the .asm files in test_data.

      // basic if syntax:
      // if (cond) begin
      //    ...;
      //    ...;
      // end

      // Set a breakpoint on the empty $display() below
      // to step through your pipeline cycle-by-cycle.
      // You'll need to rewind the simulation to start
      // stepping from the beginning.

      // You can also simulate for XXX ns, then set the
      // breakpoint to start stepping midway through the
      // testbench.  Use the $time printouts you added above (!)
      // to figure out when your problem instruction first
      // enters the fetch stage.  Rewind your simulation,
      // run it for that many nano-seconds, then set
      // the breakpoint.

      // In the objects view, you can change the values to
      // hexadecimal by selecting all signals (Ctrl-A),
      // then right-click, and select Radix->Hexadecimal.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      //$display(); 
   end
`endif
endmodule
