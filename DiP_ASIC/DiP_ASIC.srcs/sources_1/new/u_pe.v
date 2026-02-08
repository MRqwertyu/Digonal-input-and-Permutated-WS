`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.02.2026 15:44:10
// Design Name: 
// Module Name: u_pe
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ps
// ------------------------------------------------------------
// DiP Processing Element (Weight-Stationary, Pipelined MAC)
// Latency: 2 cycles (input -> multiply -> accumulate)
// ------------------------------------------------------------
module pe_unit (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [7:0]  input_i,
    input  wire        valid_i,

    input  wire [7:0]  weight_i,
    input  wire        wshift,

    output reg  [31:0] psum_o,
    output reg         valid_o
);

    /* ---------------- Registers ---------------- */
    reg [7:0] input_r;        // pipeline stage 0
    reg       valid_r0;

    reg [15:0] mul_r;         // pipeline stage 1
    reg        valid_r1;

    reg [7:0] weight_r;       // stationary weight

    /* ---------------- Weight Stationary ---------------- */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            weight_r <= 8'd0;
        else if (wshift)
            weight_r <= weight_i;
    end

    /* ---------------- Pipeline Stage 0 ---------------- */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_r  <= 8'd0;
            valid_r0 <= 1'b0;
        end else begin
            input_r  <= input_i;
            valid_r0 <= valid_i;
        end
    end

    /* ---------------- Pipeline Stage 1 ---------------- */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_r    <= 16'd0;
            valid_r1 <= 1'b0;
        end else begin
            mul_r    <= input_r * weight_r;
            valid_r1 <= valid_r0;
        end
    end

    /* ---------------- Accumulation ---------------- */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            psum_o  <= 32'd0;
            valid_o <= 1'b0;
        end else begin
            if (valid_r1)
                psum_o <= psum_o + mul_r;
            valid_o <= valid_r1;
        end
    end

endmodule
