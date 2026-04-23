`timescale 1ns / 1ps

module matrix_memory #(
    parameter BW = 16,           // Bit Width of Data
    parameter N = 4,             // Matrix Dimension (N x N)
    parameter MEM_FILE = "matrix_a.mem" // File name to read
)(

    
    // Read Interface
    input wire ren,              // Read Enable (active high)
    input wire [15:0] addr,      // Address (Row Index)
    
    // Output Interface
    // We output an ENTIRE ROW at once because that's what the array needs
    output reg [BW-1:0] row_data_out [0:N-1] 
);

    // 1. Storage Declaration
    // We store the matrix as a 1D array of vectors for easier file reading
    // Size = N rows * N columns
    reg [BW-1:0] memory [0:(N*N)-1];
    
    // 2. File Loading (Initialization)
    initial begin
        // $readmemh loads hex values from a file into the memory array
        // Format of .mem file: One hex value per line (or space separated)
        $readmemh(MEM_FILE, memory);
    end

integer i;
    always @(*) begin 
        // FIX: Now it only outputs data if Read Enable is HIGH *and* address is valid
        if (ren && (addr < N)) begin
            for (i = 0; i < N; i = i + 1) begin
                row_data_out[i] = memory[(addr * N) + i];
            end
        end else begin
            // If ren is LOW, or address is invalid, force zeros to kill toggling/power
            for (i = 0; i < N; i = i + 1) begin
                row_data_out[i] = {BW{1'b0}};
            end
        end
    end

endmodule