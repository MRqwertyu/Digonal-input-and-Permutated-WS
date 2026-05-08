`timescale 1ns / 1ps

module weight_memory #(
    parameter BW = 16,
    parameter N = 6,
    parameter MEM_FILE = "weights_natural.mem"
)(
    input  wire [15:0] addr,
    output reg  [(N*BW)-1:0] row_data_out 
);

    // E.g., Supports up to 100 tiles at 64x64 (64 * 64 * 100 = 409,600)
    reg [BW-1:0] memory [0:4095];
    
    initial begin
        $readmemh(MEM_FILE, memory);
    end

    integer i;
    always @(*) begin // Instant Combinational Read!
        if (addr < N) begin
            for (i = 0; i < N; i = i + 1) begin
                // FIX: Map the BW-sized word into the correct slice of the flat wire
                row_data_out[(i*BW) +: BW] = memory[(addr * N) + i];
            end
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                row_data_out[(i*BW) +: BW] = {BW{1'b0}};
            end
        end
    end

endmodule