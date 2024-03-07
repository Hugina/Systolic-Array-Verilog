
// Verilog Module lab1_lib Mat Pad
//
// Created:
//          by - pelegse.UNKNOWN (SHOHAM)
//          at - 14:57:07 01/24/2024
//
// using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
//

`resetall
`timescale 1ns / 10ps

module mat_pad (clk_i,reset_ni,start_bit_i,mat_A,mat_B,mat_c_in,N_i,K_i,M_i,vec_a_o,vec_b_o,c_flat_out,done_sig_o);
    parameter DW = 8; // Data width for matrix elements.
    parameter BW = 32; // Bus width for accumulators and outputs. Must be a multiple of DW.
    parameter [1:0] // pragma enum current_state_code gray
    STATE_DONE    = 2'b10,
     STATE_PADDING = 2'b01,
     STATE_START   = 2'b00;
    localparam MAX_DIM = BW / DW; // Maximum dimension of the matrix, derived from BW and DW.
    localparam Elements_Num = MAX_DIM * MAX_DIM; // Total number of elements in the matrix.
	
    input wire clk_i; // Clock input
    input wire reset_ni; // Active low reset input
    input wire start_bit_i;
    input wire [(Elements_Num*DW)-1:0] mat_A;
    input wire [(Elements_Num*DW)-1:0] mat_B;
    input wire [(BW*Elements_Num)-1:0] mat_c_in;
    input wire [1:0] N_i, K_i, M_i;
    output reg [(MAX_DIM*DW)-1:0] vec_a_o;
    output reg [(MAX_DIM*DW)-1:0] vec_b_o;
    output reg [(BW * MAX_DIM * MAX_DIM)-1:0] c_flat_out;
    output reg done_sig_o;

    //----------------------Internal wires-----------------------
    integer i, j, cycle_count; // Decoded Dimensions of the matrix for processing
    reg  [(Elements_Num*DW)-1:0] shifted_mat_A;
    reg  [(Elements_Num*DW)-1:0] shifted_mat_B;
    wire [(Elements_Num*DW)-1:0] mat_B_T;
    reg [DW-1:0] temp_a [MAX_DIM-1:0];
    reg [DW-1:0] temp_b [MAX_DIM-1:0];
    reg [1:0] current_state;
    reg [2:0] N,K,M;

    genvar row, col;
    // Generating the transpose of matrix B
    generate
        for (row = 0; row < MAX_DIM; row = row + 1) begin: row_loop
            for (col = 0; col < MAX_DIM; col = col + 1) begin: col_loop
               assign mat_B_T[(col*MAX_DIM+row+1)*DW-1 -: DW] = mat_B[(row*MAX_DIM+col+1)*DW-1 -: DW];
            end
        end
    endgenerate
  
    //---------------------------FSM------------------------------
    always @(posedge clk_i or negedge reset_ni) begin : FSM
        if (!reset_ni) begin
            // Reset logic
            vec_a_o <= 0;
            vec_b_o <= 0;
            shifted_mat_A <= 0;
            shifted_mat_B <= 0;
            done_sig_o <= 0;
            current_state <= STATE_START;
            cycle_count <= 0;
             // Resetting temporary storage for A and B
            for (i = 0; i < MAX_DIM; i = i + 1) begin
                temp_a[i] <= 0;
                temp_b[i] <= 0;
            end
            N <= 0;
            K <= 0;
            M <= 0;
        end 
        else begin
          // Operating based on the current state
            case (current_state)
                STATE_START: begin
                    if (start_bit_i) begin  // Begin operations, loading matrices and setting dimensions
                        shifted_mat_A <= mat_A;
                        shifted_mat_B <= mat_B_T;
                        current_state <= STATE_PADDING;
                        cycle_count <= 0;
                        done_sig_o <= 0;
                        N <= N_i + 1;
                        K <= K_i + 1;
                        M <= M_i + 1;
                    end
                end
                STATE_PADDING: begin
                /* Padding logic for matrices
                 This part involves  logic to handle matrix padding
                 based on the cycle count and matrix dimensions N, K, M
                 It dynamically adjusts the output matrices vec_a_o and vec_b_o
                 based on the input matrices and dimensions
                 We move bits around to make sure they line up just right
                Depending on how big N and M are, we do things a bit differently*/
                
                    if (cycle_count < (2*MAX_DIM)) begin      
                              case(N)
                              1: begin
                                  for (i = 0; i < 1; i = i + 1)
                                   begin
                                      if ((i <= cycle_count) && (cycle_count-i<1)) begin
                                        vec_a_o[(i+1)*DW-1 -: DW] <=  shifted_mat_A[((MAX_DIM-1)*i+1)*DW-1 -: DW];
                                      end 
                                      else 
                                      begin
                                        vec_a_o[(i+1)*DW-1 -: DW] <= 0;
                                      end
                                  end
                        
    
                              end
                              2:
                               begin
                                 for (i = 0; i < 2; i = i + 1) begin
                                      if ((i <= cycle_count) && (cycle_count-i<2)) begin
                                        vec_a_o[(i+1)*DW-1 -: DW] <=  shifted_mat_A[((MAX_DIM-1)*i+1)*DW-1 -: DW];
                                      end 
                                      else begin
                                        vec_a_o[(i+1)*DW-1 -: DW] <= 0;
                                      end
                                  end
                              end
                              3: begin
                                 for (i = 0; i < 3; i = i + 1) begin
                                      if ((i <= cycle_count) && (cycle_count-i<3)) begin
                                        vec_a_o[(i+1)*DW-1 -: DW] <=  shifted_mat_A[((MAX_DIM-1)*i+1)*DW-1 -: DW];
                                      end 
                                      else
                                       begin
                                        vec_a_o[(i+1)*DW-1 -: DW] <= 0;
                                      end
                                  end
                              end
                              4: 
                              begin
                                 for (i = 0; i < 4; i = i + 1) begin
                                      if ((i <= cycle_count) && (cycle_count-i<4)) begin
                                        vec_a_o[(i+1)*DW-1 -: DW] <=  shifted_mat_A[((MAX_DIM-1)*i+1)*DW-1 -: DW];
                                      end 
                                      else begin
                                        vec_a_o[(i+1)*DW-1 -: DW] <= 0;
                                      end
                                  end
                               end
                               
                              default: begin
                              // we made this is just for coding practice although it's not necessary
                              end
                          
                          endcase
                          
                          case(M)
                              1: begin
                                  for (j = 0; j < 1; j = j + 1) begin   
                                      if ((j <= cycle_count) && (cycle_count-j<K)) begin
                                          vec_b_o[(j+1)*DW-1 -: DW] <= shifted_mat_B[((MAX_DIM-1)*j+1)*DW-1 -: DW];
                                      end else begin
                                          vec_b_o[(j+1)*DW-1 -: DW] <= 0;
                                      end
                                  end  
    
                              end
                              2: begin
                                  for (j = 0; j < 2; j = j + 1) begin   
                                      if ((j <= cycle_count) && (cycle_count-j<K)) begin
                                          vec_b_o[(j+1)*DW-1 -: DW] <= shifted_mat_B[((MAX_DIM-1)*j+1)*DW-1 -: DW];
                                      end else begin
                                          vec_b_o[(j+1)*DW-1 -: DW] <= 0;
                                      end
                                  end  
                              end
                              3: begin
                                  for (j = 0; j < 3; j = j + 1) begin   
                                      if ((j <= cycle_count) && (cycle_count-j<K)) begin
                                          vec_b_o[(j+1)*DW-1 -: DW] <= shifted_mat_B[((MAX_DIM-1)*j+1)*DW-1 -: DW];
                                      end else begin
                                          vec_b_o[(j+1)*DW-1 -: DW] <= 0;
                                      end
                                  end
                              end
                              4: begin
                                  for (j = 0; j < 4; j = j + 1) begin   
                                      if ((j <= cycle_count) && (cycle_count-j<K)) begin
                                          vec_b_o[(j+1)*DW-1 -: DW] <= shifted_mat_B[((MAX_DIM-1)*j+1)*DW-1 -: DW];
                                      end else begin
                                          vec_b_o[(j+1)*DW-1 -: DW] <= 0;
                                      end
                                  end  
                              end
                              
                              default: begin
                              // we made this is just for coding practice although it's not necessary
                              end
                          endcase
                          
                        shifted_mat_A <= shifted_mat_A >> DW;
                        shifted_mat_B <= shifted_mat_B >> DW; 
                    end           
                    else if(cycle_count >= (2*MAX_DIM) && cycle_count < (3*MAX_DIM)) begin
                        vec_a_o <= 0;
                        vec_b_o <= 0;                      
                    end
                    else begin
                        // Finish
                        current_state <= STATE_DONE;
                    end
                    cycle_count <= cycle_count + 1;    
                end
                STATE_DONE: begin                  
                // Signal that the operation is done
                    done_sig_o <= 1;
                    if(!start_bit_i) begin
                      // Prepare for next start
						          current_state <= STATE_START;
					          end
                end
                default: begin
                    current_state <= STATE_START;
                end
            endcase
        end
    end
    
    always @(posedge clk_i or negedge reset_ni) begin : C_IN_OUT
        if (!reset_ni) begin
            c_flat_out <= 0;
        end 
        else begin   
            // Additional logic for handling matrix C output
            for (i = 0; i < MAX_DIM; i = i + 1) begin
                for (j = 0; j < MAX_DIM; j = j + 1) begin
                    if (i < N && j < M) begin
                        // Keep elements within MxN boundaries
                        c_flat_out[(i*MAX_DIM+j + 1)*BW-1 -: BW] <= mat_c_in[(i*MAX_DIM+j + 1)*BW-1 -: BW];
                    end else begin
                        // Clear elements outside MxN boundaries
                        c_flat_out[(i*MAX_DIM+j + 1)*BW-1 -: BW] <= 0;
                    end
                end
            end   
        end        
    end
endmodule