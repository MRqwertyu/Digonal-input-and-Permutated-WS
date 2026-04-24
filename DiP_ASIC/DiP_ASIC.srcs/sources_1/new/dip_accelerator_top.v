`timescale 1ns / 1ps

// Assuming this is your Isomorphic Top Module
module dip_accelerator_top #(
    parameter N = 6,            
    parameter BW = 16,          
    parameter ACC_BW = 32,      
    parameter MAX_TILES = 30,                    // 1. ADD THIS: Top-level control
    parameter MEM_FILE_A = "matrix_a.mem",       
    parameter MEM_FILE_B = "weights_natural.mem" // Isomorphic uses natural weights
)(
    input wire clk,
    input wire rst_n,
    input wire start,            
    input wire [7:0] num_tiles,                  // 2. EXPAND THIS: To 8 bits

    output wire busy,
    output wire done,
    output wire result_valid    
);

    (* dont_touch = "true" *) wire [ACC_BW-1:0] result_data [0:N-1];
    
    wire wshift, pe_en, mul_en, adder_en;
    reg [15:0] addr_a;
    reg [15:0] addr_b; // Used for the step counter in the permutating memory

    wire [BW-1:0] mem_a_data [0:N-1];   
    wire [BW-1:0] mem_b_data [0:N-1];   

    // 1. Controller (Use the NEW streaming controller)
    dip_controller #(
        .N(N), .BW(BW), .ACC_BW(ACC_BW)
    ) u_controller (
        .clk(clk), .rst_n(rst_n), .start(start), .num_tiles(num_tiles),
        .wshift(wshift), .pe_en(pe_en), .mul_en(mul_en), .adder_en(adder_en),
        .busy(busy), .done(done)
    );

    // 2. Address Generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_a <= 0;
            addr_b <= 0;
        end else if (done) begin
            addr_a <= 0;
            addr_b <= 0;
        end else begin
            if (pe_en)  addr_a <= addr_a + 1;
            if (wshift) addr_b <= addr_b + 1;
        end
    end

    // 3. Memory A (Standard Inputs)
    matrix_memory #(
        .BW(BW), .N(N), .MAX_TILES(MAX_TILES), .MEM_FILE(MEM_FILE_A) // 3. PASS MAX_TILES
    ) u_mem_inputs (
        .ren(pe_en), 
        .addr(addr_a),            
        .row_data_out(mem_a_data) 
    );

    // 4. Memory B (Permutating Weights from earlier)
    permutating_weight_memory #(
        .N(N), .BW(BW), .DEPTH(N), .MEM_FILE(MEM_FILE_B) 
    ) u_mem_weights (
        .ren(wshift),          
        .base_addr(addr_b[3:0]), 
        .row_data_out(mem_b_data) 
    );

// 5. Systolic Array Core (Isomorphic Version)
    dip_array #(                 // <--- CHANGE THIS from iso_array back to dip_array
        .N(N), .BW(BW), .ACC_BW(ACC_BW)
    ) u_array_core (
        .clk(clk), .rst_n(rst_n),
        .wshift(wshift), .pe_en(pe_en), .mul_en(mul_en), .adder_en(adder_en),
        .row_inputs(mem_a_data),
        .row_weight(mem_b_data), 
        .col_outputs(result_data)
    );

    assign result_valid = adder_en; 

endmodule