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
    
    // OUTPUT: SystemVerilog Array (Clean & Simple)
    output reg [BW-1:0] row_data_out [0:N-1]
);

    // ============================================================
    // 1. Temporary Storage for File Loading
    // ============================================================
    reg [BW-1:0] flat_mem [0:(N*DEPTH)-1];
    integer k;

    initial begin
        // A. Initialize
        for (k = 0; k < N*DEPTH; k = k + 1) flat_mem[k] = {BW{1'b0}};
        
        // B. Load File
        $readmemh(MEM_FILE, flat_mem);

        // C. Debug Check
        #1; 
        if (flat_mem[0] === {BW{1'bx}}) begin
            $display("[ERROR] Weight Memory: Failed to load '%s'.", MEM_FILE);
            $finish;
        end else begin
            $display("[SUCCESS] Weight Memory: Loaded '%s'. First val: %h", MEM_FILE, flat_mem[0]);
        end
    end

    // ============================================================
    // 2. Column Banks Generation
    // ============================================================
    genvar c;
    generate
        for (c = 0; c < N; c = c + 1) begin : COL_BANK
            
            reg [BW-1:0] bank_mem [0:DEPTH-1];
            
            // Distribute Data
            integer r;
            initial begin
                #10; // Wait for flat_mem to be ready
                for (r = 0; r < DEPTH; r = r + 1) begin
                    bank_mem[r] = flat_mem[(r * N) + c];
                end
            end

            // Read Logic
            wire [3:0] permutated_addr;
            assign permutated_addr = (base_addr + c) % N; 

            always @(posedge clk) begin
                if (ren) begin
                    // Direct assignment to output array slice
                    row_data_out[c] <= bank_mem[permutated_addr];
                end
            end
            
        end
    endgenerate

endmodule