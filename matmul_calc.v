//
// Verilog Module HT1_matmul_calc
//
// Created:
//          by - NadavHugi.UNKNOWN (DESKTOP-9P9608N)
//          at - 15:04:10 02/03/2024
//
// using Mentor Graphics HDL Designer(TM) 2021.1 Built on 14 Jan 2021 at 15:11:42
//

`resetall
`timescale 1ns/10ps
module matmul_calc #(
    parameter DW = 8, // Each element's bit width
    parameter BW = 32, 
    parameter MAX_DIM = BW/DW, // The max number of rows/columns
    parameter Elements_Num = MAX_DIM*MAX_DIM // The total number of elements in a matrix
)
(
    // Inputs and outputs:
    input wire clk_i, 
    input wire reset_ni, // signal to reset the module, active when low.
	input  start_bit_i, // signal to start the matrix multiplication 
    input wire [MAX_DIM*DW-1:0] in_a, // vector representation of matrix A's elements
    input wire [MAX_DIM*DW-1:0] in_b, // vector representation of matrix B's elements
    input wire [Elements_Num*BW-1:0] in_c, // vector representation of an additional matrix to be added to the result
    output wire [Elements_Num-1:0] out_of_mat, // Flags indicating overflow for each element of the result matrix.
    output [Elements_Num*BW-1:0] out_res_mat // vector representation of the result matrix.
);

    // Internal signals for connecting processing elements=
    wire [BW-1:0] cell_accumulator [Elements_Num-1:0]; //  sum for each matrix cell.
    wire [DW-1:0] cell_a [Elements_Num-1:0]; //  values for matrix A elements.
    wire [DW-1:0] cell_b [Elements_Num-1:0]; //  values for matrix B elements.
    wire [Elements_Num-1:0] of_pes; // Flags indicating overflows from PEs.
    wire [Elements_Num-1:0] of_mat_c; // Flags for overflows when adding values from C
    assign out_of_mat = of_pes | of_mat_c; // Combine overflow flags from all sources.

    // Calculating inputs for each PE:
    wire [DW-1:0] pe_input_a [Elements_Num-1:0];
    wire [DW-1:0] pe_input_b [Elements_Num-1:0];

    genvar row,i;
    generate for (row = 0; row < MAX_DIM; row = row +1) begin: GEN_ROWS_pe_input
          genvar col;
            for (col = 0; col < MAX_DIM; col = col+1) begin: GEN_COLS_pe_input
                // Determine what each PE takes as input based on its position
              assign   pe_input_a[row*MAX_DIM + col] = (col == 0) ? in_a[(row+1)*DW-1 : row*DW] : cell_a[row*MAX_DIM + col - 1];
              assign   pe_input_b[row*MAX_DIM + col] = (row == 0) ? in_b[(col+1)*DW-1 : col*DW] : cell_b[col*MAX_DIM + row - 1];
            end
        end
    endgenerate

    // Setting up the PEs to do the calculations:
    generate for (row = 0; row < MAX_DIM; row = row +1) begin: GEN_ROWS
      genvar col;
            for (col = 0; col < MAX_DIM; col = col+1) begin:GEN_ROWS
                pe #(.DW(DW), .BW(BW)) pe_inst (
                    .clk_i(clk_i),
                    .reset_ni(reset_ni),
					.start_bit_i(start_bit_i),
                    .input_a(pe_input_a[row*MAX_DIM + col]),
                    .input_b(pe_input_b[row*MAX_DIM + col]),
                    .out_a(cell_a[row*MAX_DIM + col]),
                    .out_b(cell_b[col*MAX_DIM + row]),
                    .out_accumulator(cell_accumulator[row*MAX_DIM + col]),
                    .out_of(of_pes[row*MAX_DIM + col])
                );
            end
        end
    endgenerate

    // Adding input matrix C to the PEs' results and checking for overflow:
    generate
        for (i = 0; i < Elements_Num; i=i+1) begin: result
            // Perform the addition and capture any overflow.
            assign {of_mat_c[i], out_res_mat[(i+1)*BW-1 : i*BW]} = cell_accumulator[i] + in_c[(i+1)*BW-1 : i*BW];
        end
    endgenerate
endmodule
