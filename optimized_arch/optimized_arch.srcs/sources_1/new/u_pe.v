`timescale 1ns/1ps
<<<<<<< HEAD

module pe_unit #(
    parameter BW     = 8,
    parameter ACC_BW = 16  // Note: Ensure this matches the 19-bit requirement at your top level if N=6
=======
module pe_unit #(
    parameter BW     = 8,
    parameter ACC_BW = 16
>>>>>>> f791e296ea4674a338443894ad1640085a9690b1
)(
    input  wire              clk,
    input  wire              rst_n,
    // Weights
    input  wire [BW-1:0]     weight_i,
    input  wire              wshift,
    output wire [BW-1:0]     weight_o,
    // Inputs
    input  wire [BW-1:0]     input_i,
    output wire [BW-1:0]     input_o,
    // Partial sums
    input  wire [ACC_BW-1:0] psum_i,
    output wire [ACC_BW-1:0] psum_o,
    // Control
    input  wire              pe_en,
    input  wire              mul_en,
    input  wire              adder_en
);
<<<<<<< HEAD

=======
>>>>>>> f791e296ea4674a338443894ad1640085a9690b1
    // ============================================================
    // Internal registers
    // ============================================================
    reg [BW-1:0]     input_reg;
    reg [BW-1:0]     weight_reg;
<<<<<<< HEAD
    
    // FORCE VIVADO TO USE DSP SLICES FOR 8-BIT MATH
    (* use_dsp = "yes" *) reg [2*BW-1:0]   mul_reg;
    
    reg [ACC_BW-1:0] psum_reg;

    // ============================================================
    // Operand gating (TRUE ASIC ISOLATION)
    // ============================================================
    wire zero_skip = (input_reg == {BW{1'b0}}) ||
                     (weight_reg == {BW{1'b0}});

=======
    reg [2*BW-1:0]   mul_reg;
    reg [ACC_BW-1:0] psum_reg;
    // ============================================================
    // Pipeline alignment (important)
    // ============================================================
    reg mul_en_d1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mul_en_d1 <= 1'b0;
        else
            mul_en_d1 <= mul_en;
    end
    // ============================================================
    // Operand gating (SAFE - no pipeline freeze)
    // ============================================================
    wire zero_skip = (input_reg == {BW{1'b0}}) ||
                     (weight_reg == {BW{1'b0}});
>>>>>>> f791e296ea4674a338443894ad1640085a9690b1
    // ============================================================
    // Weight register (stationary)
    // ============================================================
    assign weight_o = weight_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            weight_reg <= {BW{1'b0}};
        else if (wshift)
            weight_reg <= weight_i;
    end
<<<<<<< HEAD

=======
>>>>>>> f791e296ea4674a338443894ad1640085a9690b1
    // ============================================================
    // Input register (diagonal movement)
    // ============================================================
    assign input_o = input_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            input_reg <= {BW{1'b0}};
        else if (pe_en)
            input_reg <= input_i;
    end
<<<<<<< HEAD

    // ============================================================
    // Stage 1: TRUE Operand Isolation (MUX BEFORE the Multiplier)
    // ============================================================
    
    // 1. Clamp the inputs to absolute zero BEFORE they enter the multiplier
    wire [BW-1:0] isolated_input  = zero_skip ? {BW{1'b0}} : input_reg;
    wire [BW-1:0] isolated_weight = zero_skip ? {BW{1'b0}} : weight_reg;

=======
    // ============================================================
    // Stage 1: Multiply (with safe zero-skipping)
    // ============================================================
>>>>>>> f791e296ea4674a338443894ad1640085a9690b1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mul_reg <= {(2*BW){1'b0}};
        else if (mul_en)
<<<<<<< HEAD
            // 2. The multiplier now receives stable 0s when skipped. 
            // Because neither input is changing, toggling drops to absolute zero!
            mul_reg <= isolated_input * isolated_weight; 
    end

    // ============================================================
    // Stage 2: Accumulate (aligned with global controller pipeline)
=======
            mul_reg <= zero_skip ? {(2*BW){1'b0}} 
                                 : input_reg * weight_reg;
    end
    // ============================================================
    // Stage 2: Accumulate (aligned with pipeline)
>>>>>>> f791e296ea4674a338443894ad1640085a9690b1
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            psum_reg <= {ACC_BW{1'b0}};
<<<<<<< HEAD
        else if (adder_en)
            // Safely adds 0 if the multiplication was skipped
            psum_reg <= psum_i + {{(ACC_BW-2*BW){mul_reg[2*BW-1]}}, mul_reg};
    end

=======
        else if (mul_en_d1 && adder_en)
            psum_reg <= psum_i + 
                        {{(ACC_BW-2*BW){mul_reg[2*BW-1]}}, mul_reg};
    end
>>>>>>> f791e296ea4674a338443894ad1640085a9690b1
    // ============================================================
    // Output
    // ============================================================
    assign psum_o = psum_reg;
<<<<<<< HEAD

=======
>>>>>>> f791e296ea4674a338443894ad1640085a9690b1
endmodule