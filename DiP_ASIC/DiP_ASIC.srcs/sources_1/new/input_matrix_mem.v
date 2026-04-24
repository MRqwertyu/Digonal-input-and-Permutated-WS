`timescale 1ns / 1ps

module matrix_memory #(
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
            for (i = 0; i < N; i = i + 1) begin
                row_data_out[i] = memory[(addr * N) + i];
            end
        end else begin
            // If address exceeds ROWS (during the pipeline flush phase), 
            // safely output zeros to push the last calculations out of the array
            for (i = 0; i < N; i = i + 1) begin
                row_data_out[i] = {BW{1'b0}};
            end
        end
    end

endmodule