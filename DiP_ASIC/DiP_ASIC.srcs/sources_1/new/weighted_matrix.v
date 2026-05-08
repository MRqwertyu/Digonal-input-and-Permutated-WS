`timescale 1ns / 1ps

module permutating_weight_memory #(
    parameter N = 6,             
    parameter BW = 16,           
    parameter DEPTH = 6,        
    parameter MEM_FILE = "weights_natural.mem" 
)(
    input wire ren,              
    input wire [3:0] base_addr,  
    output wire [(N*BW)-1:0] row_data_out // FLATTENED TO WIRE
);

    reg [BW-1:0] flat_mem [0:(N*DEPTH)-1];
    integer k;

    initial begin
        for (k = 0; k < N*DEPTH; k = k + 1) flat_mem[k] = {BW{1'b0}};
        $readmemh(MEM_FILE, flat_mem);
    end

    genvar c;
    generate
        for (c = 0; c < N; c = c + 1) begin : COL_BANK
            reg [BW-1:0] bank_mem [0:DEPTH-1];
            integer r;
            
            initial begin
                #10; 
                for (r = 0; r < DEPTH; r = r + 1) begin
                    bank_mem[r] = flat_mem[(r * N) + c];
                end
            end

            wire [3:0] read_addr;
            wire [3:0] safe_addr;
            
            assign safe_addr = base_addr % N;
            assign read_addr = ( (N - 1) - safe_addr + c + N ) % N; 

            // Directly drive the correct slice of the flattened output wire
            assign row_data_out[c*BW +: BW] = ren ? bank_mem[read_addr] : {BW{1'b0}};
        end
    endgenerate

endmodule