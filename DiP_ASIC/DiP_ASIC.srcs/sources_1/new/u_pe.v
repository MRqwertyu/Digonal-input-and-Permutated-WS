`timescale 1ns/1ps
module pe_unit #(
    parameter BW = 16,       // Width of Inputs/Weights
    parameter ACC_BW = 32    // Width of Accumulator
)(
    input  wire              clk,
    input  wire              rst_n,

    // --- Inputs ---
    input  wire [BW-1:0]     weight_i, // Renamed to match instantiation
    input  wire              wshift,

    input  wire [BW-1:0]     input_i,
    input  wire [ACC_BW-1:0] psum_i,   // Renamed to match instantiation

    input  wire              pe_en,
    input  wire              mul_en,
    input  wire              adder_en,

    // --- Outputs ---
    output reg  [BW-1:0]     input_o,
    output reg  [BW-1:0]     weight_o,
    output reg  [ACC_BW-1:0] psum_o    // Renamed to match instantiation
);

    /* -------- Internal Registers -------- */
    reg [BW-1:0]     input_reg;
    reg [BW-1:0]     weight_reg;
    reg [2*BW-1:0]   mul_reg;     // Multiplier result needs 2x width
    reg [ACC_BW-1:0] psum_reg;

    /* -------- Weight Stationary Logic -------- */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_reg <= {BW{1'b0}};
            weight_o   <= {BW{1'b0}}; // Forwarding reset
        end else if (wshift) begin
            weight_reg <= weight_i;
            weight_o   <= weight_i;   // Daisy chain weight
        end
    end

    /* -------- Input Logic -------- */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_reg <= {BW{1'b0}};
            input_o   <= {BW{1'b0}};
        end else if (pe_en) begin
            input_reg <= input_i;
            input_o   <= input_reg;   // Systolic delay (forward REGISTERED value)
        end
    end

    /* -------- Multiply Stage -------- */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            mul_reg <= {(2*BW){1'b0}};
        else if (mul_en)
            mul_reg <= input_reg * weight_reg;
    end

    /* -------- Accumulate Stage -------- */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            psum_reg <= {ACC_BW{1'b0}};
        else if (adder_en)
            psum_reg <= psum_i + mul_reg; // Add Incoming Sum + My Product
    end

    /* -------- Output Assignment -------- */
    // In systolic arrays, the output is driven by the register
    always @(*) begin
        psum_o = psum_reg;
    end

endmodule