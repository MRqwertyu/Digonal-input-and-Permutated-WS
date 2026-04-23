`timescale 1ns / 1ps

module weight_memory #(
    parameter BW = 16,
    parameter N = 4,
    parameter MEM_FILE = "weights_natural.mem"
)(
    input  wire [15:0] addr,
    output reg  [BW-1:0] row_data_out [0:N-1]
);

// E.g., Supports up to 100 tiles at 64x64 (64 * 64 * 100 = 409,600)
    reg [BW-1:0] memory [0:500000];
    
    initial begin
        $readmemh(MEM_FILE, memory);
    end

    integer i;
    always @(*) begin // FIX: Instant Combinational Read!
        if (addr < N) begin
            for (i = 0; i < N; i = i + 1) begin
                row_data_out[i] = memory[(addr * N) + i];
            end
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                row_data_out[i] = {BW{1'b0}};
            end
        end
    end

endmodule