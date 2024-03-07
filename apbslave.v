//
// Verilog Module HT1_lib.apbslave
//
// Created:
//          by - NadavHugi.UNKNOWN (DESKTOP-9P9608N)
//          at - 15:04:10 02/03/2024
//
// using Mentor Graphics HDL Designer(TM) 2021.1 Built on 14 Jan 2021 at 15:11:42
//

`timescale 1ns/1ps

// These are text replacements for Readability and versatility.
`define ADDR_CONTROL_REG 5'b00000 
`define ADDR_OP_A        5'b00100
`define ADDR_OP_B        5'b01000
`define ADDR_RES_FLAGS   5'b01100
`define ADDR_SP_1 		 5'b10000
`define ADDR_SP_2 		 5'b10100
`define ADDR_SP_3 		 5'b11000
`define ADDR_SP_4 		 5'b11100

module apbslave# (
    parameter DW = 8, // Size of each piece of data.
    parameter BW = 32, // Bus Width.
	parameter ADDR_W = 16, // Address Width.
	parameter SP_NTARGETS = 4, 
    parameter MAX_DIM = BW/DW,
    parameter MAX_MAX_DIM = 4, // Maximum dimension.
    parameter Elements_Num = MAX_DIM*MAX_DIM // How many elements in total.
)
(
	input wire  clk_i, 
	input wire  reset_ni, 
	input wire  psel_i, 
	input wire  penable_i, 
	input wire  pwrite_i, // Allows us to write data.
	input wire  [MAX_DIM-1:0] pstrb_i, // Chooses specific data bits.
	input wire  [BW-1:0] pwdata_i, // The data we write.
	input wire  [ADDR_W-1:0] paddr_i, // The address where we write data.
	input wire  [Elements_Num-1:0] of_i, // Overflow bis.
	input wire  done_i, // Tells us when we're done.
	input wire  [BW*Elements_Num-1:0] result_i, // The result of our work.
	output wire [BW*MAX_DIM-1:0] operand_A_o, // Output for operand A.
	output wire [BW*MAX_DIM-1:0] operand_B_o, // Output for operand B.
	output reg  [BW*Elements_Num-1:0] operand_C_o, // Output for operand C.
	output wire [15:0] control_reg_o, // Control register output.
	output reg  pready_o, // Tells us when ready.
	output reg  pslverr_o, // Tells us if there's an error.
	output reg  [BW-1:0] prdata_o, // Data output.
	output reg  busy_o // Tells us if it's busy.
);
    
	localparam SP_ADDR_WIDTH = MAX_DIM > 2 ? 4 : 2; 
	localparam OP_ADDR_WIDTH = MAX_DIM > 2 ? 2 : 1; 

   

	reg [1:0] current_state;
	reg [1:0] STATE_IDLE;
	reg [1:0] STATE_WRITE;
	reg [1:0] STATE_READ;
	reg [1:0] STATE_OPERATING;
	reg [BW*Elements_Num-1:0] result_reg;
	reg [15:0] control_reg;
	reg [Elements_Num-1:0] flags_reg;
 	wire start_bit_i;
	wire [BW - 1:0] result_mat [Elements_Num-1:0];
	wire [OP_ADDR_WIDTH-1:0] op_addr;

	reg [BW-1:0] data_in_op_a;
	reg [BW-1:0] data_in_op_b;
	wire [BW*MAX_DIM-1:0] op_a_mat_sig;
	wire [BW*MAX_DIM-1:0] op_b_mat_sig;
	wire [BW-1:0] op_a_sig_row_o;
	wire [BW-1:0] op_b_sig_row_o;
	reg [BW-1:0] sp_data_in;
	reg [SP_ADDR_WIDTH-1:0] sp_addr;
	wire [BW*Elements_Num-1:0] sp_op;
	wire unused; // Declare the wire
	wire [BW-1:0] sp_data_o;
	reg op_en_a_i;
	reg op_en_b_i;
	reg op_en_sp_i;

 localparam DIM_IDX = $clog2(MAX_DIM);
 
	assign op_addr = paddr_i[OP_ADDR_WIDTH - 1 + 5:5];
	assign start_bit_i = control_reg[0]; 
	assign control_reg_o = control_reg; 
	assign operand_A_o = op_a_mat_sig;
	assign operand_B_o = op_b_mat_sig;
	assign unused = 1'b0; // Assign a default value to the wire
	integer count_w;
	integer i;

generate
    if(MAX_DIM < MAX_MAX_DIM) begin: GEN_LABEL
        // Instantiate operand_a and operand_b with the unused wire connected to addr
        reg_file_op #(.DW(DW), .MAX_DIM(MAX_DIM)) operand_a (
            .clk_i(clk_i), 
            .reset_ni(reset_ni),
            .addr({unused, op_addr}), 
            .data_i(data_in_op_a), 
            .ena_i(op_en_a_i),  
            .pstrb_i(pstrb_i), 
            .row_bus_o(op_a_sig_row_o), 
            .mat_o(op_a_mat_sig) 
        );

        reg_file_op #(.DW(DW), .MAX_DIM(MAX_DIM)) operand_b (
            .clk_i(clk_i),
            .reset_ni(reset_ni),	
            .addr({unused, op_addr}), 
            .data_i(data_in_op_b), 
            .ena_i(op_en_b_i), 
            .pstrb_i(pstrb_i),			
            .row_bus_o(op_b_sig_row_o),
            .mat_o(op_b_mat_sig)
        );
    end else begin
        // Instantiate operand_a and operand_b normally
        reg_file_op #(.DW(DW), .MAX_DIM(MAX_DIM)) operand_a (
            .clk_i(clk_i), 
            .reset_ni(reset_ni),
            .addr(op_addr), 
            .data_i(data_in_op_a), 
            .ena_i(op_en_a_i),  
            .pstrb_i(pstrb_i), 
            .row_bus_o(op_a_sig_row_o), 
            .mat_o(op_a_mat_sig) 
        );

        reg_file_op #(.DW(DW), .MAX_DIM(MAX_DIM)) operand_b (
            .clk_i(clk_i),
            .reset_ni(reset_ni),	
            .addr(op_addr), 
            .data_i(data_in_op_b), 
            .ena_i(op_en_b_i), 
            .pstrb_i(pstrb_i),			
            .row_bus_o(op_b_sig_row_o),
            .mat_o(op_b_mat_sig)
        );
    end
endgenerate

	scrachpad #(.BW(BW), .MAX_DIM(MAX_DIM),.SPN(SP_NTARGETS),.ADDR_W(SP_ADDR_WIDTH)) sp (
			.clk_i(clk_i),
			.reset_ni(reset_ni),
			.addr(sp_addr),
			.bus_mat_sel(paddr_i[4:0]),
			.data_i(sp_data_in), 
			.ena_i(op_en_sp_i),
			.mat_to_read(control_reg[5:4]),
			.element_w_sel(control_reg[3:2]),
			.row_sp_o(sp_data_o),
			.mat_sp_o(sp_op)
	);
        

	// This part of the code decides what to do based on the current state.
	always @(negedge reset_ni or posedge clk_i) begin : FSM
		if (!reset_ni) begin
			current_state <= STATE_IDLE;
			prdata_o <= 1'b0;
			pready_o <= 1'b0;
			pslverr_o <= 1'b0;
			result_reg <= 0;
			STATE_IDLE <= 2'b00;
        	STATE_WRITE <= 2'b01;
        	STATE_READ <= 2'b10;
        	STATE_OPERATING <= 2'b11;

  		  
		end	
		else begin				
			case (current_state)
				STATE_IDLE : begin
        			op_en_a_i <= 1'b0;
					op_en_b_i <= 1'b0;
					op_en_sp_i<= 1'b0;	
					prdata_o  <= 1'b0;
					pready_o  <= 1'b0;
					pslverr_o <= 1'b0;
					
					if (penable_i && psel_i && !start_bit_i) begin
						if (pwrite_i) begin
							current_state <= STATE_WRITE;
						end
						else begin
							current_state <= STATE_READ;
						end
					end

					else if (start_bit_i) begin
						busy_o  <= 1;
						count_w <= 0;
						current_state <= STATE_OPERATING;
					end
				end


				STATE_READ : begin
					if (!pwrite_i) begin 
						    pready_o <= 1;				  
						case (paddr_i[4:0])
							 `ADDR_CONTROL_REG: begin
								prdata_o[15:0] <= control_reg;
						   end
							`ADDR_OP_A: begin
								prdata_o <= op_a_sig_row_o;
							 end
							`ADDR_OP_B: begin
								prdata_o <= op_b_sig_row_o;								
							 end
							`ADDR_RES_FLAGS: begin
								prdata_o[Elements_Num - 1:0] <= flags_reg;
							 end
							`ADDR_SP_1, `ADDR_SP_2, `ADDR_SP_3, `ADDR_SP_4: begin
								sp_addr  <= paddr_i[5 + SP_ADDR_WIDTH - 1:5];
								prdata_o <= sp_data_o;								
						  	end
						  	
						  default: begin
                // This part is just for practice.
                end
						 endcase
					end
					current_state <= STATE_IDLE;
				end
				
				
				STATE_WRITE : begin
					if (pwrite_i) begin
						pready_o <= 1; 
						case (paddr_i[4:0])
							`ADDR_CONTROL_REG: begin
								control_reg <= pwdata_i[15:0];
							end
							`ADDR_OP_A: begin
								op_en_a_i <= 1'b1;                          
								data_in_op_a <= pwdata_i;
							end
							`ADDR_OP_B: begin
								op_en_b_i <= 1'b1; 
								data_in_op_b <= pwdata_i;								
							end
							
							default: begin
              // This part is also just for practice.
              end
						endcase
						         
					end
					current_state <= STATE_IDLE;
				end
				
				STATE_OPERATING : begin
					// Decides what to do with the result.
					operand_C_o <= (control_reg[1] ? sp_op : {BW*Elements_Num{1'b0}}); 
					
					if (penable_i && psel_i) begin
					pslverr_o <= 1'b1;		// Tells us if there's an error.
					end
					
					result_reg <= result_i; // Stores the result.
					
					if (done_i) begin // Checks if we are done.
						if (count_w < Elements_Num) begin
							op_en_sp_i <= 1'b1;
							sp_addr <= count_w;
						    sp_data_in <= result_reg[BW-1:0]; // Uses the lowest part of the result.
                            result_reg <= result_reg >> BW; // Prepares the next part of the result.
                            count_w <= count_w + 1;
						    end
						else begin
							// Updates flags and resets control for next operation.
							flags_reg <= of_i;
							control_reg[0] <= 1'b0;
							busy_o <= 1'b0;
							current_state  <= STATE_IDLE;
						end
					end				
				end	
				default: begin
               // Again, this part is just for practice.
                end
			endcase		
		end
	end					
	
	
endmodule
