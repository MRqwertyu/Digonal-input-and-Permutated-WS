`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.02.2026 14:16:34
// Design Name: 
// Module Name: MaC_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module dip_array #(
    parameter N = 4,
    parameter BW = 16,     // Width of Inputs/Weights
    parameter ACC_BW = 32  // Width of Partial Sums (usually larger)
)(
    input wire clk,
    input wire rst_n,      // Added Reset
    
    // Control Signals (Needed for PE)
    input wire wshift,
    input wire pe_en,
    input wire mul_en,
    input wire adder_en,

    // Data Inputs
    input wire [BW-1:0] row_inputs [0:N-1], 
    input wire [BW-1:0] row_weight [0:N-1],
    
    // Data Output (The bottom of the systolic array)
    output wire [ACC_BW-1:0] col_outputs [0:N-1]
);

    genvar r, c;
    
    // 1. GRID WIRES
    // Holds the input value stored in PE(r,c) to pass to diagonal neighbor
    wire [BW-1:0] pe_in_wires [0:N-1][0:N-1];
    
    // Holds the weight value stored in PE(r,c) to pass down (if loading)
    wire [BW-1:0] pe_weight_wires [0:N-1][0:N-1];
    
    // Holds psums flowing VERTICALLY. 
    // Size is [0:N]: Index 0 is input to top row, Index N is output of bottom row.
    wire [ACC_BW-1:0] pe_psum_wires [0:N][0:N-1]; 

    // Initialize Top Row Psums to 0
    generate
        for (c = 0; c < N; c = c + 1) begin : INIT_PSUM
            assign pe_psum_wires[0][c] = {ACC_BW{1'b0}};
        end
    endgenerate

    // 2. THE ARRAY GENERATION
    generate
        for (r = 0; r < N; r = r + 1) begin : ROW
            for (c = 0; c < N; c = c + 1) begin : COL
                
                // --- A. Diagonal Input Logic ---
                wire [BW-1:0] diagonal_input;
                
                if (r == 0) begin
                    // Top Row: Fresh data from outside
                    assign diagonal_input = row_inputs[c]; 
                end 
                else if (c == N-1) begin
                    // Right Edge: Wrap around from Left Edge of previous row
                    assign diagonal_input = pe_in_wires[r-1][0];
                end 
                else begin
                    // Standard Diagonal: Shift from (r-1, c+1)
                    assign diagonal_input = pe_in_wires[r-1][c+1];
                end

                // --- B. Weight Logic (Vertical) ---
                wire [BW-1:0] weight_in_wire;
                if (r == 0) begin
                    assign weight_in_wire = row_weight[c];
                end else begin
                    assign weight_in_wire = pe_weight_wires[r-1][c];
                end

                // --- C. Partial Sum Logic (Vertical) ---
                // Input comes from the wire "above" (r). 
                // Output goes to the wire "below" (r+1).
                wire [ACC_BW-1:0] psum_in_wire;
                assign psum_in_wire = pe_psum_wires[r][c];

                // --- D. PE Instantiation ---
                pe_unit u_pe (
                    .clk(clk),
                    .rst_n(rst_n),
                    
                    // Controls
                    .wshift(wshift),
                    .pe_en(pe_en),
                    .mul_en(mul_en),
                    .adder_en(adder_en),

                    // Inputs
                    .input_i(diagonal_input), 
                    .weight_i(weight_in_wire),
                    .psum_i(psum_in_wire),  // <--- You missed connecting this!

                    // Outputs
                    .input_o(pe_in_wires[r][c]),      // Output to diagonal grid
                    .weight_o(pe_weight_wires[r][c]), // Output to weight grid
                    .psum_o(pe_psum_wires[r+1][c])    // Output to psum grid (Next Row)
                );
                
            end
        end
    endgenerate

    // 3. Assign Final Outputs
    // The results exiting the bottom row (Index N) are the module outputs
    generate
        for (c = 0; c < N; c = c + 1) begin : OUT_ASSIGN
            assign col_outputs[c] = pe_psum_wires[N][c];
        end
    endgenerate

endmodule