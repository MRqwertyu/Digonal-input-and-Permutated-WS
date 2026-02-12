`timescale 1ns / 1ps

module permutating_weight_memory #(
    parameter N = 4,             // Matrix Size (Columns)
    parameter BW = 16,           // Bit Width
    parameter DEPTH = 16,        // Max rows in memory
    parameter MEM_FILE = "weights_natural.mem" // File to read
)(
    input wire clk,
    input wire ren,              // Read Enable
    input wire [3:0] base_addr,  // The Row requested by controller
    
    // Output: Unpacked Array (Requires SystemVerilog)
    output wire [BW-1:0] row_data_out [0:N-1]
);

    // ============================================================
    // 1. Temporary Storage for File Loading
    // ============================================================
    reg [BW-1:0] flat_mem [0:(N*DEPTH)-1];

    // Declare loop variable at module level to avoid "unnamed block" errors
    integer k;

    initial begin
        // Initialize with zeros
        for (k = 0; k < N*DEPTH; k = k + 1) begin
            flat_mem[k] = {BW{1'b0}};
        end
        
        // Load the external file
        $readmemh(MEM_FILE, flat_mem);
    end

    // ============================================================
    // 2. Column Banks Generation
    // ============================================================
    genvar c;
    generate
        for (c = 0; c < N; c = c + 1) begin : COL_BANK
            
            // A. Create the memory for THIS specific column
            reg [BW-1:0] bank_mem [0:DEPTH-1];
            
            // B. Distribute Data: Copy from Flat Mem -> Column Bank
            // We use a named block "INIT_BANK" to allow integer declaration if needed,
            // but for safety, we just use a static integer at the top or implied loop.
            integer r;
            initial begin
                // Small delay to ensure flat_mem is loaded
                #1; 
                for (r = 0; r < DEPTH; r = r + 1) begin
                    // Mapping: element [row r, col c] is at flat_mem index (r*N + c)
                    bank_mem[r] = flat_mem[(r * N) + c];
                end
            end

            // C. The Permutation Read Logic
            // Formula: (Base_Row + Column_Index) % N
            wire [3:0] permutated_addr;
            assign permutated_addr = (base_addr + c) % N; 

            reg [BW-1:0] data_out;

            always @(posedge clk) begin
                if (ren) begin
                    data_out <= bank_mem[permutated_addr];
                end
            end
            
            assign row_data_out[c] = data_out;
            
        end
    endgenerate

endmodule