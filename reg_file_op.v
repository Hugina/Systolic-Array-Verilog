/*
 Verilog Module HT1_lib.reg_file_op

 Created:
          by - NadavHugi.UNKNOWN (DESKTOP-9P9608N)
          at - 16:04:45 02/03/2024

 using Mentor Graphics HDL Designer(TM) 2021.1 Built on 14 Jan 2021 at 15:11:42
*/

`resetall
`timescale 1ns/10ps

module reg_file_op#(
    parameter DW = 8, // Data width for matrix elements
    parameter BW = 32, // Bus width for accumulators and outputs
    parameter MAX_DIM = BW/DW, // Maximum dimension of the matrix
    parameter Elements_Num = MAX_DIM*MAX_DIM // Total number of elements in the matrix
)
(
    //----------------------Inputs and Outputs--------------------
	input wire clk_i,
	input wire reset_ni,
	input wire ena_i,
	input wire [DW*MAX_DIM - 1:0] data_i,// Input data for the matrix.
	input wire [1:0] addr, // Address input to select a specific row in the matrix
	input wire [MAX_DIM-1:0] pstrb_i, // Byte enable signals for partial updates
	output wire [DW*Elements_Num - 1:0] mat_o, // Output of the entire matrix
	output wire [DW*MAX_DIM - 1:0] row_bus_o // Output of a selected row from the matrix
 ); 

	reg [DW*MAX_DIM - 1:0] mem [MAX_DIM - 1:0];// Memory storage for matrix elements, organized as rows
	assign row_bus_o = mem[addr];// Provides the selected row based on the input address
	integer j;
	genvar i;
	generate for (i = 0; i < MAX_DIM; i = i + 1) begin : put_mat_lines_to_out // This loop unpacks the matrix rows into a flat output
				assign mat_o[(i+1)*DW*MAX_DIM-1 -: DW*MAX_DIM] = mem[i]; 
			end
	endgenerate
  
  genvar k; // This block handles the updating of matrix elements based on the enable signal and byte enables
	generate		for(k = 0; k < MAX_DIM; k = k + 1) begin: choos_exact_element_in_row
      always @(posedge clk_i) begin : reset_mem
        if (!reset_ni) begin
            for (j = 0; j < MAX_DIM; j = j + 1) begin
              mem[j] <= 0;  
            end 
        end        
        else begin                   
    				  if(ena_i) begin
    					 mem[addr][(k+1)*DW-1 : k*DW] <= pstrb_i[k]? (data_i[(k+1)*DW-1 -: DW]) : (mem[addr][(k+1)*DW-1 : k*DW]);
    				  end
				end
			end
		end
	endgenerate
endmodule