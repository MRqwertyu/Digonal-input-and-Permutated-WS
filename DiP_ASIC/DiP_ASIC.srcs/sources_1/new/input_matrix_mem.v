`timescale 1ns / 1ps

module matrix_memory #(
    parameter BW = 16,            
    parameter N = 6,              
    parameter MAX_TILES = 30,             
    parameter ROWS = MAX_TILES * N,       
    parameter MEM_FILE = "matrix_a.mem" 
)(
    input wire ren,              
    input wire [15:0] addr,      
    output reg [(N*BW)-1:0] row_data_out // FLATTENED
);

    reg [BW-1:0] memory [0:(ROWS*N)-1]; 
    
    initial begin
        $readmemh(MEM_FILE, memory);
    end

    integer i;
    always @(*) begin 
        if (ren && (addr < ROWS)) begin
            for (i = 0; i < N; i = i + 1) begin
                // Map array blocks to flattened wire using indexed part-select
                row_data_out[i*BW +: BW] = memory[(addr * N) + i];
            end
        end else begin
            row_data_out = {(N*BW){1'b0}};
        end
    end

endmodule