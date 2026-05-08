`timescale 1ns / 1ps

module matrix_memory #(
    parameter BW = 16,            
    parameter N = 6,              
    parameter MAX_TILES = 30,             // Soft-coded tile limit
    parameter ROWS = MAX_TILES * N,       // Dynamically calculated rows
    parameter MEM_FILE = "matrix_a.mem" 
)(
    input wire ren,              
    input wire [15:0] addr,      
    output reg [(N*BW)-1:0] row_data_out  // FIX: Flattened port
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
            for (i = 0; i < N; i = i + 1) begin
                // FIX: Map into flat wire slice
                row_data_out[(i*BW) +: BW] = memory[(addr * N) + i];
            end
        end else begin
            // If address exceeds ROWS, safely output zeros
            for (i = 0; i < N; i = i + 1) begin
                row_data_out[(i*BW) +: BW] = {BW{1'b0}};
            end
        end
    end

endmodule 