module permutating_weight_memory #(
    parameter N = 4,
    parameter BW = 16,
    parameter DEPTH = 16
)(
    input wire clk,
    input wire ren,              // Read Enable
    input wire [3:0] base_addr,  // The "Row" the controller thinks it's asking for
    
    // Output: The correctly permutated row for DiP
    output wire [BW-1:0] row_data_out [0:N-1]
);

    genvar i;
    generate
        // Create N independent memory banks (one per column)
        for (i = 0; i < N; i = i + 1) begin : COL_BANK
            
            // 1. Calculate the Address Rotation
            // Formula: (Base_Row + Column_Index) % Total_Rows
            // This implements the "rotate up by column index" logic
            wire [3:0] bank_addr;
            assign bank_addr = (base_addr + i) % N; // Modulo N logic

            // 2. Instantiate a Single-Column Memory
            // Note: In a real ASIC, this would be a compiled SRAM macro.
            // Here we use a register array for behavioral simulation.
            reg [BW-1:0] mem_bank [0:DEPTH-1];

            // Initialize this specific column from a file
            // You would split your matrix_b.mem into columns, 
            // or load a flat file and stride it.
            initial begin
                // Load logic depends on your file format. 
                // For simplicity, assume we load a file specific to this column.
                // $readmemh($sformatf("weight_col_%0d.mem", i), mem_bank);
            end

            reg [BW-1:0] data_out;
            
            // 3. Read Logic with ROTATED Address
            always @(posedge clk) begin
                if (ren) begin
                    data_out <= mem_bank[bank_addr];
                end
            end
            
            // Output connection
            assign row_data_out[i] = data_out;
            
        end
    endgenerate

endmodule