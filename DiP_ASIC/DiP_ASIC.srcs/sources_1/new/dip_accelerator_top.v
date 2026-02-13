`timescale 1ns / 1ps

module dip_accelerator_top #(
    parameter N = 5,            
    parameter BW = 16,          
    parameter ACC_BW = 32,      
    parameter MEM_FILE_A = "matrix_a.mem",       
    parameter MEM_FILE_B = "weights_natural.mem" 
)(
    input wire clk,
    input wire rst_n,
    input wire start,           
    input wire [15:0] num_tiles,

    output wire busy,
    output wire done,
    output wire [ACC_BW-1:0] result_data [0:N-1],
    output wire result_valid    
);

    // Internal Signals
    wire wshift, pe_en, mul_en, adder_en;
    reg [15:0] addr_a;
    reg [15:0] addr_b;

    // DATA BUSES (Now clean SystemVerilog Arrays!)
    wire [BW-1:0] mem_a_data [0:N-1];   
    wire [BW-1:0] mem_b_data [0:N-1];   

    // 1. Controller
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
        .BW(BW), .N(N), .MEM_FILE(MEM_FILE_A)
    ) u_mem_inputs (
        .clk(clk), .rst_n(rst_n), .ren(pe_en), .addr(addr_a),    
        .row_data_out(mem_a_data) // Connect Array directly
    );

    // 4. Memory B (Permutated Weights)
    permutating_weight_memory #(
        .N(N), .BW(BW), .DEPTH(N), .MEM_FILE(MEM_FILE_B)
    ) u_mem_weights (
        .clk(clk),
        .ren(wshift),          
        .base_addr(addr_b[3:0]), 
        .row_data_out(mem_b_data) // Connect Array directly
    );

    // 5. Systolic Array Core
    dip_array #(
        .N(N), .BW(BW), .ACC_BW(ACC_BW)
    ) u_array_core (
        .clk(clk), .rst_n(rst_n),
        .wshift(wshift), .pe_en(pe_en), .mul_en(mul_en), .adder_en(adder_en),
        .row_inputs(mem_a_data),
        .row_weight(mem_b_data), // Connect Array directly
        .col_outputs(result_data)
    );

    assign result_valid = adder_en; 

endmodule