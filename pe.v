	//
// Verilog Module lab1_lib.PE
//
// Created:
//          by - pelegse.UNKNOWN (SHOHAM)
//          at - 14:57:07 01/24/2024
//
// using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
//


`resetall
`timescale 1ns/10ps

module pe#(
parameter DW = 8,
parameter BW = 32
)
(
    input   				    clk_i,
    input   				    reset_ni,
	input  						start_bit_i, 

    input 	   [DW -1:0] 		input_a,
    input 	   [DW -1:0] 		input_b,
    output reg [DW-1:0] out_a,
    output reg [DW-1:0] out_b, 
    output reg [BW -1:0]		out_accumulator,
    output reg 					out_of
);

// Temporary variables to hold in module information
wire [2*DW -1:0] mult_result;
reg  [BW-1:0]    accum_sig;
reg              of_sig;
assign           mult_result = (input_a * input_b);

always @(posedge clk_i , negedge reset_ni) begin : seq_mul_oper
    if (!reset_ni) begin
        // Reset the accumulator to 0
        of_sig    		<= 0;
        accum_sig 		<= 0;   
        out_a     		<= 0;
        out_b     		<= 0;
		out_of    		<= 0;
		out_accumulator <= 0;
	end else if (start_bit_i) begin
	    // Multiply the inputs
        {of_sig,accum_sig} <= accum_sig + mult_result;                        
        out_a              <= input_a;
        out_b              <= input_b;
        out_accumulator    <= accum_sig;
        out_of             <= of_sig | out_of; 
    end else begin
	    of_sig    		<= 0;
        accum_sig 		<= 0;   
        out_a     		<= 0;
        out_b     		<= 0;
		out_of    		<= 0;
		out_accumulator <= 0;
             
    end
  end
endmodule