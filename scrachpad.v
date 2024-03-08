`resetall
`timescale 1ns/10ps

module scrachpad #(
    parameter DW = 8, // Data width for matrix elements
    parameter BW = 32, // Bus width for accumulators and outputs
    parameter MAX_DIM = BW/DW, 
	parameter SPN = 1,// Number of scratchpad sections
	parameter ADDR_W = 4,
    parameter Elements_Num = MAX_DIM*MAX_DIM // Total number of elements in the matrix
)(
    //----------------------Inputs and Outputs--------------------
	input wire clk_i,
	input wire reset_ni,
	input wire [ADDR_W-1:0] addr,// Address for reading/writing
	input wire [4:0] bus_mat_sel,// Selector signal for matrix operation
	input wire [BW - 1:0] data_i,// Data input for writing
	input wire ena_i,// Enable signal for write operation
	input wire [1:0] mat_to_read, // bus
	input wire [1:0] element_w_sel, // bus		
	output reg [BW*Elements_Num - 1:0] mat_sp_o, // Output of the entire matrix
	output reg [BW - 1:0] row_sp_o// Output of a specific row based on address
);
	
	reg [BW - 1:0] mem [(Elements_Num*SPN)*3 - 1:0]; // Memory storage for matrices// Memory storage for matrices
	wire [BW*Elements_Num - 1:0] flat_mat_sp [SPN - 1:0];
	genvar i,j;	
	integer q;
		// Generate flattened matrices for each scratchpad section.
	generate
		for (i = 0; i < SPN; i = i + 1) begin  : 	gen_i		
			for (j = 0; j < Elements_Num; j = j + 1) begin  : gen_j
				assign flat_mat_sp[i][(j+1)*BW-1 -: BW] = mem[i*Elements_Num + j]; 
			end	
		end		
	endgenerate	
	
	// Write data to the memory based on enable signal and selected section
	generate		
	  for(i = 0; i < SPN; i = i + 1) begin: write
      	 always @(posedge clk_i) begin : w_data
      	    if (!reset_ni) begin
              for (q = 0; q < MAX_DIM; q = q + 1) begin
                mem[q] <= 0;  // Clear memory on reset
              end 
            end        
            else begin 
          				if(ena_i) begin// Write data to the selected address and section.
          				  mem[i*Elements_Num + addr] <= {30'b0, element_w_sel} == i ? data_i: mem[i*Elements_Num + addr];
          				end
            end
     			 end
  		end
  endgenerate
  
// Output logic for reading from the scratchpad
    always @(posedge clk_i) begin : SP_output
		case(bus_mat_sel) // bus read
	        16: row_sp_o <= (SPN > 0) ? mem[addr] : 0;
            20: row_sp_o <= (SPN > 1) ? mem[1*Elements_Num + addr] : 0;
            24: row_sp_o <= (SPN > 2) ? mem[2*Elements_Num + addr] : 0;
            28: row_sp_o <= (SPN > 3) ? mem[3*Elements_Num + addr] : 0;
			default: row_sp_o <= 0;
		endcase	
		
        case(mat_to_read) // Select entire matrix based on read selector.
            0: mat_sp_o <= (SPN > 0) ? flat_mat_sp[0] : 0;
            1: mat_sp_o <= (SPN > 1) ? flat_mat_sp[1] : 0;
            2: mat_sp_o <= (SPN > 2) ? flat_mat_sp[2] : 0;
            3: mat_sp_o <= (SPN > 3) ? flat_mat_sp[3] : 0;
            default: mat_sp_o <= 0; // Default case if mat_to_read is out of bounds
        endcase
    end	
endmodule