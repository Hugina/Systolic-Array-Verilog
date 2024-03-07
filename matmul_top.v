//
// Verilog Module HT1_lib.matmul_top
//
// Created:
//          by - NadavHugi.UNKNOWN (DESKTOP-9P9608N)
//          at - 18:04:18 02/03/2024
//
// using Mentor Graphics HDL Designer(TM) 2021.1 Built on 14 Jan 2021 at 15:11:42
//

`resetall
`timescale 1ns/10ps

// This module is the top-level design for a matrix multiplication system
// It combines different parts like APB slave interface, matrix padding, and calculation.
module matmul_top#(
    parameter DW = 8, // Bits per  element.
    parameter BW = 32, // Width of the accumulators and output bus.
	parameter ADDR_W = 16, // Width of the address bus for APB.
	parameter SP_NTARGETS = 4, // Number of scratchpad targets.
    parameter MAX_DIM = BW/DW, 
	parameter Elements_Num = MAX_DIM*MAX_DIM 
)(
    // Inputs and outputs for the module.
	input wire  clk_i, 
	input wire  reset_ni, // Reset signal, active low.
	input wire  psel_i, // Select signal for APB bus.
	input wire  penable_i,// Enable signal for APB bus.
	input wire  pwrite_i,// Write signal for APB bus.
	input wire  [MAX_DIM-1:0] pstrb_i, // Byte strobe for APB
	input wire  [BW-1:0] pwdata_i, // Write data for APB
	input wire  [ADDR_W-1:0] paddr_i, // Address for APB
	output wire  pready_o, // Ready signal for APB
	output wire  pslverr_o, // Error signal for APB.
	output wire  [BW-1:0] prdata_o, // Read data for APB.
	output wire  busy_o // Indicates system is busy.
);

  wire [BW*MAX_DIM-1:0] operand_a; 
  wire [BW*MAX_DIM-1:0] operand_b;
  wire [BW*Elements_Num-1:0] operand_c;
  wire [(MAX_DIM*DW)-1:0] vec_a;
  wire [(MAX_DIM*DW)-1:0] vec_b;
  wire [BW*Elements_Num-1:0] op_c_to_sum;
  wire  [Elements_Num-1:0] of; 
  wire  done_top;
  wire [BW*Elements_Num-1:0] result;
  wire [15:0] control_reg; 

  // APB slave module to interface with APB bus.
  apbslave #(
          .DW(DW),
         .BW(BW),
  	      .ADDR_W(ADDR_W),
  	      .SP_NTARGETS(SP_NTARGETS)
      )
      bus (
      .clk_i(clk_i),
      .reset_ni(reset_ni),
      .psel_i(psel_i),
      .penable_i(penable_i),
      .pwrite_i(pwrite_i),
      .pstrb_i(pstrb_i),
      .pwdata_i(pwdata_i),
      .paddr_i(paddr_i),
	  .pready_o(pready_o),
      .pslverr_o(pslverr_o),
      .prdata_o(prdata_o),
      .of_i(of),
      .done_i(done_top),
      .result_i(result),
      .operand_A_o(operand_a),
      .operand_B_o(operand_b),
      .operand_C_o(operand_c),
      .control_reg_o(control_reg),
      .busy_o(busy_o)
    );


  // Matrix padding module to prepare matrices A and B.
  mat_pad #(
          .DW(DW),
          .BW(BW)
      )
      padding (
      .clk_i(clk_i),
      .reset_ni(reset_ni),
      .start_bit_i(control_reg[0]),
      .mat_A(operand_a),
      .mat_B(operand_b),
      .mat_c_in(operand_c),
      .N_i(control_reg[9:8]),
      .K_i(control_reg[11:10]),
      .M_i(control_reg[13:12]),
      .vec_a_o(vec_a), 
      .vec_b_o(vec_b),
      .c_flat_out(op_c_to_sum),
      .done_sig_o(done_top)
  );


  // Matrix calculation module to perform the actual multiplication.
  matmul_calc #(
          .DW(DW),
          .BW(BW)
      )
      calc (
      .clk_i(clk_i),
      .reset_ni(reset_ni),
      .start_bit_i(control_reg[0]),
      .in_a(vec_a),
      .in_b(vec_b),
      .in_c(op_c_to_sum),
      .out_res_mat(result),
      .out_of_mat(of)
  );


endmodule
