`timescale 1ns / 1ps

module dip_array #(
    parameter N = 6,
    parameter BW = 16,     // Width of Inputs/Weights
    parameter ACC_BW = 32  // Width of Partial Sums
)(
    input wire clk,
    input wire rst_n,      
    
    // Control Signals
    input wire wshift,
    input wire pe_en,
    input wire mul_en,
    input wire adder_en,

    // FIX: Flattened Data Inputs
    input wire [(N*BW)-1:0] row_inputs, 
    input wire [(N*BW)-1:0] row_weight,
    
    // FIX: Flattened Data Output
    output wire [(N*ACC_BW)-1:0] col_outputs
);

    // --- 1. UNPACK FLAT INPUTS ---
    wire [BW-1:0] unpacked_inputs [0:N-1];
    wire [BW-1:0] unpacked_weights [0:N-1];
    
    genvar i_unp;
    generate
        for (i_unp = 0; i_unp < N; i_unp = i_unp + 1) begin : UNPACK
            assign unpacked_inputs[i_unp] = row_inputs[(i_unp*BW) +: BW];
            assign unpacked_weights[i_unp] = row_weight[(i_unp*BW) +: BW];
        end
    endgenerate

    genvar r, c;
    
    // 1. GRID WIRES
    wire [BW-1:0] pe_in_wires [0:N-1][0:N-1];
    wire [BW-1:0] pe_weight_wires [0:N-1][0:N-1];
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
                    assign diagonal_input = unpacked_inputs[c];  // FIX: Using unpacked array
                end 
                else if (c == N-1) begin
                    assign diagonal_input = pe_in_wires[r-1][0];
                end 
                else begin
                    assign diagonal_input = pe_in_wires[r-1][c+1];
                end

                // --- B. Weight Logic (Vertical) ---
                wire [BW-1:0] weight_in_wire;
                if (r == 0) begin
                    assign weight_in_wire = unpacked_weights[c]; // FIX: Using unpacked array
                end else begin
                    assign weight_in_wire = pe_weight_wires[r-1][c];
                end

                // --- C. Partial Sum Logic (Vertical) ---
                wire [ACC_BW-1:0] psum_in_wire;
                assign psum_in_wire = pe_psum_wires[r][c];

                // --- D. PE Instantiation ---
                pe_unit #(
                    .BW(BW),          
                    .ACC_BW(ACC_BW)   
                ) u_pe (
                    .clk(clk),
                    .rst_n(rst_n),
                    
                    .wshift(wshift),
                    .pe_en(pe_en),
                    .mul_en(mul_en),
                    .adder_en(adder_en),

                    .input_i(diagonal_input), 
                    .weight_i(weight_in_wire), 
                    .psum_i(psum_in_wire),     

                    .input_o(pe_in_wires[r][c]),      
                    .weight_o(pe_weight_wires[r][c]), 
                    .psum_o(pe_psum_wires[r+1][c])    
                );
            end
        end
    endgenerate

    // --- 3. PACK FINAL OUTPUTS ---
    generate
        for (c = 0; c < N; c = c + 1) begin : PACK_OUTPUTS
            // FIX: Pack the bottom row internal results into the flat 1D output port
            assign col_outputs[(c*ACC_BW) +: ACC_BW] = pe_psum_wires[N][c];
        end
    endgenerate

endmodule