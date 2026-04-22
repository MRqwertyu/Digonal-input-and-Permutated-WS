`timescale 1ns / 1ps

module weight_memory #(
    parameter BW = 16,
    parameter N = 4,
    parameter MEM_FILE = "weights_natural.mem"
)(
    input  wire [15:0] addr,
    output reg  [BW-1:0] row_data_out [0:N-1]
);

    reg [BW-1:0] memory [0:(N*N)-1];
    
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