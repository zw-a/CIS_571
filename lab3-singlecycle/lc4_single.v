/* TODO: name and PennKeys of all group members here
 *
 * lc4_single.v
 * Implements a single-cycle data path
 *
 */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input  wire        clk,                // Main clock
    input  wire        rst,                // Global reset
    input  wire        gwe,                // Global we for single-step clock
   
    output wire [15:0] o_cur_pc,           // Address to read from instruction memory
    input  wire [15:0] i_cur_insn,         // Output of instruction memory
    output wire [15:0] o_dmem_addr,        // Address to read/write from/to data memory; SET TO 0x0000 FOR NON LOAD/STORE INSNS
    input  wire [15:0] i_cur_dmem_data,    // Output of data memory
    output wire        o_dmem_we,          // Data memory write enable
    output wire [15:0] o_dmem_towrite,     // Value to write to data memory

    // Testbench signals are used by the testbench to verify the correctness of your datapath.
    // Many of these signals simply export internal processor state for verification (such as the PC).
    // Some signals are duplicate output signals for clarity of purpose.
    //
    // Don't forget to include these in your schematic!

    output wire [1:0]  test_stall,         // Testbench: is this a stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc,        // Testbench: program counter
    output wire [15:0] test_cur_insn,      // Testbench: instruction bits
    output wire        test_regfile_we,    // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel,  // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data,  // Testbench: value to write into the register file
    output wire        test_nzp_we,        // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits,  // Testbench: value to write to NZP bits
    output wire        test_dmem_we,       // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr,     // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data,     // Testbench: value read/writen from/to memory
   
    input  wire [7:0]  switch_data,        // Current settings of the Zedboard switches
    output wire [7:0]  led_data            // Which Zedboard LEDs should be turned on?
    );

   // By default, assign LEDs to display switch inputs to avoid warnings about
   // disconnected ports. Feel free to use this for debugging input/output if
   // you desire.
   assign led_data = switch_data;

   
   /* DO NOT MODIFY THIS CODE */
   // Always execute one instruction each cycle (test_stall will get used in your pipelined processor)
   assign test_stall = 2'b0; 

   // pc wires attached to the PC register's ports
   wire [15:0]   pc;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)

   // Program counter register, starts at 8200h at bootup
   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   /* END DO NOT MODIFY THIS CODE */
   
    
 
   // decoder
    wire [2:0] rs;
    wire [2:0] rt;
    wire [2:0] rd;
    wire       r1re;               // does this instruction read from rs?
    wire       r2re;               // does this instruction read from rt?
    wire       i_rd_we;                 // does this instruction write to rd?
    wire       nzp_we;             // does this instruction write the NZP bits?
    wire       select_pc_plus_one; // write PC+1 to the regfile?
    wire       is_load;            // is this a load instruction?
    wire       is_store;           // is this a store instruction?
    wire       is_branch;          // is this a branch instruction?
    wire       is_control_insn;    // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?
    lc4_decoder dc(.insn              (i_cur_insn),
                   .r1sel             (rs),
                   .r1re              (r1re),
                   .r2sel             (rt),
                   .r2re              (r2re),
                   .wsel              (rd),
                   .regfile_we        (i_rd_we),
                   .nzp_we            (nzp_we),
                   .select_pc_plus_one(select_pc_plus_one),
                   .is_load           (is_load),
                   .is_store          (is_store),
                   .is_branch         (is_branch),
                   .is_control_insn   (is_control_insn)
                   ); 
   
    assign test_regfile_we = i_rd_we;
    assign test_nzp_we = nzp_we;
    assign test_regfile_wsel = rd;
    assign test_cur_insn = i_cur_insn;
   
    // Register file
    wire [15:0] rs_data;
    wire [15:0] rt_data;
    wire [15:0] i_wdata;
    wire [15:0] alu_out;
    lc4_regfile regfile (.clk         (clk),
                         .gwe         (gwe),
                         .rst         (rst),
                         .i_rs        (rs),
                         .o_rs_data   (rs_data),
                         .i_rt        (rt),
                         .o_rt_data   (rt_data),
                         .i_rd        (rd),
                         .i_wdata     (i_wdata), // data to write
                         .i_rd_we     (i_rd_we));

    // ALU
    lc4_alu alu (
      .i_insn    (i_cur_insn),
      .i_pc      (pc),
      .i_r1data  (rs_data),
      .i_r2data  (rt_data),
      .o_result  (alu_out)
   );
   
 
    assign test_dmem_data = (is_load && ~is_store) ? i_cur_dmem_data :
                              (~is_load && is_store) ? rt_data :
                              16'h0000;
    
    //pc and nzp logic
    assign o_cur_pc = pc;
    assign test_cur_pc = pc;
    wire [15:0] pc_plus_one;
    cla16 cla (.a(pc), .b(16'h0000), .cin(1'b1), .sum(pc_plus_one));
   
   
    wire [2:0] nzp_new_bits;
    wire [2:0] nzp_r;
    wire n = (i_wdata[15] == 1'b1);
    wire z = (i_wdata == 0);
    wire p = (~n & ~z); 
    Nbit_reg #(3,3'b000) nzp_reg (.in(nzp_new_bits), .out(nzp_r), .clk(clk), .we(nzp_we), .gwe(gwe), .rst(rst));
    assign nzp_new_bits = (n) ? 3'b100 : 
                          (z) ? 3'b010 : 
                          (p) ? 3'b001 : 3'b000;
    assign test_nzp_new_bits = nzp_new_bits;
   
    
    assign next_pc = (select_pc_plus_one) ? pc_plus_one:alu_out;
    assign o_dmem_addr = (is_load|is_store) ? alu_out : 16'h0000;
    
     
    //write back to regfile
    assign i_wdata = (is_load) ? i_cur_dmem_data :
                     ((select_pc_plus_one == 0) ? alu_out :
                      ((select_pc_plus_one == 1) ? pc_plus_one :
                       i_wdata));

               
    // Assign output and test wires
    assign o_dmem_we = is_store;
    assign o_dmem_towrite = rt_data;
    assign test_regfile_data = i_wdata;
    assign test_dmem_we = is_store;
    assign test_dmem_addr = o_dmem_addr;
    
                        


   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    * 
    * To disable the entire block add the statement
    * `define NDEBUG
    * to the top of your file.  We also define this symbol
    * when we run the grading scripts.
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
      // then right-click, and select Radix->Hexadecial.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      // $display();
   end
`endif
endmodule
