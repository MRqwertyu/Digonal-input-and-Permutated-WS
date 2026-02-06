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
    parameter BW = 8
)(
    input clk,
    input [BW-1:0] row_inputs [0:N-1]  // New data entering the array
);

    genvar r, c;
    
    // 1. Create a Grid of Wires to hold the state between PEs
    //    wires[r][c] holds the input value currently stored in PE(r,c)
    wire [BW-1:0] pe_in_wires [0:N-1][0:N-1];

    generate
        for (r = 0; r < N; r = r + 1) begin : ROW
            for (c = 0; c < N; c = c + 1) begin : COL
                
                // 2. Determine the SOURCE of the input for this PE
                wire [BW-1:0] diagonal_input;
                
                if (r == 0) begin
                    // TOP ROW: Receives fresh data from outside
                    assign diagonal_input = row_inputs[c]; 
                end 
                else if (c == N-1) begin
                    // RIGHT EDGE (Boundary Case):
                    // "Leftmost PE column connected to rightmost in subsequent row"
                    // Connects from PE(r-1, 0) -> PE(r, N-1)
                    assign diagonal_input = pe_in_wires[r-1][0];
                end 
                else begin
                    // STANDARD DIAGONAL: 
                    // Connects from PE(r-1, c+1) -> PE(r, c)
                    assign diagonal_input = pe_in_wires[r-1][c+1];
                end

                // 3. Instantiate the PE using these specific wires
                pe_unit u_pe (
                    .clk(clk),
                    .data_in(diagonal_input),      // The wire we selected above
                    .data_stored(pe_in_wires[r][c]) // Output own state to the grid
                );
                
            end
        end
    endgenerate

endmodule