`timescale 1ns/1ps

module pe_unit #(
    parameter BW = 16,       // Width of Inputs/Weights
    parameter ACC_BW = 32    // Width of Accumulator
)(
    input  wire              clk,
    input  wire              rst_n,

    // --- Weights (Wire-Forwarded) ---
    input  wire [BW-1:0]     weight_i, 
    input  wire              wshift,
    output wire [BW-1:0]     weight_o, // Changed to Wire

    // --- Inputs (Register-Forwarded for Systolic Timing) ---
    input  wire [BW-1:0]     input_i,
    output wire  [BW-1:0]    input_o,  // Kept as Reg for diagonal skew

    // --- Partial Sums ---
    input  wire [ACC_BW-1:0] psum_i,   
    output wire [ACC_BW-1:0] psum_o,

    // --- Control Signals ---
    input  wire              pe_en,
    input  wire              mul_en,
    input  wire              adder_en
);

    /* -------- Internal Storage -------- */
    reg [BW-1:0]     input_reg;
    reg [BW-1:0]     weight_reg;
    reg [2*BW-1:0]   mul_reg;
    reg [ACC_BW-1:0] psum_reg;

    /* -------- Weight Logic (Stationary) -------- */
    // weight_o is a direct wire connection (combinational forwarding)
    assign weight_o = weight_reg; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_reg <= {BW{1'b0}};
        end else if (wshift) begin
            // Local weight register still captures the value for multiplication
            weight_reg <= weight_i;
        end
    end

    /* -------- Input Logic (Systolic Delay) -------- */
    // We KEEP this registered to preserve the diagonal wavefront flow
    assign input_o = input_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_reg <= {BW{1'b0}};
        end else if (pe_en) begin
            input_reg <= input_i;
        end
    end

    /* -------- Multiply-Accumulate Pipeline -------- */
    // Multiplier Stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            mul_reg <= {(2*BW){1'b0}};
        else if (mul_en)
            mul_reg <= input_reg * weight_reg;
    end

    // Accumulator Stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            psum_reg <= {ACC_BW{1'b0}};
        else if (adder_en)
            psum_reg <= psum_i + mul_reg;
    end

    /* -------- Output Assignment -------- */
    assign psum_o = psum_reg;

endmodule