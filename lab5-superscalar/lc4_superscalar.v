`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

module lc4_processor(input wire         clk,             // main clock
                     input wire         rst,             // global reset
                     input wire         gwe,             // global we for single-step clock

                     output wire [15:0] o_cur_pc,        // address to read from instruction memory
                     input wire [15:0]  i_cur_insn_A,    // output of instruction memory (pipe A)
                     input wire [15:0]  i_cur_insn_B,    // output of instruction memory (pipe B)

                     output wire [15:0] o_dmem_addr,     // address to read/write from/to data memory
                     input wire [15:0]  i_cur_dmem_data, // contents of o_dmem_addr
                     output wire        o_dmem_we,       // data memory write enable
                     output wire [15:0] o_dmem_towrite,  // data to write to o_dmem_addr if we is set

                     // testbench signals (always emitted from the WB stage)
                     output wire [ 1:0] test_stall_A,        // is this a stall cycle?  (0: no stall,
                     output wire [ 1:0] test_stall_B,        // 1: pipeline stall, 2: branch stall, 3: load stall)

                     output wire [15:0] test_cur_pc_A,       // program counter
                     output wire [15:0] test_cur_pc_B,
                     output wire [15:0] test_cur_insn_A,     // instruction bits
                     output wire [15:0] test_cur_insn_B,
                     output wire        test_regfile_we_A,   // register file write-enable
                     output wire        test_regfile_we_B,
                     output wire [ 2:0] test_regfile_wsel_A, // which register to write
                     output wire [ 2:0] test_regfile_wsel_B,
                     output wire [15:0] test_regfile_data_A, // data to write to register file
                     output wire [15:0] test_regfile_data_B,
                     output wire        test_nzp_we_A,       // nzp register write enable
                     output wire        test_nzp_we_B,
                     output wire [ 2:0] test_nzp_new_bits_A, // new nzp bits
                     output wire [ 2:0] test_nzp_new_bits_B,
                     output wire        test_dmem_we_A,      // data memory write enable
                     output wire        test_dmem_we_B,
                     output wire [15:0] test_dmem_addr_A,    // address to read/write from/to memory
                     output wire [15:0] test_dmem_addr_B,
                     output wire [15:0] test_dmem_data_A,    // data to read/write from/to memory
                     output wire [15:0] test_dmem_data_B,

                     // zedboard switches/display/leds (ignore if you don't want to control these)
                     input  wire [ 7:0] switch_data,         // read on/off status of zedboard's 8 switches
                     output wire [ 7:0] led_data             // set on/off status of zedboard's 8 leds
                     );
   
   wire [15:0]  Fout_pc, pc_plus_one, pc_plus_two, F_pc_out_A, D_IR_in_A, rs_data_A, rt_data_A, alu_out_A, AluBP_rs_A, AluBP_rt_A;
   wire [1:0]   D_stall_in_A, D_regstall_in_A, D_stall_out_A, DX_stall_A, XM_stall_A, MW_stall_A;
   reg  [15:0]  F_pc_out_A_reg, D_IR_in_A_reg;
   reg  [1:0]   D_stall_in_A_reg;
   wire [15:0]  stgD_IR_in_A, D_IR_out_A, X_rs_data_A, X_rt_data_A, M_in_A, M_out_A, M_out_B_A, W_rDmemData_in_A, W_r0_out_A, W_rD_out_A, W_result_A, DX_pc_A, X_pc_out_A, MW_pc_A, W_pc_out_A, dmem_addr_A;
   wire [33:0]  X_IR_in_A, DX_dcd_A, XM_dcd_A, MW_dcd_A_A, W_dcd_A;
   wire [2:0]   MW_nzp_bits_A, W_rNZP_in_A;
   wire [15:0]  next_pc, Stage_D_pc_in_A, Stage_D_pc_in_B, next_pc_added;

 
  lc4_decoder dcdA (.r1sel(DX_dcd_A[33:31]), 
                    .r2sel(DX_dcd_A[30:28]),
                    .wsel(DX_dcd_A[27:25]),
                    .r1re(DX_dcd_A[24]),
                    .r2re(DX_dcd_A[23]),
                    .regfile_we(DX_dcd_A[22]),
                    .nzp_we(DX_dcd_A[21]), 
                    .select_pc_plus_one(DX_dcd_A[20]),
                    .is_load(DX_dcd_A[19]), 
                    .is_store(DX_dcd_A[18]),
                    .is_branch(DX_dcd_A[17]), 
                    .is_control_insn(DX_dcd_A[16]),
                    .insn(DX_dcd_A[15:0]));

 lc4_decoder dcdB (.r1sel(DX_dcd_B[33:31]), 
                   .r2sel(DX_dcd_B[30:28]),
                   .wsel(DX_dcd_B[27:25]),
                   .r1re(DX_dcd_B[24]),
                   .r2re(DX_dcd_B[23]),
                   .regfile_we(DX_dcd_B[22]),
                   .nzp_we(DX_dcd_B[21]), 
                   .select_pc_plus_one(DX_dcd_B[20]),
                   .is_load(DX_dcd_B[19]), 
                   .is_store(DX_dcd_B[18]),
                   .is_branch(DX_dcd_B[17]), 
                   .is_control_insn(DX_dcd_B[16]),
                   .insn(DX_dcd_B[15:0]));
  

    lc4_alu aluA (.i_insn(XM_dcd_A[15:0]),
                  .i_pc(X_pc_out_A),
                  .i_r1data(AluBP_rs_A),
                  .i_r2data(AluBP_rt_A),
                  .o_result(alu_out_A));
    
    lc4_alu aluB (.i_insn(XM_dcd_B[15:0]),
                  .i_pc(X_pc_out_B),
                  .i_r1data(AluBP_rs_B),
                  .i_r2data(AluBP_rt_B),
                  .o_result(alu_out_B));
    
    lc4_regfile_ss main_regfile (.clk(clk),
                                 .gwe(gwe),
                                 .rst(rst),
                                 .i_rs_A(DX_dcd_A[33:31]), 
                                 .o_rs_data_A(rs_data_A),
                                 .i_rt_A(DX_dcd_A[30:28]), 
                                 .o_rt_data_A(rt_data_A),
                                 .i_rs_B(DX_dcd_B[33:31]), 
                                 .o_rs_data_B(rs_data_B),
                                 .i_rt_B(DX_dcd_B[30:28]), 
                                 .o_rt_data_B(rt_data_B),
                                 .i_rd_A(W_dcd_A[27:25]), 
                                 .i_wdata_A(W_result_A), 
                                 .i_rd_we_A(W_dcd_A[22]),
                                 .i_rd_B(W_dcd_B[27:25]), 
                                 .i_wdata_B(W_result_B), 
                                 .i_rd_we_B(W_dcd_B[22]));
   //registers
   Nbit_reg #(16, 16'h8200) F_PC (.in(next_pc), .out(Fout_pc), .clk(clk), .we(~loadToUse), .gwe(gwe), .rst(rst));

   Nbit_reg #(16, 16'b0) D_PC_A (.in(F_pc_out_A), .out(DX_pc_A), .clk(clk), .we(~loadToUse), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) D_IR_A (.in(D_IR_in_A), .out(D_IR_out_A), .clk(clk), .we(~loadToUse), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10)  D_Stall_A (.in(D_stall_in_A), .out(D_stall_out_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
  
   Nbit_reg #(16, 16'b0) D_PC_B (.in(F_pc_out_B), .out(DX_pc_B), .clk(clk), .we(~(loadToUse)), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) D_IR_B (.in(D_IR_in_B), .out(D_IR_out_B), .clk(clk), .we(~(loadToUse)), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10)  D_Stall_B (.in(D_stall_in_B), .out(D_stall_out_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   Nbit_reg #(16, 16'b0) X_PC_A (.in(DX_pc_A), .out(X_pc_out_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) X_rA_A (.in(rs_data_A), .out(X_rs_data_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) X_rB_A (.in(rt_data_A), .out(X_rt_data_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(34, 34'b0) X_IR_A (.in(X_IR_in_A), .out(XM_dcd_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10)  X_Stall_A (.in(DX_stall_A), .out(XM_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 
   Nbit_reg #(16, 16'b0) X_PC_B (.in(DX_pc_B), .out(X_pc_out_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) X_rA_B (.in(rs_data_B), .out(X_rs_data_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) X_rB_B (.in(rt_data_B), .out(X_rt_data_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(34, 34'b0) X_IR_B (.in(X_IR_in_B), .out(XM_dcd_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10)  X_Stall_B (.in(DX_stall_B), .out(XM_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 
   Nbit_reg #(16, 16'b0) M_PC_A (.in(X_pc_out_A), .out(MW_pc_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) M_rO_A (.in(M_in_A), .out(M_out_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) M_rB_A (.in(AluBP_rt_A), .out(M_out_B_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(34, 34'b0) M_IR_A (.in(XM_dcd_A), .out(MW_dcd_A_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0)   M_NZP_A (.in(nzp_new_bits_A), .out(MW_nzp_bits_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10)  M_Stall_A (.in(XM_stall_A), .out(MW_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   Nbit_reg #(16, 16'b0) M_PC_B (.in(X_pc_out_B), .out(MW_pc_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) M_rO_B (.in(M_in_B), .out(M_out_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) M_rB_B (.in(AluBP_rt_B), .out(M_out_B_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(34, 34'b0) M_IR_B (.in(M_IR_in_B), .out(MW_dcd_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0)   M_NZP_B (.in(final_nap_bits_B), .out(MW_nzp_bits_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10)  M_Stall_B (.in(XM_stallc_B), .out(MW_stallc_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   Nbit_reg #(16, 16'b0) W_PC_A (.in(MW_pc_A), .out(W_pc_out_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) W_rO_A (.in(M_out_A), .out(W_r0_out_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) W_rD_A (.in(i_cur_dmem_data), .out(W_rD_out_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(34, 34'b0) W_rIR_A (.in(MW_dcd_A_A), .out(W_dcd_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0)   W_rNZP_A (.in(W_rNZP_in_A), .out(test_nzp_new_bits_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10)  W_rStall_A (.in(MW_stall_A), .out(test_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0)   W_rDmem_A (.in(MW_dcd_A_A[18]), .out(test_dmem_we_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) W_rDmemAdd_A (.in(dmem_addr_A), .out(test_dmem_addr_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) W_rDmemData_A (.in(W_rDmemData_in_A), .out(test_dmem_data_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   Nbit_reg #(.n(3)) pipeB_nzp_reg (.in(final_nap_bits_B),.out(nzp_reg_out),.clk(clk),.we(1'b1), .gwe(gwe),.rst(rst));
   Nbit_reg #(16, 16'b0) W_PC_B (.in(MW_pc_B), .out(W_pc_out_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) W_rO_B (.in(M_out_B), .out(W_r0_out_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) W_rD_B (.in(i_cur_dmem_data), .out(W_rD_out_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(34, 34'b0) W_rIR_B (.in(MW_dcd_B), .out(W_dcd_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b0)   W_rNZP_B (.in(W_rNZP_in_B), .out(test_nzp_new_bits_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b10)  W_rStall_B (.in(MW_stallc_B), .out(test_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0)   W_rDmem_B (.in(MW_dcd_B[18]), .out(test_dmem_we_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) W_rDmemAdd_B (.in(dmem_addr_B), .out(test_dmem_addr_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) W_rDmemData_B (.in(W_rDmemData_in_B), .out(test_dmem_data_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   cla16 pc_plus_1(.a(Fout_pc), .b(16'b0), .cin(1'b1), .sum(pc_plus_one));
   cla16 pc_plus_2(.a(pc_plus_one), .b(16'b0), .cin(1'b1), .sum(pc_plus_two));
   // bypassing logic
   assign Stage_D_pc_in_A = Fout_pc;
   assign Stage_D_pc_in_B = pc_plus_one;
   assign next_pc_added =  (loadToUse) ? Fout_pc : (pipe_switch == 1) ? pc_plus_one : pc_plus_two;
   assign next_pc =  (X_br_toc_A == 1) ? alu_out_A :(X_br_toc_B == 1) ? alu_out_B :next_pc_added;
   assign F_pc_out_A = F_pc_out_A_reg;
   assign D_IR_in_A = D_IR_in_A_reg;
   assign D_stall_in_A = D_stall_in_A_reg;
   assign DX_dcd_A[15:0] = D_IR_out_A; 
   reg [15:0] AluBP_rs_A_reg, AluBP_rt_A_reg, WM_bp_rst_A;
   assign AluBP_rs_A = AluBP_rs_A_reg;
   assign AluBP_rt_A = AluBP_rt_A_reg;
   reg [15:0] M_in_A_aux;
   assign M_in_A = M_in_A_aux;
   reg [2:0] W_rNZP_in_A_aux;
   assign W_rNZP_in_A = W_rNZP_in_A_aux;
   reg [15:0] W_result_A_aux;
   assign W_result_A = W_result_A_aux;
   reg [15:0] W_rDmemData_in_A_aux;
   assign W_rDmemData_in_A = W_rDmemData_in_A_aux;
   reg [15:0] dmem_addr_A_aux;
   
   always @(*) begin
    if (!branch_taken && pipe_switch) begin
        F_pc_out_A_reg = DX_pc_B;
        D_IR_in_A_reg = D_IR_out_B;
        D_stall_in_A_reg = D_stall_out_B;
    end else begin
        F_pc_out_A_reg = Stage_D_pc_in_A;
        D_IR_in_A_reg = stgD_IR_in_A;
        D_stall_in_A_reg = D_regstall_in_A;
    end
  end
      
   always @(*) begin
   if ((XM_dcd_A[33:31] == MW_dcd_B[27:25]) && (MW_dcd_B[22] == 1)) begin
        AluBP_rs_A_reg = M_out_B;
    end else if ((XM_dcd_A[33:31] == MW_dcd_A_A[27:25]) && (MW_dcd_A_A[22] == 1)) begin
        AluBP_rs_A_reg = M_out_A;
    end else if ((XM_dcd_A[33:31] == W_dcd_B[27:25]) && W_dcd_B[22] == 1) begin
        AluBP_rs_A_reg = W_result_B;
    end else if ((XM_dcd_A[33:31] == W_dcd_A[27:25]) && W_dcd_A[22] == 1) begin
        AluBP_rs_A_reg = W_result_A;
    end else begin
        AluBP_rs_A_reg = X_rs_data_A;
    end

    if ((XM_dcd_A[30:28] == MW_dcd_B[27:25]) && (MW_dcd_B[22] == 1)) begin
        AluBP_rt_A_reg = M_out_B;
    end else if ((XM_dcd_A[30:28] == MW_dcd_A_A[27:25]) && (MW_dcd_A_A[22] == 1)) begin
        AluBP_rt_A_reg = M_out_A;
    end else if ((XM_dcd_A[30:28] == W_dcd_B[27:25]) && W_dcd_B[22] == 1) begin
        AluBP_rt_A_reg = W_result_B;
    end else if ((XM_dcd_A[30:28] == W_dcd_A[27:25]) && W_dcd_A[22] == 1) begin
        AluBP_rt_A_reg = W_result_A;
    end else begin
        AluBP_rt_A_reg = X_rt_data_A;
    end

    if ((MW_dcd_A_A[18]) && (W_dcd_B[22]) && (MW_dcd_A_A[30:28] == W_dcd_B[27:25])) begin
        WM_bp_rst_A = W_result_B;  
    end else if ((MW_dcd_A_A[18]) && (W_dcd_A[22]) && (MW_dcd_A_A[30:28] == W_dcd_A[27:25])) begin
        WM_bp_rst_A = W_result_A;  
    end else begin
    WM_bp_rst_A = M_out_B_A;
    end
    end

   always @(*) begin
    if (XM_dcd_A[16] == 1) begin
        M_in_A_aux = X_pc_out_B;
    end else begin
        M_in_A_aux = alu_out_A;
    end
   end

   always @(*) begin
    if (MW_dcd_A_A[19] == 1) begin
        W_rNZP_in_A_aux = nzp_new_bits_ld_A;
    end else begin
        W_rNZP_in_A_aux = MW_nzp_bits_A;
    end
   end

   always @(*) begin
    if (W_dcd_A[19] == 1) begin
        W_result_A_aux = W_rD_out_A;
    end else begin
        W_result_A_aux = W_r0_out_A;
    end
   end

   always @(*) begin
    if (MW_dcd_A_A[19] == 1) begin
        W_rDmemData_in_A_aux = i_cur_dmem_data;
    end else if (MW_dcd_A_A[18] == 1) begin
        W_rDmemData_in_A_aux = 16'b1;
    end else begin
        W_rDmemData_in_A_aux = 16'b0;
    end
   end

   always @(*) begin
    if ((MW_dcd_A_A[19] == 1) || (MW_dcd_A_A[18] == 1)) begin
        dmem_addr_A_aux = M_out_A;
    end else begin
        dmem_addr_A_aux = 16'b0;
    end
   end
   // bypassing and stalling
   assign dmem_addr_A = dmem_addr_A_aux;
   assign ps_not_br = (pipe_switch == 1 && branch_taken == 0);
   assign F_pc_out_B = ps_not_br ? Stage_D_pc_in_A : Stage_D_pc_in_B;
   assign D_IR_in_B = ps_not_br ? stgD_IR_in_A : stgD_IR_in_B;
   assign D_stall_in_B = ps_not_br ? D_regstall_in_A : stgD_rstall_in_B;
   assign DX_dcd_B[15:0] = D_IR_out_B; 
   assign XbDaR1_dependence = XbDaR1_dependence_temp;
   assign XbDaR2_dependence = XbDaR2_dependence_temp;
   assign XbDaBr_dependence = XbDaBr_dependence_temp;
   assign LTU_XbDa = LTU_XbDa_temp;
   assign XaDaR1_dependence = XaDaR1_dependence_temp;
   assign XaDaR2_dependence = XaDaR2_dependence_temp;
   assign XaDaBr_dependence = XaDaBr_dependence_temp;
   assign LTU_XaDa = LTU_XaDa_temp;

   wire [15:0] rs_data_B, rt_data_B, alu_out_B, F_pc_out_B, D_IR_in_B;
   wire [1:0]  D_stall_in_B, stgD_rstall_in_B, D_stall_out_B, DX_stall_B, XM_stall_B, MW_stallc_B;
   wire [15:0] stgD_IR_in_B, D_IR_out_B, X_rs_data_B, X_rt_data_B, M_in_B, M_out_B, M_out_B_B;
   wire [15:0] W_rDmemData_in_B, W_r0_out_B, W_rD_out_B, W_result_B,DX_pc_B, X_pc_out_B, MW_pc_B, W_pc_out_B;
   wire [33:0] DX_dcd_B, X_IR_in_B, XM_dcd_B, M_IR_in_B, MW_dcd_B, W_dcd_B;
   wire [2:0]  MW_nzp_bits_B, W_rNZP_in_B;
   wire [15:0] dmem_addr_B;
   reg  [15:0] AluBP_rs_B, AluBP_rt_B;
   wire ps_not_br;
   
   wire LTU_XbDa, LTU_XaDa, LTU_XaDa_B;
   wire XbDaR1_dependence, XbDaR2_dependence, XbDaBr_dependence;
   wire XaDaR1_dependence, XaDaR2_dependence, XaDaBr_dependence;
   wire XaDbR1_dependence, XaDbR2_dependence, XaDbBr_dependence;
   wire loadToUse, LTU_B;
   wire pipe_switch, scl_stall_B;

   reg XbDaR1_dependence_temp;
   reg XbDaR2_dependence_temp;
   reg XbDaBr_dependence_temp;
   reg LTU_XbDa_temp;
   reg XaDaR1_dependence_temp;
   reg XaDaR2_dependence_temp;
   reg XaDaBr_dependence_temp;
   reg LTU_XaDa_temp;
   reg DaDbR1_dependence;
   reg DaDbR2_dependence;
   reg DaDbBr_dependence;
   reg DaDbMem_dependence;
   reg decode_dependence;
   reg XbDbR1_dependence;
   reg XbDbR2_dependence;
   reg XbDbBr_dependence;
   reg LTU_B_XbDb;

   always @(*) begin
    if ((DX_dcd_A[24]) && (XM_dcd_B[22]) && (DX_dcd_A[33:31] == XM_dcd_B[27:25]))
        XbDaR1_dependence_temp = 1'b1;
    else
        XbDaR1_dependence_temp = 1'b0;
    
    if ((DX_dcd_A[23]) && (XM_dcd_B[22]) && (DX_dcd_A[30:28] == XM_dcd_B[27:25]) && (~DX_dcd_A[18]))
        XbDaR2_dependence_temp = 1'b1;
    else
        XbDaR2_dependence_temp = 1'b0;

    if ((DX_dcd_A[15:12]==4'b0) && (DX_dcd_A[15:0] != 16'b0) && (XM_dcd_B[21] == 1))
        XbDaBr_dependence_temp = 1'b1;
    else
        XbDaBr_dependence_temp = 1'b0;

    if (XM_dcd_B[19] && (XbDaR1_dependence_temp || XbDaR2_dependence_temp || XbDaBr_dependence_temp) && ~branch_taken)
        LTU_XbDa_temp = 1'b1;
    else
        LTU_XbDa_temp = 1'b0;

    if ((DX_dcd_A[24]) && (XM_dcd_A[22]) && (DX_dcd_A[33:31] == XM_dcd_A[27:25]))
        XaDaR1_dependence_temp = 1'b1;
    else
        XaDaR1_dependence_temp = 1'b0;

    if ((DX_dcd_A[23]) && (XM_dcd_A[22]) && (DX_dcd_A[30:28] == XM_dcd_A[27:25]) && (~DX_dcd_A[18]))
        XaDaR2_dependence_temp = 1'b1;
    else
        XaDaR2_dependence_temp = 1'b0;

    if ((DX_dcd_A[15:12]==4'b0) && (DX_dcd_A[15:0] != 16'b0) && (XM_dcd_A[21] == 1))
        XaDaBr_dependence_temp = 1'b1;
    else
        XaDaBr_dependence_temp = 1'b0;

    if (XM_dcd_A[19] && ((XaDaR1_dependence_temp && ~XbDaR1_dependence_temp) || (XaDaR2_dependence_temp && ~XbDaR2_dependence_temp) || (XaDaBr_dependence_temp && ~XbDaBr_dependence_temp)) && ~branch_taken)
        LTU_XaDa_temp = 1'b1;
    else
    LTU_XaDa_temp = 1'b0;
    end
      
    always @(*) begin
    if ((DX_dcd_A[27:25] == DX_dcd_B[33:31]) && DX_dcd_A[22] == 1 && DX_dcd_B[24] == 1)
        DaDbR1_dependence = 1;
    else
        DaDbR1_dependence = 0;
    
    if ((DX_dcd_A[27:25] == DX_dcd_B[30:28]) && DX_dcd_A[22] == 1 && DX_dcd_B[23] == 1 && DX_dcd_B[18] == 0)
        DaDbR2_dependence = 1;
    else
        DaDbR2_dependence = 0;
    
    if ((DX_dcd_B[15:12] == 4'b0) && (DX_dcd_B[15:0] != 16'b0) && (DX_dcd_A[21] == 1))
        DaDbBr_dependence = 1;
    else
        DaDbBr_dependence = 0;
    
    if ((DX_dcd_A[18] | DX_dcd_A[19]) && (DX_dcd_B[18] | DX_dcd_B[19]))
        DaDbMem_dependence = 1;
    else
        DaDbMem_dependence = 0;
    
    if ((~LTU_XbDa && ~LTU_XaDa) && (DaDbR1_dependence || DaDbR2_dependence || DaDbBr_dependence || DaDbMem_dependence) && ~branch_taken)
        decode_dependence = 1;
    else
        decode_dependence = 0;

    if ((DX_dcd_B[24]) && (XM_dcd_B[22]) && (DX_dcd_B[33:31] == XM_dcd_B[27:25]))
        XbDbR1_dependence = 1;
    else
        XbDbR1_dependence = 0;

    if ((DX_dcd_B[23]) && (XM_dcd_B[22]) && (DX_dcd_B[30:28] == XM_dcd_B[27:25]) && (~DX_dcd_B[18]))
        XbDbR2_dependence = 1;
    else
        XbDbR2_dependence = 0;

    if (DX_dcd_B[15:12] == 4'b0 && (DX_dcd_B[15:0] != 16'b0) && (XM_dcd_B[21] == 1))
        XbDbBr_dependence = 1;
    else
        XbDbBr_dependence = 0;

    if (~LTU_XbDa && ~LTU_XaDa && ~decode_dependence && XM_dcd_B[19] && (XbDbR1_dependence && ~DaDbR1_dependence || XbDbR2_dependence && ~DaDbR2_dependence || XbDbBr_dependence && ~DaDbBr_dependence) && ~branch_taken)
        LTU_B_XbDb = 1;
    else
        LTU_B_XbDb = 0;
    end

   function reg XaDbR1_dependence_func;
   input [33:0] DX_dcd_B;
   input [27:0] XM_dcd_A;
   begin
      if ((DX_dcd_B[24]) && (XM_dcd_A[22]) && (DX_dcd_B[33:31] == XM_dcd_A[27:25]))
         XaDbR1_dependence_func = 1;
      else
         XaDbR1_dependence_func = 0;
   end
   endfunction

   function reg XaDbR2_dependence_func;
   input [33:0] DX_dcd_B;
   input [27:0] XM_dcd_A;
   begin
      if ((DX_dcd_B[23]) && (XM_dcd_A[22]) && (DX_dcd_B[30:28] == XM_dcd_A[27:25]) && (~DX_dcd_B[18]))
         XaDbR2_dependence_func = 1;
      else
         XaDbR2_dependence_func = 0;
   end
   endfunction

   function reg XaDbBr_dependence_func;
   input [33:0] DX_dcd_B;
   input [27:0] XM_dcd_A;
   begin
      if ((DX_dcd_B[15:12]==4'b0) && (DX_dcd_B[15:0] != 16'b0) && (XM_dcd_A[21] == 1))
         XaDbBr_dependence_func = 1;
      else
         XaDbBr_dependence_func = 0;
   end
   endfunction

   assign XaDbR1_dependence = XaDbR1_dependence_func(DX_dcd_B, XM_dcd_A);
   assign XaDbR2_dependence = XaDbR2_dependence_func(DX_dcd_B, XM_dcd_A);
   assign XaDbBr_dependence = XaDbBr_dependence_func(DX_dcd_B, XM_dcd_A);

   reg LTU_XaDa_B_cond1, LTU_XaDa_B_cond2, LTU_XaDa_B_cond3;

   always @(*) begin
   if (~LTU_XbDa && ~LTU_XaDa && ~decode_dependence)
      LTU_XaDa_B_cond1 = 1;
   else
      LTU_XaDa_B_cond1 = 0;
    end

   always @(*) begin
   if (XM_dcd_A[19] && (XaDbR1_dependence || XaDbR2_dependence || XaDbBr_dependence))
      LTU_XaDa_B_cond2 = 1;
   else
      LTU_XaDa_B_cond2 = 0;
   end

   always @(*) begin
   if (~XbDbR1_dependence && ~XbDbR2_dependence && ~DaDbR1_dependence && ~XbDbBr_dependence && ~DaDbBr_dependence)
      LTU_XaDa_B_cond3 = 1;
   else
      LTU_XaDa_B_cond3 = 0;
   end
   //branch
   wire branch_taken;
   assign LTU_XaDa_B = LTU_XaDa_B_cond1 && LTU_XaDa_B_cond2 && LTU_XaDa_B_cond3 && ~branch_taken;
   wire loadToUse_XaDa_LTU, loadToUse_XbDa_LTU;
   assign loadToUse_XaDa_LTU = LTU_XaDa;
   assign loadToUse_XbDa_LTU = LTU_XbDa;
   wire branch_taken_X_br_toc_A, branch_taken_X_br_toc_B;
   assign branch_taken_X_br_toc_A = X_br_toc_A;
   assign branch_taken_X_br_toc_B = X_br_toc_B;
   assign loadToUse = loadToUse_XaDa_LTU | loadToUse_XbDa_LTU;
   assign branch_taken = branch_taken_X_br_toc_A | branch_taken_X_br_toc_B;
   wire [1:0] branch_taken_cond_A, loadToUse_cond_A;
   assign branch_taken_cond_A = branch_taken ? 2'd2 : 2'd0;
   assign loadToUse_cond_A = (loadToUse == 1) ? 2'd3 : D_stall_out_A;
   assign D_regstall_in_A = branch_taken_cond_A;
   assign DX_stall_A = branch_taken ? branch_taken_cond_A : loadToUse_cond_A;
   wire [15:0] stgD_IR_zero_A = {16{1'b0}};
   assign stgD_IR_in_A = branch_taken ? stgD_IR_zero_A : i_cur_insn_A;

   wire [33:0] X_IR_zero_A = {34{1'b0}};
   assign X_IR_in_A = (branch_taken | loadToUse) ? X_IR_zero_A : DX_dcd_A;
   assign LTU_B = LTU_XaDa_B | LTU_B_XbDb;
   assign scl_stall_B = loadToUse | decode_dependence;
   assign pipe_switch = decode_dependence | LTU_B;
   
   reg [1:0] stgD_rstall_in_B_reg;
   reg [1:0] DX_stall_B_reg;
   reg [15:0] stgD_IR_in_B_reg;
   reg [33:0] X_IR_in_B_reg;
   reg [33:0] M_IR_in_B_reg;
   reg [2:0] XM_stallc_B;

   always @(*) begin
   if (branch_taken) 
      stgD_rstall_in_B_reg = 2'd2;
   else
      stgD_rstall_in_B_reg = 2'd0;

   if (branch_taken)
      DX_stall_B_reg = 2'd2;
   else if (scl_stall_B == 1)
      DX_stall_B_reg = 2'd1;
   else if (LTU_B == 1)
      DX_stall_B_reg = 2'd3;
   else
      DX_stall_B_reg = D_stall_out_B;

   if (X_br_toc_A == 1)
      XM_stallc_B = 2'd2;
   else
      XM_stallc_B = XM_stall_B;

   if (branch_taken == 1)
      stgD_IR_in_B_reg = {16{1'b0}};
   else
      stgD_IR_in_B_reg = i_cur_insn_B;

   if ((branch_taken | LTU_B | scl_stall_B) == 1)
      X_IR_in_B_reg = {34{1'b0}};
   else
      X_IR_in_B_reg = DX_dcd_B;

   if (X_br_toc_A == 1)
      M_IR_in_B_reg = {34{1'b0}};
   else
      M_IR_in_B_reg = XM_dcd_B;
   end

    assign stgD_rstall_in_B = stgD_rstall_in_B_reg;
    assign DX_stall_B = DX_stall_B_reg;
    assign stgD_IR_in_B = stgD_IR_in_B_reg;
    assign X_IR_in_B = X_IR_in_B_reg;
    assign M_IR_in_B = M_IR_in_B_reg;

   always @(*) begin
    if ((XM_dcd_B[33:31] == MW_dcd_B[27:25]) && (MW_dcd_B[22] == 1))
        AluBP_rs_B = M_out_B;
    else if ((XM_dcd_B[33:31] == MW_dcd_A_A[27:25]) && (MW_dcd_A_A[22] == 1))
        AluBP_rs_B = M_out_A;
    else if ((XM_dcd_B[33:31] == W_dcd_B[27:25]) && W_dcd_B[22] == 1)
        AluBP_rs_B = W_result_B;
    else if ((XM_dcd_B[33:31] == W_dcd_A[27:25]) && W_dcd_A[22] == 1)
        AluBP_rs_B = W_result_A;
    else
        AluBP_rs_B = X_rs_data_B;
    end

    always @(*) begin
    if ((XM_dcd_B[30:28] == MW_dcd_B[27:25]) && (MW_dcd_B[22] == 1))
        AluBP_rt_B = M_out_B;
    else if ((XM_dcd_B[30:28] == MW_dcd_A_A[27:25]) && (MW_dcd_A_A[22] == 1))
        AluBP_rt_B = M_out_A;
    else if ((XM_dcd_B[30:28] == W_dcd_B[27:25]) && W_dcd_B[22] == 1)
        AluBP_rt_B = W_result_B;
    else if ((XM_dcd_B[30:28] == W_dcd_A[27:25]) && W_dcd_A[22] == 1)
        AluBP_rt_B = W_result_A;
    else
        AluBP_rt_B = X_rt_data_B;
    end


   wire [15:0] M_in_B_sel, W_rNZP_in_B_sel, W_result_B_sel, W_rDmemData_in_B_sel, dmem_addr_B_sel;
   //nzp
   assign M_in_B_sel = (XM_dcd_B[16] == 1) ? DX_pc_A : alu_out_B;
   assign W_rNZP_in_B_sel = (MW_dcd_B[19] == 1) ? nzp_new_bs_ld_B : MW_nzp_bits_B;
   assign W_result_B_sel = (W_dcd_B[19] == 1) ? W_rD_out_B : W_r0_out_B;
   assign W_rDmemData_in_B_sel = (MW_dcd_B[19] == 1) ? i_cur_dmem_data : (MW_dcd_B[18] == 1) ? 16'b1 : 16'b0;
   assign dmem_addr_B_sel = (MW_dcd_B[19] == 1) || (MW_dcd_B[18] == 1) ? M_out_B : 16'b0;

   assign M_in_B = M_in_B_sel;
   assign W_rNZP_in_B = W_rNZP_in_B_sel;
   assign W_result_B = W_result_B_sel;
   assign W_rDmemData_in_B = W_rDmemData_in_B_sel;
   assign dmem_addr_B = dmem_addr_B_sel;

   wire [2:0] nzp_new_bits_A, final_nap_bits_B, nzp_reg_out, nzp_new_alu_A, nzp_new_bits_ld_A, nzp_new_t_A, nzp_new_bs_A, bu_nzp_ad_A;
   wire bu_nzp_rd_A, X_br_toc_A;
   wire bu_nzp_rd_B, X_br_toc_B;
   wire [2:0] nzp_new_bits_alu_B, nzp_new_bs_ld_B, nzp_new_bits_alu_t_B, nzp_newbs_B, bu_nzp_ad_B;
   
   localparam SIGNED_GT_0 = 3'b001;
   localparam EQ_0 = 3'b010;
   localparam SIGNED_LT_0 = 3'b100;
   localparam NZP_CONDITION = 4'b1111;
   localparam NZP_POSITIVE = 3'b001;
   localparam NZP_ZERO = 3'b010;
   localparam NZP_NEGATIVE = 3'b100;

   assign nzp_new_alu_A = ($signed(alu_out_A) > 0) ? SIGNED_GT_0 : (alu_out_A == 0) ? EQ_0 : SIGNED_LT_0;
   assign nzp_new_bits_ld_A = ($signed(i_cur_dmem_data) > 0) ? SIGNED_GT_0 : (i_cur_dmem_data == 0) ? EQ_0 : SIGNED_LT_0;
   assign nzp_new_t_A = ($signed(X_pc_out_A) > 0) ? SIGNED_GT_0 : (X_pc_out_A == 0) ? EQ_0 : SIGNED_LT_0;
   assign nzp_new_bs_A = (XM_dcd_A[15:12] == NZP_CONDITION) ? nzp_new_t_A :
                        ((MW_dcd_A_A[19] == 1) && (XM_stall_A == 2'd3)) ? nzp_new_bits_ld_A :nzp_new_alu_A;

   assign nzp_new_bits_alu_B = ($signed(alu_out_B) > 0) ? NZP_POSITIVE : (alu_out_B == 0) ? NZP_ZERO : NZP_NEGATIVE;  
   assign nzp_new_bs_ld_B = ($signed(i_cur_dmem_data) > 0) ? NZP_POSITIVE :(i_cur_dmem_data == 0) ? NZP_ZERO : NZP_NEGATIVE;
   assign nzp_new_bits_alu_t_B = ($signed(X_pc_out_B) > 0) ? NZP_POSITIVE : (X_pc_out_B == 0) ? NZP_ZERO : NZP_NEGATIVE;
   assign nzp_newbs_B = (XM_dcd_B[15:12] == 4'b1111) ? nzp_new_bits_alu_t_B :  
                            ((MW_dcd_B[19]==1) && (XM_stallc_B==2'd3) ) ? nzp_new_bs_ld_B : nzp_new_bits_alu_B;

   assign nzp_new_bits_A = (XM_dcd_A[21] == 1) ? nzp_new_bs_A : nzp_reg_out;
   assign bu_nzp_ad_A = nzp_new_bits_A & XM_dcd_A[11:9]; 
   assign bu_nzp_rd_A = |bu_nzp_ad_A;
   assign X_br_toc_A = (bu_nzp_rd_A & XM_dcd_A[17]) || XM_dcd_A[16]; 
   assign final_nap_bits_B = (X_br_toc_A == 1) ? nzp_new_bits_A: (XM_dcd_B[21] == 1) ? nzp_newbs_B : 
                                 (XM_dcd_A[21] == 1) ? nzp_new_bs_A : nzp_reg_out;
   assign bu_nzp_ad_B = final_nap_bits_B & XM_dcd_B[11:9]; 
   assign bu_nzp_rd_B = |bu_nzp_ad_B;
   assign X_br_toc_B = (~X_br_toc_A) && ((bu_nzp_rd_B & XM_dcd_B[17]) || XM_dcd_B[16]); 


   // tests
   assign o_cur_pc = Fout_pc;
   assign test_cur_pc_A = W_pc_out_A; 
   assign test_cur_pc_B = W_pc_out_B;                
   assign test_cur_insn_A = W_dcd_A[15:0];
   assign test_cur_insn_B = W_dcd_B[15:0];
   assign test_regfile_we_A = W_dcd_A[22];
   assign test_regfile_we_B = W_dcd_B[22];
   assign test_regfile_wsel_A = W_dcd_A[27:25];
   assign test_regfile_wsel_B = W_dcd_B[27:25];
   assign test_regfile_data_A = W_result_A;
   assign test_regfile_data_B = W_result_B;  
   assign test_nzp_we_A = W_dcd_A[21];
   assign test_nzp_we_B = W_dcd_B[21];
   assign o_dmem_we = W_dcd_A[18] | W_dcd_B[18];
   assign o_dmem_towrite = (W_dcd_A[18] == 1) ? W_result_A : W_result_B;
   assign o_dmem_addr = ((MW_dcd_A_A[18] == 1) || (MW_dcd_A_A[18] == 1)) ? M_out_A :  
                        ((MW_dcd_B[18] == 1) || (MW_dcd_B[18] == 1)) ? M_out_B :16'b0;         
   
   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    */
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
      // run it for that many nanoseconds, then set
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
endmodule
