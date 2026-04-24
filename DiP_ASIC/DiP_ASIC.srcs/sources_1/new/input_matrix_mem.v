`timescale 1ns / 1ps

module matrix_memory #(
<<<<<<< HEAD
    parameter BW = 16,           
    parameter N = 3,             
    parameter MAX_TILES = 30,             // 1. Soft-coded tile limit
    parameter ROWS = MAX_TILES * N,       // 2. Dynamically calculated rows
    parameter MEM_FILE = "matrix_a.mem" 
)(
    input wire ren,              
    input wire [15:0] addr,      
    output reg [BW-1:0] row_data_out [0:N-1] 
);

    // Array size dynamically scales based on MAX_TILES
    reg [BW-1:0] memory [0:(ROWS*N)-1]; 
    
    initial begin
        $readmemh(MEM_FILE, memory);
    end

    integer i;
    always @(*) begin 
        // If address is within valid bounds, output data
        if (ren && (addr < ROWS)) begin
=======
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
>>>>>>> f791e296ea4674a338443894ad1640085a9690b1
            for (i = 0; i < N; i = i + 1) begin
                row_data_out[i] = memory[(addr * N) + i];
            end
        end else begin
<<<<<<< HEAD
            // If address exceeds ROWS (during the pipeline flush phase), 
            // safely output zeros to push the last calculations out of the array
=======
            // If ren is LOW, or address is invalid, force zeros to kill toggling/power
>>>>>>> f791e296ea4674a338443894ad1640085a9690b1
            for (i = 0; i < N; i = i + 1) begin
                row_data_out[i] = {BW{1'b0}};
            end
        end
    end

endmodule